from datetime import datetime, timezone

import pytest
from sqlalchemy import create_engine
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.domain.articles.models import (
    Article,
    ArticleProcessingStatus,
    ArticleSegment,
    ArticleStructuredOutput,
    Base,
    SourceRegistryEntry,
    SourceRetentionMode,
)


def build_session() -> Session:
    engine = create_engine("sqlite+pysqlite:///:memory:", future=True)
    Base.metadata.create_all(engine)
    return Session(engine)


def test_source_registry_rejects_non_positive_retention_days() -> None:
    with pytest.raises(ValueError, match="retention"):
        SourceRegistryEntry(
            slug="keek-news",
            display_name="Keek News",
            base_url="https://keek.com/news",
            content_retention_mode=SourceRetentionMode.NORMALIZED_SEGMENTS,
            content_retention_days=0,
            policy_notes="Keep normalized segments only.",
        )


def test_article_detail_persistence_roundtrip_supports_first_release_contract() -> None:
    session = build_session()

    source = SourceRegistryEntry(
        slug="keek-news",
        display_name="Keek News",
        base_url="https://keek.com/news",
        content_retention_mode=SourceRetentionMode.NORMALIZED_SEGMENTS,
        content_retention_days=30,
        policy_notes="Keep normalized segments only for the MVP.",
    )
    article = Article(
        source=source,
        canonical_url="https://keek.com/news/state-of-ai-tooling",
        external_id="state-of-ai-tooling",
        title="The State of AI Tooling",
        excerpt="A quick look at how teams are shipping AI-powered developer tools.",
        published_at=datetime(2026, 4, 20, 8, 0, tzinfo=timezone.utc),
        ingested_at=datetime(2026, 4, 20, 8, 5, tzinfo=timezone.utc),
        category_slug="ai-and-machine-learning",
        tags=["agents", "tooling"],
        status=ArticleProcessingStatus.PUBLISHED,
        quality_notes="Translation confidence is high, but one quote should be reviewed.",
    )
    article.segments.extend(
        [
            ArticleSegment(
                position=0,
                original_text="Teams now expect AI coding tools to understand repository context.",
                translated_text="Teams are increasingly asking AI coding tools to understand the full repository context.",
            ),
            ArticleSegment(
                position=1,
                original_text="Retrieval quality matters more than model size for this workflow.",
                translated_text="For this workflow, retrieval quality matters more than raw model size.",
            ),
        ]
    )
    article.structured_output = ArticleStructuredOutput(
        summary="Repository-aware assistants are becoming the baseline for AI development tooling.",
        glossary_entries=[
            {
                "term": "repository context",
                "explanation_ko": "코드 저장소 전체 구조와 관계를 이해하는 문맥입니다.",
            }
        ],
        concept_explanations=[
            {
                "concept": "retrieval quality",
                "explanation_ko": "필요한 정보를 정확히 찾아 모델 입력에 포함시키는 품질입니다.",
            }
        ],
        related_concepts=[
            {
                "concept": "RAG",
                "reason_ko": "저장소 문맥 검색 품질을 이해하는 데 직접 연결됩니다.",
            }
        ],
        quality_notes=[
            "The generated glossary is complete enough for MVP publishing.",
        ],
    )

    session.add(article)
    session.commit()

    stored_article = session.query(Article).filter_by(external_id="state-of-ai-tooling").one()

    assert stored_article.source.slug == "keek-news"
    assert stored_article.status is ArticleProcessingStatus.PUBLISHED
    assert stored_article.category_slug == "ai-and-machine-learning"
    assert stored_article.tags == ["agents", "tooling"]
    assert [segment.original_text for segment in stored_article.segments] == [
        "Teams now expect AI coding tools to understand repository context.",
        "Retrieval quality matters more than model size for this workflow.",
    ]
    assert [segment.translated_text for segment in stored_article.segments] == [
        "Teams are increasingly asking AI coding tools to understand the full repository context.",
        "For this workflow, retrieval quality matters more than raw model size.",
    ]
    assert stored_article.structured_output.summary.startswith("Repository-aware assistants")
    assert stored_article.structured_output.glossary_entries == [
        {
            "term": "repository context",
            "explanation_ko": "코드 저장소 전체 구조와 관계를 이해하는 문맥입니다.",
        }
    ]


def test_article_segments_require_unique_position_per_article() -> None:
    session = build_session()

    article = Article(
        source=SourceRegistryEntry(
            slug="keek-news",
            display_name="Keek News",
            base_url="https://keek.com/news",
            content_retention_mode=SourceRetentionMode.NORMALIZED_SEGMENTS,
            content_retention_days=30,
            policy_notes="Keep normalized segments only for the MVP.",
        ),
        canonical_url="https://keek.com/news/duplicate-segment",
        title="Duplicate Segment",
        ingested_at=datetime(2026, 4, 20, 9, 0, tzinfo=timezone.utc),
        status=ArticleProcessingStatus.PENDING_NORMALIZATION,
    )
    article.segments.extend(
        [
            ArticleSegment(position=0, original_text="First segment."),
            ArticleSegment(position=0, original_text="Duplicate position."),
        ]
    )

    session.add(article)

    with pytest.raises(IntegrityError):
        session.commit()


def test_article_canonical_url_is_unique_within_source_registry() -> None:
    session = build_session()

    source = SourceRegistryEntry(
        slug="keek-news",
        display_name="Keek News",
        base_url="https://keek.com/news",
        content_retention_mode=SourceRetentionMode.NORMALIZED_SEGMENTS,
        content_retention_days=30,
        policy_notes="Keep normalized segments only for the MVP.",
    )
    session.add_all(
        [
            Article(
                source=source,
                canonical_url="https://keek.com/news/same-url",
                title="First record",
                ingested_at=datetime(2026, 4, 20, 9, 0, tzinfo=timezone.utc),
                status=ArticleProcessingStatus.PENDING_INTAKE,
            ),
            Article(
                source=source,
                canonical_url="https://keek.com/news/same-url",
                title="Second record",
                ingested_at=datetime(2026, 4, 20, 9, 5, tzinfo=timezone.utc),
                status=ArticleProcessingStatus.PENDING_INTAKE,
            ),
        ]
    )

    with pytest.raises(IntegrityError):
        session.commit()
