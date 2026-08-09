"""Tests for AC-3: Idempotent reprocessing of already-published articles.

Verifies that when an article has already been published (matched on
source_id + canonical_url via UniqueConstraint), a second pipeline run:
  - Returns None (no-op skip).
  - Produces no duplicate Article records.
  - Produces no duplicate ArticleSegment records.
  - Produces no duplicate ArticleStructuredOutput records.
  - Leaves the existing published Article row unmodified.

Also verifies multi-entry feed behaviour: when the first feed entry is already
published, the pipeline processes the next unprocessed entry rather than
skipping the whole run.

All tests use an in-memory SQLite database; the HTTP feed fetch is
monkeypatched so no network access is required.
"""
from __future__ import annotations

from collections.abc import Generator
from datetime import datetime, timezone

import pytest
from sqlalchemy import create_engine, select
from sqlalchemy.engine import Engine
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
    run_pipeline,
    upsert_source_registry,
)

# ---------------------------------------------------------------------------
# Shared test data
# ---------------------------------------------------------------------------

_ENTRY_A = FeedEntry(
    title="첫 번째 기사 제목",
    canonical_url="https://news.hada.io/topic?id=10001",
    content="첫 번째 기사 본문 내용입니다.",
    external_id="https://news.hada.io/topic?id=10001",
    published_at=datetime(2024, 6, 1, 10, 0, 0, tzinfo=timezone.utc),
)

_ENTRY_B = FeedEntry(
    title="두 번째 기사 제목",
    canonical_url="https://news.hada.io/topic?id=10002",
    content="두 번째 기사 본문 내용입니다.",
    external_id="https://news.hada.io/topic?id=10002",
    published_at=datetime(2024, 6, 2, 10, 0, 0, tzinfo=timezone.utc),
)

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture()
def engine() -> Engine:
    """Fresh in-memory SQLite engine with schema created."""
    eng = create_engine("sqlite+pysqlite:///:memory:", future=True)
    Base.metadata.create_all(eng)
    return eng


@pytest.fixture()
def session(engine: Engine) -> Generator[Session, None, None]:
    with Session(engine) as s:
        yield s


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------


def _run_with_feed(
    session: Session,
    entries: list[FeedEntry],
    monkeypatch: pytest.MonkeyPatch,
) -> Article | None:
    """Run the pipeline with the feed monkeypatched to return *entries*."""
    monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: entries)
    return run_pipeline(session)


# ---------------------------------------------------------------------------
# Core idempotency: second run returns None
# ---------------------------------------------------------------------------


def test_second_run_returns_none(engine: Engine, monkeypatch: pytest.MonkeyPatch) -> None:
    """Second run with the same single entry returns None — no-op skip."""
    with Session(engine) as session1:
        monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY_A])
        result1 = run_pipeline(session1)

    assert result1 is not None, "First run must return a published Article"
    assert result1.status == ArticleProcessingStatus.PUBLISHED

    with Session(engine) as session2:
        monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY_A])
        result2 = run_pipeline(session2)

    assert result2 is None, "Second run must return None for an already-published article"


# ---------------------------------------------------------------------------
# No duplicate Article rows
# ---------------------------------------------------------------------------


def test_no_duplicate_article_rows(engine: Engine, monkeypatch: pytest.MonkeyPatch) -> None:
    """Exactly one Article row persists after two runs with the same entry."""
    for _ in range(2):
        with Session(engine) as session:
            monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY_A])
            run_pipeline(session)

    with Session(engine) as verify:
        source = verify.scalars(
            select(SourceRegistryEntry).where(SourceRegistryEntry.slug == GEEKNEWS_SLUG)
        ).first()
        assert source is not None

        articles = list(
            verify.scalars(
                select(Article).where(
                    Article.source_id == source.id,
                    Article.canonical_url == _ENTRY_A.canonical_url,
                )
            ).all()
        )

    assert len(articles) == 1, f"Expected 1 Article row, found {len(articles)}"


# ---------------------------------------------------------------------------
# No duplicate ArticleSegment rows
# ---------------------------------------------------------------------------


def test_no_duplicate_segment_rows(engine: Engine, monkeypatch: pytest.MonkeyPatch) -> None:
    """Exactly one ArticleSegment at position=0 after two runs with the same entry."""
    article_id: str | None = None

    with Session(engine) as session1:
        monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY_A])
        article = run_pipeline(session1)
        assert article is not None
        article_id = article.id

    with Session(engine) as session2:
        monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY_A])
        run_pipeline(session2)

    with Session(engine) as verify:
        segments = list(
            verify.scalars(
                select(ArticleSegment).where(ArticleSegment.article_id == article_id)
            ).all()
        )

    assert len(segments) == 1, f"Expected 1 ArticleSegment, found {len(segments)}"
    assert segments[0].position == 0


# ---------------------------------------------------------------------------
# No duplicate ArticleStructuredOutput rows
# ---------------------------------------------------------------------------


def test_no_duplicate_structured_output_rows(
    engine: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Exactly one ArticleStructuredOutput after two runs with the same entry."""
    article_id: str | None = None

    with Session(engine) as session1:
        monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY_A])
        article = run_pipeline(session1)
        assert article is not None
        article_id = article.id

    with Session(engine) as session2:
        monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY_A])
        run_pipeline(session2)

    with Session(engine) as verify:
        outputs = list(
            verify.scalars(
                select(ArticleStructuredOutput).where(
                    ArticleStructuredOutput.article_id == article_id
                )
            ).all()
        )

    assert len(outputs) == 1, f"Expected 1 ArticleStructuredOutput, found {len(outputs)}"


# ---------------------------------------------------------------------------
# Existing published article is untouched on skip
# ---------------------------------------------------------------------------


def test_existing_article_not_modified_on_skip(
    engine: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    """The existing published Article row is not modified when the second run skips it."""
    with Session(engine) as session1:
        monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY_A])
        article = run_pipeline(session1)
        assert article is not None
        original_id = article.id
        original_title = article.title
        original_canonical_url = article.canonical_url
        original_status = article.status

    # Second run — should skip
    with Session(engine) as session2:
        monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY_A])
        run_pipeline(session2)

    # Verify the original row is unchanged
    with Session(engine) as verify:
        row = verify.scalars(
            select(Article).where(Article.id == original_id)
        ).first()

    assert row is not None
    assert row.id == original_id
    assert row.title == original_title
    assert row.canonical_url == original_canonical_url
    assert row.status == original_status == ArticleProcessingStatus.PUBLISHED


# ---------------------------------------------------------------------------
# Multi-entry feed: first published → second is processed
# ---------------------------------------------------------------------------


def test_second_entry_processed_when_first_already_published(
    engine: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    """When the first feed entry is already published, the pipeline processes the next one."""
    # First run: processes _ENTRY_A (first in feed order)
    with Session(engine) as session1:
        monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY_A, _ENTRY_B])
        result1 = run_pipeline(session1)
    assert result1 is not None
    assert result1.canonical_url == _ENTRY_A.canonical_url
    assert result1.status == ArticleProcessingStatus.PUBLISHED

    # Second run: _ENTRY_A already published → processes _ENTRY_B
    with Session(engine) as session2:
        monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY_A, _ENTRY_B])
        result2 = run_pipeline(session2)
    assert result2 is not None
    assert result2.canonical_url == _ENTRY_B.canonical_url
    assert result2.status == ArticleProcessingStatus.PUBLISHED

    # Third run: both already published → returns None
    with Session(engine) as session3:
        monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY_A, _ENTRY_B])
        result3 = run_pipeline(session3)
    assert result3 is None, "Third run must skip when all entries are already published"


# ---------------------------------------------------------------------------
# Idempotency when article is pre-inserted directly (not via pipeline)
# ---------------------------------------------------------------------------


def test_skip_when_article_pre_inserted(
    engine: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Pipeline skips an entry whose canonical_url is already in the DB (any method of insert)."""
    from app.models import now_utc

    # Directly insert a PUBLISHED article with _ENTRY_A's canonical_url
    with Session(engine) as setup_session:
        source = upsert_source_registry(setup_session)
        pre_article = Article(
            source_id=source.id,
            canonical_url=_ENTRY_A.canonical_url,
            title=_ENTRY_A.title,
            ingested_at=now_utc(),
            status=ArticleProcessingStatus.PUBLISHED,
        )
        setup_session.add(pre_article)
        setup_session.commit()
        pre_article_id = pre_article.id

    # Run pipeline with _ENTRY_A in the feed → must skip it
    with Session(engine) as session:
        monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY_A])
        result = run_pipeline(session)

    assert result is None, "Pipeline must skip an entry already present in DB"

    # Verify exactly one Article row exists with _ENTRY_A's canonical_url
    with Session(engine) as verify:
        rows = list(
            verify.scalars(
                select(Article).where(Article.canonical_url == _ENTRY_A.canonical_url)
            ).all()
        )

    assert len(rows) == 1, "Must have exactly one Article row — no duplicate after skip"
    assert rows[0].id == pre_article_id, "The pre-inserted row must be unchanged"


# ---------------------------------------------------------------------------
# No SourceRegistryEntry duplicates across multiple runs
# ---------------------------------------------------------------------------


def test_no_duplicate_source_registry_entries(
    engine: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    """Multiple pipeline runs produce exactly one SourceRegistryEntry for GeekNews."""
    for _ in range(3):
        with Session(engine) as session:
            monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY_A])
            run_pipeline(session)

    with Session(engine) as verify:
        sources = list(
            verify.scalars(
                select(SourceRegistryEntry).where(SourceRegistryEntry.slug == GEEKNEWS_SLUG)
            ).all()
        )

    assert len(sources) == 1, f"Expected 1 SourceRegistryEntry, found {len(sources)}"
