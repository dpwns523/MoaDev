"""Tests for AC-6: Fetch failure commits terminal FAILED status.

Verifies that when the HTTP feed fetch fails:
  - An Article row is committed with status=FAILED.
  - status_reason is set and contains the error context.
  - No ArticleSegment or ArticleStructuredOutput rows are written.
  - The committed row is visible to a fresh session (truly durable).
  - The SourceRegistryEntry upsert was committed independently
    (present even after the article transaction fails).
  - No partial intermediate state is persisted.

All tests use an in-memory SQLite database — no network access required.
The HTTP fetch is patched to raise an exception, simulating a network failure.
"""
from __future__ import annotations

import urllib.error
from collections.abc import Generator
from unittest.mock import patch

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
    run_pipeline,
)

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

FAKE_FEED_URL = "https://news.hada.io/rss/news"


def _make_engine() -> Engine:
    """Return a fresh in-memory SQLite engine with schema created."""
    engine = create_engine("sqlite+pysqlite:///:memory:", future=True)
    Base.metadata.create_all(engine)
    return engine


@pytest.fixture()
def engine() -> Engine:
    return _make_engine()


@pytest.fixture()
def session(engine: Engine) -> Generator[Session, None, None]:
    with Session(engine) as s:
        yield s


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _run_with_fetch_failure(
    session: Session,
    error: Exception,
    feed_url: str = FAKE_FEED_URL,
) -> Article:
    """Run the pipeline with urlopen patched to raise *error*."""
    with patch("urllib.request.urlopen", side_effect=error):
        result = run_pipeline(session, feed_url=feed_url)
    assert result is not None, "run_pipeline must return an Article on fetch failure"
    return result


# ---------------------------------------------------------------------------
# Tests — status and status_reason
# ---------------------------------------------------------------------------


def test_fetch_failure_article_status_is_failed(session: Session) -> None:
    """Article status must be FAILED after a fetch failure."""
    error = urllib.error.URLError("connection refused")
    article = _run_with_fetch_failure(session, error)

    assert article.status == ArticleProcessingStatus.FAILED


def test_fetch_failure_status_reason_is_set(session: Session) -> None:
    """status_reason must be non-empty and reflect the error."""
    error = urllib.error.URLError("connection refused")
    article = _run_with_fetch_failure(session, error)

    assert article.status_reason is not None
    assert len(article.status_reason) > 0


def test_fetch_failure_status_reason_contains_error_message(session: Session) -> None:
    """status_reason must contain the exception message."""
    error = urllib.error.URLError("timeout reading feed")
    article = _run_with_fetch_failure(session, error)

    assert "timeout reading feed" in article.status_reason  # type: ignore[operator]


def test_fetch_failure_status_reason_set_for_generic_exception(session: Session) -> None:
    """status_reason is populated for any Exception subclass, not only URLError."""
    error = OSError("DNS resolution failed")
    article = _run_with_fetch_failure(session, error)

    assert article.status == ArticleProcessingStatus.FAILED
    assert article.status_reason is not None
    assert "DNS resolution failed" in article.status_reason  # type: ignore[operator]


# ---------------------------------------------------------------------------
# Tests — no partial intermediate state
# ---------------------------------------------------------------------------


def test_fetch_failure_no_article_segment(engine: Engine, session: Session) -> None:
    """No ArticleSegment must be written on fetch failure."""
    error = urllib.error.URLError("network error")
    article = _run_with_fetch_failure(session, error)

    with Session(engine) as verify_session:
        segments = list(
            verify_session.scalars(
                select(ArticleSegment).where(ArticleSegment.article_id == article.id)
            ).all()
        )

    assert segments == [], "No ArticleSegment must exist after a fetch failure"


def test_fetch_failure_no_structured_output(engine: Engine, session: Session) -> None:
    """No ArticleStructuredOutput must be written on fetch failure."""
    error = urllib.error.URLError("network error")
    article = _run_with_fetch_failure(session, error)

    with Session(engine) as verify_session:
        output = verify_session.scalars(
            select(ArticleStructuredOutput).where(
                ArticleStructuredOutput.article_id == article.id
            )
        ).first()

    assert output is None, "No ArticleStructuredOutput must exist after a fetch failure"


# ---------------------------------------------------------------------------
# Tests — durability (fresh session confirms commit)
# ---------------------------------------------------------------------------


def test_fetch_failure_article_is_durably_committed(engine: Engine, session: Session) -> None:
    """The FAILED Article row must be visible in a fresh session."""
    error = urllib.error.URLError("network error")
    article = _run_with_fetch_failure(session, error)

    with Session(engine) as verify_session:
        found = verify_session.scalars(
            select(Article).where(Article.id == article.id)
        ).first()

    assert found is not None, "Article must be durably committed"
    assert found.status == ArticleProcessingStatus.FAILED
    assert found.status_reason is not None


# ---------------------------------------------------------------------------
# Tests — source registry independence
# ---------------------------------------------------------------------------


def test_source_registry_committed_before_article_failure(
    engine: Engine, session: Session
) -> None:
    """SourceRegistryEntry is committed even when the article transaction fails."""
    error = urllib.error.URLError("network error")
    _run_with_fetch_failure(session, error)

    with Session(engine) as verify_session:
        source = verify_session.scalars(
            select(SourceRegistryEntry).where(SourceRegistryEntry.slug == GEEKNEWS_SLUG)
        ).first()

    assert source is not None, "GeekNews source must be committed independently of article failure"
    assert source.slug == GEEKNEWS_SLUG


# ---------------------------------------------------------------------------
# Tests — single transaction (no intermediate state)
# ---------------------------------------------------------------------------


def test_fetch_failure_only_one_article_row(engine: Engine, session: Session) -> None:
    """Exactly one Article row is committed per failed run — no partial rows."""
    error = urllib.error.URLError("network error")
    article = _run_with_fetch_failure(session, error)

    with Session(engine) as verify_session:
        source = verify_session.scalars(
            select(SourceRegistryEntry).where(SourceRegistryEntry.slug == GEEKNEWS_SLUG)
        ).first()
        assert source is not None
        all_articles = list(
            verify_session.scalars(
                select(Article).where(Article.source_id == source.id)
            ).all()
        )

    assert len(all_articles) == 1
    assert all_articles[0].id == article.id
    assert all_articles[0].status == ArticleProcessingStatus.FAILED
