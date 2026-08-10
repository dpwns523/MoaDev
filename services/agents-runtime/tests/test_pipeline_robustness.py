"""Regression tests for two bugs found by code review on this PR:

  - TOCTOU race: the idempotency check-then-insert in run_pipeline and
    upsert_source_registry is not atomic. If a concurrent run wins the
    race and inserts first, our commit must fall back to the winner's row
    instead of propagating an unhandled IntegrityError.
  - DetachedInstanceError: the object returned by run_pipeline must expose
    its segments/structured_output relationships even after the session
    that created them has been closed.

All tests use an in-memory SQLite database; no network access required.
"""
from __future__ import annotations

from datetime import datetime, timezone

import pytest
from sqlalchemy import create_engine, select
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session

from app.models import (
    Article,
    ArticleProcessingStatus,
    Base,
    SourceRegistryEntry,
    now_utc,
)
from app.pipeline import (
    GEEKNEWS_SLUG,
    FeedEntry,
    run_pipeline,
    upsert_source_registry,
)

_ENTRY = FeedEntry(
    title="동시성 테스트 기사",
    canonical_url="https://news.hada.io/topic?id=77777",
    content="레이스 컨디션 테스트용 본문입니다.",
    external_id="https://news.hada.io/topic?id=77777",
    published_at=datetime(2024, 3, 1, 0, 0, 0, tzinfo=timezone.utc),
)


@pytest.fixture()
def engine() -> Engine:
    eng = create_engine("sqlite+pysqlite:///:memory:", future=True)
    Base.metadata.create_all(eng)
    return eng


# ---------------------------------------------------------------------------
# TOCTOU race: article insert
# ---------------------------------------------------------------------------


def test_run_pipeline_race_falls_back_to_concurrent_winner(
    engine: Engine, monkeypatch: pytest.MonkeyPatch
) -> None:
    """If another session inserts the same canonical_url after our idempotency
    check but before our commit, run_pipeline must return that row instead of
    raising an unhandled IntegrityError."""
    winner_id: dict[str, str] = {}

    def _win_the_race_then_summarize(title: str) -> str:
        # Runs after run_pipeline's idempotency check has already passed —
        # simulates a concurrent pipeline run that inserts first.
        with Session(engine) as racer_session:
            source = upsert_source_registry(racer_session)
            winner = Article(
                source_id=source.id,
                canonical_url=_ENTRY.canonical_url,
                title="Concurrent winner",
                ingested_at=now_utc(),
                status=ArticleProcessingStatus.PUBLISHED,
            )
            racer_session.add(winner)
            racer_session.commit()
            winner_id["value"] = winner.id
        from app.enrichment import generate_summary

        return generate_summary(title)

    monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY])
    monkeypatch.setattr("app.pipeline.generate_summary", _win_the_race_then_summarize)

    with Session(engine) as session:
        result = run_pipeline(session)

    assert result is not None, "must return the winner's row, not raise"
    assert result.id == winner_id["value"]

    with Session(engine) as verify:
        rows = list(
            verify.scalars(
                select(Article).where(Article.canonical_url == _ENTRY.canonical_url)
            ).all()
        )
    assert len(rows) == 1, "no duplicate row after the race"


# ---------------------------------------------------------------------------
# TOCTOU race: source registry upsert
# ---------------------------------------------------------------------------


def test_upsert_source_registry_survives_concurrent_insert(engine: Engine) -> None:
    """If a concurrent transaction commits the GeekNews row between our
    existence check and our own commit, the resulting IntegrityError must be
    recovered from by returning the row the other transaction won with."""
    winner_id: dict[str, str] = {}

    with Session(engine) as session:
        real_commit = session.commit
        raced = {"done": False}

        def racing_commit() -> None:
            if not raced["done"]:
                raced["done"] = True
                # Another session wins the race and commits first, right
                # before our own (already in-flight) commit is called.
                with Session(engine) as racer_session:
                    winner = SourceRegistryEntry(
                        slug=GEEKNEWS_SLUG,
                        display_name="GeekNews",
                        base_url="https://news.hada.io",
                        default_language="ko",
                    )
                    racer_session.add(winner)
                    racer_session.commit()
                    winner_id["value"] = winner.id
            real_commit()

        session.commit = racing_commit  # type: ignore[method-assign]
        result = upsert_source_registry(session)

    assert result.slug == GEEKNEWS_SLUG
    assert result.id == winner_id["value"], "must return the concurrent winner's row"

    with Session(engine) as verify:
        rows = list(
            verify.scalars(
                select(SourceRegistryEntry).where(SourceRegistryEntry.slug == GEEKNEWS_SLUG)
            ).all()
        )
    assert len(rows) == 1, "no duplicate source registry row after the race"


# ---------------------------------------------------------------------------
# DetachedInstanceError: relationships accessible after session close
# ---------------------------------------------------------------------------


def test_run_pipeline_result_relationships_survive_session_close(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """article.segments and article.structured_output must be readable
    after the session that produced them has already closed."""
    engine = create_engine("sqlite+pysqlite:///:memory:", future=True)
    Base.metadata.create_all(engine)

    monkeypatch.setattr("app.pipeline.fetch_feed", lambda url: [_ENTRY])

    with Session(engine) as session:
        article = run_pipeline(session)

    assert article is not None
    # Session is closed at this point — these must not raise DetachedInstanceError.
    assert len(article.segments) == 1
    assert article.segments[0].position == 0
    assert article.structured_output is not None
    assert article.structured_output.summary
