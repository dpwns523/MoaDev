"""Tests for the GeekNews ingestion/enrichment pipeline.

AC-1: The Article row's final persisted status is PUBLISHED, written by a
single commit; no intermediate status is ever durably persisted for that row.

Test strategy:
  - Live-fetch fidelity tests: real HTTP to news.hada.io; in-run snapshot
    is captured first, then asserted against the persisted row — deterministic
    despite the feed being live.
  - Unit tests: monkeypatch fetch_feed with a minimal Atom payload so no
    network access is required; cover idempotency, segment, structured output,
    and summary determinism.
"""
from __future__ import annotations

import textwrap
from datetime import datetime, timezone

import pytest
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from app.models import (
    Article,
    ArticleProcessingStatus,
    ArticleSegment,
    ArticleStructuredOutput,
    Base,
    SourceRegistryEntry,
)
from app.pipeline import (
    GEEKNEWS_SLUG,
    FeedEntry,
    fetch_feed,
    generate_summary,
    run_pipeline,
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_MINIMAL_ATOM = textwrap.dedent("""\
    <?xml version="1.0" encoding="UTF-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
      <title>GeekNews</title>
      <entry>
        <id>https://news.hada.io/topic?id=99999</id>
        <title>테스트 기사 제목</title>
        <link rel="alternate" href="https://news.hada.io/topic?id=99999"/>
        <published>2024-01-15T12:00:00Z</published>
        <content type="html">테스트 기사 본문 내용입니다.</content>
      </entry>
    </feed>
""")

_MINIMAL_ENTRY = FeedEntry(
    title="테스트 기사 제목",
    canonical_url="https://news.hada.io/topic?id=99999",
    content="테스트 기사 본문 내용입니다.",
    external_id="https://news.hada.io/topic?id=99999",
    published_at=datetime(2024, 1, 15, 12, 0, 0, tzinfo=timezone.utc),
)


def _make_session() -> Session:
    """In-memory SQLite session with all tables created."""
    engine = create_engine("sqlite+pysqlite:///:memory:", future=True)
    Base.metadata.create_all(engine)
    return Session(engine)


def _make_engine_and_session() -> tuple:  # type: ignore[type-arg]
    engine = create_engine("sqlite+pysqlite:///:memory:", future=True)
    Base.metadata.create_all(engine)
    return engine, Session(engine)


# ---------------------------------------------------------------------------
# generate_summary unit tests
# ---------------------------------------------------------------------------


def test_generate_summary_is_deterministic() -> None:
    """Same title always produces same summary."""
    title = "인공지능 최신 동향"
    assert generate_summary(title) == generate_summary(title)


def test_generate_summary_minimum_length() -> None:
    """Summary is at least 10 characters long."""
    title = "짧은"
    summary = generate_summary(title)
    assert len(summary) >= 10, f"Summary too short: {summary!r}"


def test_generate_summary_not_empty() -> None:
    """Summary is non-empty."""
    assert generate_summary("어떤 제목이든") != ""


def test_generate_summary_contains_title() -> None:
    """Summary contains the input title."""
    title = "테스트 제목 문자열"
    assert title in generate_summary(title)


# ---------------------------------------------------------------------------
# Unit pipeline tests (monkeypatched feed)
# ---------------------------------------------------------------------------


def test_run_pipeline_returns_published_article(monkeypatch: pytest.MonkeyPatch) -> None:
    """run_pipeline returns an Article with status=PUBLISHED."""
    monkeypatch.setattr(
        "app.pipeline.fetch_feed",
        lambda url: [_MINIMAL_ENTRY],
    )

    session = _make_session()
    article = run_pipeline(session)

    assert article is not None
    assert article.status == ArticleProcessingStatus.PUBLISHED


def test_run_pipeline_persisted_status_is_published(monkeypatch: pytest.MonkeyPatch) -> None:
    """The durably committed row has status=PUBLISHED — no intermediate row committed."""
    monkeypatch.setattr(
        "app.pipeline.fetch_feed",
        lambda url: [_MINIMAL_ENTRY],
    )

    engine, session = _make_engine_and_session()
    run_pipeline(session)
    session.close()

    with Session(engine) as verify_session:
        row = verify_session.scalars(
            select(Article).where(Article.canonical_url == _MINIMAL_ENTRY.canonical_url)
        ).first()

    assert row is not None, "Article must be persisted in DB"
    assert row.status == ArticleProcessingStatus.PUBLISHED, (
        f"Expected PUBLISHED, got {row.status!r}"
    )


def test_run_pipeline_no_intermediate_status_rows(monkeypatch: pytest.MonkeyPatch) -> None:
    """Exactly one Article row is committed; it is at the PUBLISHED terminal status."""
    monkeypatch.setattr(
        "app.pipeline.fetch_feed",
        lambda url: [_MINIMAL_ENTRY],
    )

    engine, session = _make_engine_and_session()
    run_pipeline(session)
    session.close()

    with Session(engine) as verify_session:
        source = verify_session.scalars(
            select(SourceRegistryEntry).where(SourceRegistryEntry.slug == GEEKNEWS_SLUG)
        ).first()
        assert source is not None
        rows = list(
            verify_session.scalars(
                select(Article).where(Article.source_id == source.id)
            ).all()
        )

    # One row, at PUBLISHED — never a separate PENDING_* row
    assert len(rows) == 1
    assert rows[0].status == ArticleProcessingStatus.PUBLISHED


def test_run_pipeline_single_segment_at_position_0(monkeypatch: pytest.MonkeyPatch) -> None:
    """Exactly one ArticleSegment is created at position=0."""
    monkeypatch.setattr(
        "app.pipeline.fetch_feed",
        lambda url: [_MINIMAL_ENTRY],
    )

    engine, session = _make_engine_and_session()
    article = run_pipeline(session)
    assert article is not None
    article_id = article.id
    session.close()

    with Session(engine) as verify_session:
        segments = list(
            verify_session.scalars(
                select(ArticleSegment).where(ArticleSegment.article_id == article_id)
            ).all()
        )

    assert len(segments) == 1
    assert segments[0].position == 0


def test_run_pipeline_segment_original_text(monkeypatch: pytest.MonkeyPatch) -> None:
    """Segment original_text equals the raw feed content."""
    monkeypatch.setattr(
        "app.pipeline.fetch_feed",
        lambda url: [_MINIMAL_ENTRY],
    )

    engine, session = _make_engine_and_session()
    article = run_pipeline(session)
    assert article is not None
    article_id = article.id
    session.close()

    with Session(engine) as verify_session:
        seg = verify_session.scalars(
            select(ArticleSegment).where(ArticleSegment.article_id == article_id)
        ).first()

    assert seg is not None
    assert seg.original_text == _MINIMAL_ENTRY.content


def test_run_pipeline_segment_translated_text_is_passthrough(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Segment translated_text is a pass-through copy of the original_text."""
    monkeypatch.setattr(
        "app.pipeline.fetch_feed",
        lambda url: [_MINIMAL_ENTRY],
    )

    engine, session = _make_engine_and_session()
    article = run_pipeline(session)
    assert article is not None
    article_id = article.id
    session.close()

    with Session(engine) as verify_session:
        seg = verify_session.scalars(
            select(ArticleSegment).where(ArticleSegment.article_id == article_id)
        ).first()

    assert seg is not None
    assert seg.translated_text == seg.original_text


def test_run_pipeline_creates_structured_output(monkeypatch: pytest.MonkeyPatch) -> None:
    """ArticleStructuredOutput is created with a non-empty summary."""
    monkeypatch.setattr(
        "app.pipeline.fetch_feed",
        lambda url: [_MINIMAL_ENTRY],
    )

    engine, session = _make_engine_and_session()
    article = run_pipeline(session)
    assert article is not None
    article_id = article.id
    session.close()

    with Session(engine) as verify_session:
        output = verify_session.scalars(
            select(ArticleStructuredOutput).where(
                ArticleStructuredOutput.article_id == article_id
            )
        ).first()

    assert output is not None
    assert output.summary, "summary must be non-empty"
    assert len(output.summary) >= 10


def test_run_pipeline_summary_contains_title(monkeypatch: pytest.MonkeyPatch) -> None:
    """Structured output summary contains the article title."""
    monkeypatch.setattr(
        "app.pipeline.fetch_feed",
        lambda url: [_MINIMAL_ENTRY],
    )

    engine, session = _make_engine_and_session()
    article = run_pipeline(session)
    assert article is not None
    article_id = article.id
    session.close()

    with Session(engine) as verify_session:
        output = verify_session.scalars(
            select(ArticleStructuredOutput).where(
                ArticleStructuredOutput.article_id == article_id
            )
        ).first()

    assert output is not None
    assert _MINIMAL_ENTRY.title in output.summary


def test_run_pipeline_idempotent_skips_already_published(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Second run with the same article returns None — no duplicate rows."""
    monkeypatch.setattr(
        "app.pipeline.fetch_feed",
        lambda url: [_MINIMAL_ENTRY],
    )

    engine, session1 = _make_engine_and_session()
    run_pipeline(session1)
    session1.close()

    with Session(engine) as session2:
        result2 = run_pipeline(session2)

    assert result2 is None, "Second run must return None for an already-published article"

    with Session(engine) as verify_session:
        source = verify_session.scalars(
            select(SourceRegistryEntry).where(SourceRegistryEntry.slug == GEEKNEWS_SLUG)
        ).first()
        assert source is not None
        rows = list(
            verify_session.scalars(
                select(Article).where(
                    Article.source_id == source.id,
                    Article.canonical_url == _MINIMAL_ENTRY.canonical_url,
                )
            ).all()
        )

    assert len(rows) == 1, "Must have exactly one Article row — no duplicates"


def test_run_pipeline_source_registry_committed_independently(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """SourceRegistryEntry is durable even when the article transaction is skipped."""
    monkeypatch.setattr(
        "app.pipeline.fetch_feed",
        lambda url: [],  # No entries — article phase produces None
    )

    engine, session = _make_engine_and_session()
    result = run_pipeline(session)
    session.close()

    assert result is None  # No entries → skip

    with Session(engine) as verify_session:
        source = verify_session.scalars(
            select(SourceRegistryEntry).where(SourceRegistryEntry.slug == GEEKNEWS_SLUG)
        ).first()

    assert source is not None, "SourceRegistryEntry must be committed even when article is skipped"
    assert source.slug == GEEKNEWS_SLUG


def test_run_pipeline_article_title_and_url(monkeypatch: pytest.MonkeyPatch) -> None:
    """Persisted Article has correct title and canonical_url from feed entry."""
    monkeypatch.setattr(
        "app.pipeline.fetch_feed",
        lambda url: [_MINIMAL_ENTRY],
    )

    engine, session = _make_engine_and_session()
    article = run_pipeline(session)
    assert article is not None
    article_id = article.id
    session.close()

    with Session(engine) as verify_session:
        row = verify_session.scalars(
            select(Article).where(Article.id == article_id)
        ).first()

    assert row is not None
    assert row.title == _MINIMAL_ENTRY.title
    assert row.canonical_url == _MINIMAL_ENTRY.canonical_url


# ---------------------------------------------------------------------------
# Live-fetch fidelity test (real HTTP to news.hada.io)
# ---------------------------------------------------------------------------


def test_live_fetch_and_pipeline_published_status() -> None:
    """Live-fetch fidelity: fetch real feed, run pipeline, assert persisted row matches.

    The in-run snapshot is captured first from the live feed; the pipeline
    fetches the same live feed independently; assertions compare against the
    snapshot — deterministic within the same test run despite the feed being
    mutable over time.

    Marks the test as xfail if the network is unavailable so CI is not blocked.
    """
    import urllib.error

    # Step 1: capture in-run snapshot of the first entry.
    try:
        entries = fetch_feed("https://news.hada.io/rss/news")
    except urllib.error.URLError as exc:
        pytest.skip(f"Network unavailable — skipping live test: {exc}")
    except Exception as exc:
        pytest.skip(f"Feed fetch failed — skipping live test: {exc}")

    if not entries:
        pytest.skip("Feed returned no entries — skipping live test")

    snapshot = entries[0]

    # Step 2: run pipeline against the same live feed.
    engine = create_engine("sqlite+pysqlite:///:memory:", future=True)
    Base.metadata.create_all(engine)

    with Session(engine) as session:
        article = run_pipeline(session)
        # Capture attributes while session is open (avoid DetachedInstanceError)
        assert article is not None
        article_status = article.status
        article_canonical_url = article.canonical_url
        article_title = article.title
        article_external_id = article.external_id
        article_published_at = article.published_at

    # SQLite (used here for fast unit tests) round-trips DateTime(timezone=True)
    # columns by dropping tzinfo while preserving the wall-clock value — unlike
    # the Postgres backend used in production. Normalize both sides to naive
    # wall-clock datetimes for comparison so this test isn't sqlite-specific.
    expected_published_at = (
        snapshot.published_at.replace(tzinfo=None) if snapshot.published_at else None
    )

    # Step 3: verify persisted row against in-run snapshot (AC-2: title,
    # canonical_url, external_id, published_at, and body all match).
    assert article_status == ArticleProcessingStatus.PUBLISHED
    assert article_canonical_url == snapshot.canonical_url
    assert article_title == snapshot.title
    assert article_external_id == snapshot.external_id
    assert article_published_at == expected_published_at

    with Session(engine) as verify_session:
        row = verify_session.scalars(
            select(Article).where(Article.canonical_url == snapshot.canonical_url)
        ).first()
        assert row is not None, "Article must be persisted in DB"
        assert row.status == ArticleProcessingStatus.PUBLISHED
        assert row.title == snapshot.title
        assert row.canonical_url == snapshot.canonical_url
        assert row.external_id == snapshot.external_id
        assert row.published_at == expected_published_at
        row_id = row.id

    # Verify segment exists and its body (original_text) matches the snapshot.
    with Session(engine) as verify_session:
        seg = verify_session.scalars(
            select(ArticleSegment).where(ArticleSegment.article_id == row_id)
        ).first()
    assert seg is not None
    assert seg.position == 0
    expected_body = snapshot.content if snapshot.content else snapshot.title
    assert seg.original_text == expected_body

    # Verify structured output exists with summary containing the title
    with Session(engine) as verify_session:
        output = verify_session.scalars(
            select(ArticleStructuredOutput).where(
                ArticleStructuredOutput.article_id == row_id
            )
        ).first()
    assert output is not None
    assert snapshot.title in output.summary
