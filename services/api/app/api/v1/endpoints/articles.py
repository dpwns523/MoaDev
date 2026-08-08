from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api.dependencies.db import get_db_session
from app.domain.articles.models import Article, ArticleStructuredOutput
from app.domain.articles.service import (
    ArticleLookupError,
    build_category_display_name,
    get_article,
    get_public_article_id,
    list_articles,
)
from app.schemas.article import (
    ArticleDetailItem,
    ArticleDetailResponse,
    ArticleListItem,
    ArticleListResponse,
    ArticleProcessingStateItem,
    ArticleProcessingStatusItem,
    ArticleProcessingStatusResponse,
    ArticleSegmentItem,
    CategoryReferenceItem,
    SourceReferenceItem,
    StructuredOutputItem,
)
from app.schemas.common import ErrorResponse


router = APIRouter(prefix="/articles", tags=["articles"])


@router.get(
    "",
    response_model=ArticleListResponse,
    responses={401: {"model": ErrorResponse}, 503: {"model": ErrorResponse}},
)
def read_articles(
    category: Optional[str] = None,
    source: Optional[str] = None,
    session: Session = Depends(get_db_session),
) -> ArticleListResponse:
    articles = list_articles(session, category_slug=category, source_slug=source)
    items = [
        ArticleListItem(
            id=get_public_article_id(article),
            title=article.title,
            excerpt=article.excerpt,
            source=SourceReferenceItem(
                slug=article.source.slug,
                display_name=article.source.display_name,
            ),
            category=build_category_reference(article.category_slug),
            published_at=serialize_datetime(article.published_at),
            processing_status=article.status.value,
        )
        for article in articles
    ]
    return ArticleListResponse(data=items, meta={"total": len(items)})


@router.get(
    "/{article_id}",
    response_model=ArticleDetailResponse,
    responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}, 503: {"model": ErrorResponse}},
)
def read_article_detail(
    article_id: str,
    session: Session = Depends(get_db_session),
) -> ArticleDetailResponse:
    article = resolve_article(session, article_id)
    return ArticleDetailResponse(data=build_article_detail_item(article))


@router.get(
    "/{article_id}/processing-status",
    response_model=ArticleProcessingStatusResponse,
    responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}, 503: {"model": ErrorResponse}},
)
def read_article_processing_status(
    article_id: str,
    session: Session = Depends(get_db_session),
) -> ArticleProcessingStatusResponse:
    article = resolve_article(session, article_id)
    return ArticleProcessingStatusResponse(
        data=ArticleProcessingStatusItem(
            article_id=get_public_article_id(article),
            status=article.status.value,
            status_reason=article.status_reason,
            quality_notes=article.quality_notes,
            has_structured_output=article.structured_output is not None,
        )
    )


def resolve_article(session: Session, article_id: str) -> Article:
    try:
        return get_article(session, article_id)
    except ArticleLookupError as exc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "article_not_found", "message": "Article was not found."},
        ) from exc


def build_article_detail_item(article: Article) -> ArticleDetailItem:
    return ArticleDetailItem(
        id=get_public_article_id(article),
        title=article.title,
        excerpt=article.excerpt,
        canonical_url=article.canonical_url,
        source=SourceReferenceItem(
            slug=article.source.slug,
            display_name=article.source.display_name,
        ),
        category=build_category_reference(article.category_slug),
        tags=article.tags,
        published_at=serialize_datetime(article.published_at),
        processing=ArticleProcessingStateItem(
            status=article.status.value,
            status_reason=article.status_reason,
            quality_notes=article.quality_notes,
        ),
        segments=[
            ArticleSegmentItem(
                position=segment.position,
                original_text=segment.original_text,
                translated_text=segment.translated_text,
            )
            for segment in article.segments
        ],
        structured_output=build_structured_output(article.structured_output),
    )


def build_category_reference(category_slug: Optional[str]) -> Optional[CategoryReferenceItem]:
    if category_slug is None:
        return None

    return CategoryReferenceItem(
        slug=category_slug,
        display_name=build_category_display_name(category_slug),
    )


def build_structured_output(
    structured_output: Optional[ArticleStructuredOutput],
) -> Optional[StructuredOutputItem]:
    if structured_output is None:
        return None

    return StructuredOutputItem(
        summary=structured_output.summary,
        glossary_entries=structured_output.glossary_entries,
        concept_explanations=structured_output.concept_explanations,
        related_concepts=structured_output.related_concepts,
        quality_notes=structured_output.quality_notes,
    )


def serialize_datetime(value: Optional[datetime]) -> Optional[str]:
    if value is None:
        return None

    if value.tzinfo is None:
        value = value.replace(tzinfo=timezone.utc)

    return value.astimezone(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
