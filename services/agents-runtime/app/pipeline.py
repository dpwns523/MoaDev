"""GeekNews ingestion/enrichment pipeline scaffold.

Processes exactly one GeekNews (news.hada.io) article per run through:
  intake → enrichment → publish

with real HTTP fetch, deterministic enrichment stub, explicit
(code-level) status transitions, idempotent persistence, and output
consumable by the existing article detail API.

Environment variables (AGENTS_RUNTIME_* convention):
  AGENTS_RUNTIME_GEEKNEWS_FEED_URL — Atom feed URL; defaults to
                                      https://news.hada.io/rss/news

Database connectivity is the caller's responsibility (a Session is passed
in); this module does not read a database URL from the environment itself.
"""
from __future__ import annotations

import logging
import os
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from datetime import datetime
from email.utils import parsedate_to_datetime

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, selectinload

from app.enrichment import generate_summary, translate_text
from app.models import (
    Article,
    ArticleProcessingStatus,
    ArticleSegment,
    ArticleStructuredOutput,
    SourceRegistryEntry,
    generate_uuid,
    now_utc,
)

LOGGER = logging.getLogger(__name__)

# DB column length limits (must match app/models.py String(...) definitions).
# Enforced here so a malformed/adversarial feed entry is rejected at the
# parse boundary instead of failing later with an opaque DB-level error.
_MAX_TITLE_LENGTH = 500
_MAX_CANONICAL_URL_LENGTH = 2048
_MAX_EXTERNAL_ID_LENGTH = 255

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

GEEKNEWS_SLUG = "geeknews"
GEEKNEWS_DISPLAY_NAME = "GeekNews"
GEEKNEWS_BASE_URL = "https://news.hada.io"
GEEKNEWS_DEFAULT_LANGUAGE = "ko"
GEEKNEWS_DEFAULT_FEED_URL = "https://news.hada.io/rss/news"

# Atom namespace
_ATOM_NS = "http://www.w3.org/2005/Atom"


# ---------------------------------------------------------------------------
# Feed data structures
# ---------------------------------------------------------------------------


@dataclass
class FeedEntry:
    """Parsed representation of a single Atom feed entry."""

    title: str
    canonical_url: str
    content: str
    external_id: str | None = None
    published_at: datetime | None = None


# ---------------------------------------------------------------------------
# Feed fetching / parsing
# ---------------------------------------------------------------------------


def fetch_feed(feed_url: str) -> list[FeedEntry]:
    """Fetch and parse the GeekNews Atom RSS feed.

    Performs a real HTTP GET to *feed_url* and returns parsed feed entries
    in the natural feed order (newest first).

    Args:
        feed_url: URL of the Atom feed to fetch.

    Returns:
        List of FeedEntry objects parsed from the feed.

    Raises:
        urllib.error.URLError: On network/HTTP failure.
        xml.etree.ElementTree.ParseError: If the response body is not valid XML.
    """
    req = urllib.request.Request(
        feed_url,
        headers={"User-Agent": "MoaDev-AgentsRuntime/0.1 (+https://github.com/moadev)"},
    )
    with urllib.request.urlopen(req, timeout=30) as response:
        raw_bytes: bytes = response.read()

    root = ET.fromstring(raw_bytes.decode("utf-8"))

    entries: list[FeedEntry] = []
    for entry_el in root.findall(f"{{{_ATOM_NS}}}entry"):
        title_el = entry_el.find(f"{{{_ATOM_NS}}}title")
        title = (title_el.text or "").strip() if title_el is not None else ""

        # <id> is looked up once and reused for both the canonical_url
        # fallback and external_id, instead of being searched twice.
        id_el = entry_el.find(f"{{{_ATOM_NS}}}id")
        id_text = (id_el.text or "").strip() if id_el is not None else ""

        # canonical_url: prefer <link rel="alternate">, fall back to <id>
        canonical_url = ""
        for link_el in entry_el.findall(f"{{{_ATOM_NS}}}link"):
            rel = link_el.get("rel", "alternate")
            if rel == "alternate":
                canonical_url = link_el.get("href", "").strip()
                break
        if not canonical_url:
            canonical_url = id_text

        external_id: str | None = id_text or None

        # published_at
        published_at: datetime | None = None
        published_el = entry_el.find(f"{{{_ATOM_NS}}}published")
        if published_el is not None and published_el.text:
            # Atom's <published> is spec'd as ISO-8601/RFC-3339, so try that
            # first; RFC-822 (email-style) is only a defensive fallback for
            # non-conformant feeds, not the expected format.
            try:
                published_at = datetime.fromisoformat(
                    published_el.text.replace("Z", "+00:00")
                )
            except (TypeError, ValueError):
                try:
                    published_at = parsedate_to_datetime(published_el.text)
                except (TypeError, ValueError):
                    published_at = None

        # content: prefer <content>, fall back to <summary>
        content_el = entry_el.find(f"{{{_ATOM_NS}}}content")
        summary_el = entry_el.find(f"{{{_ATOM_NS}}}summary")
        content = ""
        if content_el is not None and content_el.text:
            content = content_el.text.strip()
        elif summary_el is not None and summary_el.text:
            content = summary_el.text.strip()

        if not title or not canonical_url:
            continue

        # Boundary validation: reject entries that would only fail later at
        # DB-insert time with an opaque driver error. Never trust external
        # feed data to already respect our column limits.
        if len(title) > _MAX_TITLE_LENGTH:
            LOGGER.warning(
                "skipping feed entry: title exceeds %s chars (got %s)",
                _MAX_TITLE_LENGTH,
                len(title),
            )
            continue
        if len(canonical_url) > _MAX_CANONICAL_URL_LENGTH:
            LOGGER.warning(
                "skipping feed entry: canonical_url exceeds %s chars (got %s)",
                _MAX_CANONICAL_URL_LENGTH,
                len(canonical_url),
            )
            continue
        if external_id and len(external_id) > _MAX_EXTERNAL_ID_LENGTH:
            LOGGER.warning(
                "skipping feed entry: external_id exceeds %s chars (got %s)",
                _MAX_EXTERNAL_ID_LENGTH,
                len(external_id),
            )
            continue

        entries.append(
            FeedEntry(
                title=title,
                canonical_url=canonical_url,
                content=content,
                external_id=external_id if external_id else None,
                published_at=published_at,
            )
        )

    return entries


# ---------------------------------------------------------------------------
# Source registry upsert (AC-7)
# ---------------------------------------------------------------------------


def _detach_with_loaded_attributes(session: Session, article_id: str) -> Article:
    """Reload the article at *article_id* with its relationships eagerly
    loaded, then detach the whole object graph from *session*.

    Callers (tests, worker code) may access the returned object's scalar
    *and relationship* attributes (``segments``, ``structured_output``)
    after the caller's ``with Session(...)`` block has already closed the
    session. A bare ``session.refresh(article)`` only reloads scalar column
    attributes, not relationships — accessing ``article.segments`` after
    the session closes would still raise DetachedInstanceError. Re-querying
    with explicit eager-load options (mirroring
    ``services/api/app/domain/articles/service.get_article``) makes both
    load. Expunging just the parent is enough — Article.segments and
    Article.structured_output use cascade="all, delete-orphan", and "all"
    already includes the expunge cascade, so expunging the children again
    afterward would raise (they're no longer in the session by then).
    """
    article = session.scalars(
        select(Article)
        .options(
            selectinload(Article.segments),
            selectinload(Article.structured_output),
        )
        .where(Article.id == article_id)
    ).one()
    session.expunge(article)
    return article


def upsert_source_registry(session: Session) -> SourceRegistryEntry:
    """Idempotently ensure the GeekNews source registry entry exists.

    Commits immediately in its own transaction, independent of any
    subsequent per-article intake/enrichment transaction.  Calling this
    function a second time with the same session returns the existing row
    without inserting a duplicate.

    Concurrency: the existence check and the insert are not atomic, so two
    overlapping calls (different sessions/processes) can both see no
    existing row and both attempt to insert. If our insert loses that race,
    the UniqueConstraint on ``slug`` raises IntegrityError on commit; we
    roll back and return the row the other call already committed instead
    of propagating the crash.

    Args:
        session: An open SQLAlchemy Session.  The function commits within
                 this session (autobegin starts a fresh transaction for
                 the next operation automatically).

    Returns:
        The (possibly newly created) SourceRegistryEntry for GeekNews.
    """
    existing = session.scalars(
        select(SourceRegistryEntry).where(SourceRegistryEntry.slug == GEEKNEWS_SLUG)
    ).first()

    if existing is not None:
        return existing

    entry = SourceRegistryEntry(
        slug=GEEKNEWS_SLUG,
        display_name=GEEKNEWS_DISPLAY_NAME,
        base_url=GEEKNEWS_BASE_URL,
        default_language=GEEKNEWS_DEFAULT_LANGUAGE,
    )
    session.add(entry)
    try:
        session.commit()
    except IntegrityError:
        session.rollback()
        winner = session.scalars(
            select(SourceRegistryEntry).where(SourceRegistryEntry.slug == GEEKNEWS_SLUG)
        ).first()
        if winner is None:
            raise
        return winner
    return entry


# ---------------------------------------------------------------------------
# Main pipeline (AC-5 / AC-6)
# ---------------------------------------------------------------------------


def run_pipeline(
    session: Session,
    feed_url: str | None = None,
) -> Article | None:
    """Run the GeekNews ingestion/enrichment pipeline for exactly one article.

    The pipeline executes in two independent phases:

    Phase 1 — Source upsert (always committed):
        Idempotently ensures the GeekNews SourceRegistryEntry exists and
        commits it immediately in its own transaction.

    Phase 2 — Article intake/enrichment (single transaction):
        Fetches the feed, picks the first not-yet-published article, enriches
        it with a deterministic summary, then commits all objects atomically at
        the PUBLISHED terminal status.

        On fetch failure: commits only the FAILED status + status_reason in a
        single transaction; no segments or structured outputs are written.

        If all feed entries are already published: returns None (no-op skip).

        Concurrency: if another overlapping run wins the race to insert the
        same canonical_url first, our commit's UniqueConstraint violation is
        caught and we return the winner's row instead of raising.

    Persisted status is always a single terminal value — PUBLISHED on
    success, FAILED on fetch failure — written once at construction time.
    No intermediate status is ever committed for a row.

    Args:
        session: An open SQLAlchemy Session.
        feed_url: Override the feed URL (defaults to
                  AGENTS_RUNTIME_GEEKNEWS_FEED_URL env var or the live URL).

    Returns:
        The persisted Article (status PUBLISHED or FAILED), or None if all
        entries were already processed.
    """
    resolved_feed_url = feed_url or os.environ.get(
        "AGENTS_RUNTIME_GEEKNEWS_FEED_URL", GEEKNEWS_DEFAULT_FEED_URL
    )

    # Phase 1: Source registry upsert — committed independently.
    source = upsert_source_registry(session)

    # Phase 2: Article intake/enrichment — single transaction.
    try:
        entries = fetch_feed(resolved_feed_url)
    except Exception as exc:
        # transition to FAILED per AC-6, not just network errors.
        LOGGER.exception("GeekNews feed fetch/parse failed url=%s", resolved_feed_url)
        # Fetch failure: commit FAILED status in a single transaction.
        # Use a unique synthetic URL so the UniqueConstraint is never violated
        # across repeated failure runs.
        failure_url = f"{resolved_feed_url}#intake-failed-{generate_uuid()}"
        article = Article(
            source_id=source.id,
            canonical_url=failure_url,
            title="[피드 수집 실패]",
            ingested_at=now_utc(),
            status=ArticleProcessingStatus.FAILED,
            status_reason=str(exc),
        )
        session.add(article)
        session.commit()
        return _detach_with_loaded_attributes(session, article.id)

    # Find first not-yet-published entry (idempotency check). One query
    # fetches every already-processed canonical_url for this source up
    # front, instead of one SELECT per feed entry (N+1).
    already_processed = set(
        session.scalars(
            select(Article.canonical_url).where(Article.source_id == source.id)
        ).all()
    )
    target: FeedEntry | None = next(
        (entry for entry in entries if entry.canonical_url not in already_processed),
        None,
    )

    if target is None:
        # All entries already processed — skip.
        return None

    # Enrich: translation is pass-through copy; summary is deterministic stub.
    original_text = target.content if target.content else target.title
    summary = generate_summary(target.title)

    # Status is set once, directly to its terminal value — not mutated
    # through intermediate in-memory states, since nothing ever reads or
    # persists those intermediate values before the final commit below.
    article = Article(
        source_id=source.id,
        canonical_url=target.canonical_url,
        external_id=target.external_id,
        title=target.title,
        ingested_at=now_utc(),
        published_at=target.published_at,
        status=ArticleProcessingStatus.PUBLISHED,
    )

    segment = ArticleSegment(
        article=article,
        position=0,
        original_text=original_text,
        translated_text=translate_text(original_text),
    )

    structured_output = ArticleStructuredOutput(
        article=article,
        summary=summary,
    )

    # Single all-or-nothing commit.
    session.add(article)
    session.add(segment)
    session.add(structured_output)
    try:
        session.commit()
    except IntegrityError:
        # Another overlapping run already inserted this canonical_url first.
        session.rollback()
        winner = session.scalars(
            select(Article).where(
                Article.source_id == source.id,
                Article.canonical_url == target.canonical_url,
            )
        ).first()
        if winner is None:
            raise
        return _detach_with_loaded_attributes(session, winner.id)

    return _detach_with_loaded_attributes(session, article.id)
