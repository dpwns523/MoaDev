from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session, joinedload, selectinload

from app.domain.articles.models import Article, SourceRegistryEntry


ACRONYM_WORDS = {
    "ai": "AI",
    "api": "API",
    "ci": "CI",
    "ml": "ML",
    "oss": "OSS",
}


@dataclass(frozen=True)
class CategorySummary:
    slug: str
    display_name: str
    article_count: int


class ArticleLookupError(LookupError):
    pass


def list_category_summaries(session: Session) -> list[CategorySummary]:
    query = (
        select(Article.category_slug, func.count(Article.id))
        .where(Article.category_slug.is_not(None))
        .group_by(Article.category_slug)
        .order_by(Article.category_slug.asc())
    )

    return [
        CategorySummary(
            slug=category_slug,
            display_name=build_category_display_name(category_slug),
            article_count=article_count,
        )
        for category_slug, article_count in session.execute(query).all()
        if category_slug is not None
    ]


def list_articles(
    session: Session,
    *,
    category_slug: Optional[str] = None,
    source_slug: Optional[str] = None,
) -> list[Article]:
    query = (
        select(Article)
        .options(joinedload(Article.source))
        .order_by(
            Article.published_at.is_(None).asc(),
            Article.published_at.desc(),
            Article.ingested_at.desc(),
            Article.id.asc(),
        )
    )

    if source_slug:
        query = query.join(Article.source).where(SourceRegistryEntry.slug == source_slug)

    if category_slug:
        query = query.where(Article.category_slug == category_slug)

    return list(session.scalars(query).unique().all())


def get_article(session: Session, article_id: str) -> Article:
    query = (
        select(Article)
        .options(
            joinedload(Article.source),
            joinedload(Article.structured_output),
            selectinload(Article.segments),
        )
        .where(or_(Article.external_id == article_id, Article.id == article_id))
    )

    article = session.scalars(query).unique().first()
    if article is None:
        raise ArticleLookupError(article_id)

    return article


def build_category_display_name(category_slug: str) -> str:
    parts = category_slug.split("-")
    return " ".join(ACRONYM_WORDS.get(part, part.capitalize()) for part in parts)


def get_public_article_id(article: Article) -> str:
    return article.external_id or article.id
