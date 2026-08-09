"""Tests for AC-7: SourceRegistryEntry auto-upsert for GeekNews.

Verifies that upsert_source_registry():
  - Creates a GeekNews entry with the correct fields on first run.
  - Is idempotent: repeat calls produce no duplicate row.
  - Commits independently of any subsequent article transaction.

All tests use an in-memory SQLite database — no network or external
database access required.
"""
from sqlalchemy import create_engine, select
from sqlalchemy.orm import Session

from app.models import Base, SourceRegistryEntry
from app.pipeline import (
    GEEKNEWS_BASE_URL,
    GEEKNEWS_DEFAULT_LANGUAGE,
    GEEKNEWS_SLUG,
    upsert_source_registry,
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _build_session() -> Session:
    """Return a session backed by a fresh in-memory SQLite database."""
    engine = create_engine("sqlite+pysqlite:///:memory:", future=True)
    Base.metadata.create_all(engine)
    return Session(engine)


def _build_engine_and_session() -> tuple:  # type: ignore[type-arg]
    """Return (engine, session) for tests that open multiple sessions."""
    from sqlalchemy import Engine

    engine: Engine = create_engine("sqlite+pysqlite:///:memory:", future=True)
    Base.metadata.create_all(engine)
    return engine, Session(engine)


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------


def test_upsert_creates_geeknews_entry_on_first_run() -> None:
    """First call creates a SourceRegistryEntry with the correct GeekNews fields."""
    session = _build_session()

    entry = upsert_source_registry(session)

    assert entry.slug == GEEKNEWS_SLUG
    assert entry.base_url == GEEKNEWS_BASE_URL
    assert entry.default_language == GEEKNEWS_DEFAULT_LANGUAGE
    assert entry.id, "id must be a non-empty UUID string"


def test_upsert_slug_is_geeknews() -> None:
    """The slug is fixed to 'geeknews'."""
    session = _build_session()

    entry = upsert_source_registry(session)

    assert entry.slug == "geeknews"


def test_upsert_base_url_is_news_hada_io() -> None:
    """The base_url is fixed to 'https://news.hada.io'."""
    session = _build_session()

    entry = upsert_source_registry(session)

    assert entry.base_url == "https://news.hada.io"


def test_upsert_default_language_is_ko() -> None:
    """The default_language is fixed to 'ko' (Korean)."""
    session = _build_session()

    entry = upsert_source_registry(session)

    assert entry.default_language == "ko"


def test_upsert_is_idempotent_same_session() -> None:
    """Calling upsert_source_registry twice on the same session returns the same row."""
    session = _build_session()

    entry1 = upsert_source_registry(session)
    entry2 = upsert_source_registry(session)

    assert entry1.id == entry2.id

    # Exactly one row in the database
    all_rows = list(
        session.scalars(
            select(SourceRegistryEntry).where(SourceRegistryEntry.slug == GEEKNEWS_SLUG)
        ).all()
    )
    assert len(all_rows) == 1


def test_upsert_committed_independently_of_article_transaction() -> None:
    """The upsert commits immediately; a fresh session sees the committed row.

    This verifies the upsert is durable even when no article transaction
    follows (simulating a fetch-failure path where the article transaction
    is separate).
    """
    engine, session1 = _build_engine_and_session()

    # Upsert commits; close the session without any additional work
    upsert_source_registry(session1)
    session1.close()

    # A brand-new session against the same engine must see the committed row
    with Session(engine) as session2:
        found = session2.scalars(
            select(SourceRegistryEntry).where(SourceRegistryEntry.slug == GEEKNEWS_SLUG)
        ).first()

    assert found is not None, "GeekNews entry must be durably committed"
    assert found.slug == GEEKNEWS_SLUG
    assert found.base_url == GEEKNEWS_BASE_URL
    assert found.default_language == GEEKNEWS_DEFAULT_LANGUAGE


def test_upsert_no_duplicate_across_sessions() -> None:
    """Two separate sessions against the same DB produce no duplicate row."""
    engine, session1 = _build_engine_and_session()

    upsert_source_registry(session1)
    session1.close()

    with Session(engine) as session2:
        entry2 = upsert_source_registry(session2)

    with Session(engine) as session3:
        all_rows = list(
            session3.scalars(
                select(SourceRegistryEntry).where(SourceRegistryEntry.slug == GEEKNEWS_SLUG)
            ).all()
        )

    assert len(all_rows) == 1
    assert entry2.slug == GEEKNEWS_SLUG
