from datetime import datetime, timezone
from pathlib import Path

from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.db import get_engine
from app.domain.articles.models import (
    Article,
    ArticleProcessingStatus,
    ArticleSegment,
    ArticleStructuredOutput,
    Base,
    SourceRegistryEntry,
    SourceRetentionMode,
)
from app.main import app
from tests.auth_token_helpers import TEST_INTERNAL_AUTH_SECRET, build_auth_headers


client = TestClient(app)


def test_categories_require_authenticated_request() -> None:
    response = client.get("/api/v1/categories")

    assert response.status_code == 401
    assert response.json() == {
        "error": {
            "code": "auth_required",
            "message": "Authenticated bearer token is required.",
        }
    }


def test_categories_return_article_counts_for_authenticated_request(
    monkeypatch, tmp_path: Path
) -> None:
    configure_article_api(monkeypatch, tmp_path)

    response = client.get("/api/v1/categories", headers=build_auth_headers())

    assert response.status_code == 200
    assert response.json() == {
        "data": [
            {
                "slug": "ai-and-machine-learning",
                "display_name": "AI And Machine Learning",
                "article_count": 1,
            },
            {
                "slug": "oss-operations",
                "display_name": "OSS Operations",
                "article_count": 1,
            },
        ],
        "meta": {"total": 2},
    }


def test_articles_require_authenticated_request() -> None:
    response = client.get("/api/v1/articles")

    assert response.status_code == 401
    assert response.json() == {
        "error": {
            "code": "auth_required",
            "message": "Authenticated bearer token is required.",
        }
    }


def test_articles_return_source_and_category_browsing_fields(monkeypatch, tmp_path: Path) -> None:
    configure_article_api(monkeypatch, tmp_path)

    response = client.get("/api/v1/articles", headers=build_auth_headers())

    assert response.status_code == 200
    assert response.json() == {
        "data": [
            {
                "id": "state-of-ai-tooling",
                "title": "The State of AI Tooling",
                "excerpt": "A quick look at how teams are shipping AI-powered developer tools.",
                "source": {
                    "slug": "keek-news",
                    "display_name": "Keek News",
                },
                "category": {
                    "slug": "ai-and-machine-learning",
                    "display_name": "AI And Machine Learning",
                },
                "published_at": "2026-04-20T08:00:00Z",
                "processing_status": "published",
            },
            {
                "id": "ops-backpressure-watch",
                "title": "GitHub Actions Queue Backpressure Watch",
                "excerpt": "Maintainers are reporting queue pressure and delayed worker assignment.",
                "source": {
                    "slug": "github-activity",
                    "display_name": "GitHub Activity",
                },
                "category": {
                    "slug": "oss-operations",
                    "display_name": "OSS Operations",
                },
                "published_at": None,
                "processing_status": "pending_enrichment",
            },
        ],
        "meta": {"total": 2},
    }


def test_articles_support_source_and_category_filters(monkeypatch, tmp_path: Path) -> None:
    configure_article_api(monkeypatch, tmp_path)

    response = client.get(
        "/api/v1/articles?category=oss-operations&source=github-activity",
        headers=build_auth_headers(),
    )

    assert response.status_code == 200
    assert response.json() == {
        "data": [
            {
                "id": "ops-backpressure-watch",
                "title": "GitHub Actions Queue Backpressure Watch",
                "excerpt": "Maintainers are reporting queue pressure and delayed worker assignment.",
                "source": {
                    "slug": "github-activity",
                    "display_name": "GitHub Activity",
                },
                "category": {
                    "slug": "oss-operations",
                    "display_name": "OSS Operations",
                },
                "published_at": None,
                "processing_status": "pending_enrichment",
            }
        ],
        "meta": {"total": 1},
    }


def test_article_detail_returns_structured_output_contract(monkeypatch, tmp_path: Path) -> None:
    configure_article_api(monkeypatch, tmp_path)

    response = client.get("/api/v1/articles/state-of-ai-tooling", headers=build_auth_headers())

    assert response.status_code == 200
    assert response.json() == {
        "data": {
            "id": "state-of-ai-tooling",
            "title": "The State of AI Tooling",
            "excerpt": "A quick look at how teams are shipping AI-powered developer tools.",
            "canonical_url": "https://keek.com/news/state-of-ai-tooling",
            "source": {
                "slug": "keek-news",
                "display_name": "Keek News",
            },
            "category": {
                "slug": "ai-and-machine-learning",
                "display_name": "AI And Machine Learning",
            },
            "tags": ["agents", "tooling"],
            "published_at": "2026-04-20T08:00:00Z",
            "processing": {
                "status": "published",
                "status_reason": None,
                "quality_notes": "Translation confidence is high, but one quote should be reviewed.",
            },
            "segments": [
                {
                    "position": 0,
                    "original_text": "Teams now expect AI coding tools to understand repository context.",
                    "translated_text": "Teams are increasingly asking AI coding tools to understand the full repository context.",
                },
                {
                    "position": 1,
                    "original_text": "Retrieval quality matters more than model size for this workflow.",
                    "translated_text": "For this workflow, retrieval quality matters more than raw model size.",
                },
            ],
            "structured_output": {
                "summary": "Repository-aware assistants are becoming the baseline for AI development tooling.",
                "glossary_entries": [
                    {
                        "term": "repository context",
                        "explanation_ko": "코드 저장소 전체 구조와 관계를 이해하는 문맥입니다.",
                    }
                ],
                "concept_explanations": [
                    {
                        "concept": "retrieval quality",
                        "explanation_ko": "필요한 정보를 정확히 찾아 모델 입력에 포함시키는 품질입니다.",
                    }
                ],
                "related_concepts": [
                    {
                        "concept": "RAG",
                        "reason_ko": "저장소 문맥 검색 품질을 이해하는 데 직접 연결됩니다.",
                    }
                ],
                "quality_notes": [
                    "The generated glossary is complete enough for MVP publishing."
                ],
            },
        }
    }


def test_article_detail_surfaces_incomplete_processing_state(monkeypatch, tmp_path: Path) -> None:
    configure_article_api(monkeypatch, tmp_path)

    response = client.get("/api/v1/articles/ops-backpressure-watch", headers=build_auth_headers())

    assert response.status_code == 200
    assert response.json() == {
        "data": {
            "id": "ops-backpressure-watch",
            "title": "GitHub Actions Queue Backpressure Watch",
            "excerpt": "Maintainers are reporting queue pressure and delayed worker assignment.",
            "canonical_url": "https://github.com/example/actions/issues/88",
            "source": {
                "slug": "github-activity",
                "display_name": "GitHub Activity",
            },
            "category": {
                "slug": "oss-operations",
                "display_name": "OSS Operations",
            },
            "tags": ["queues", "ci"],
            "published_at": None,
            "processing": {
                "status": "pending_enrichment",
                "status_reason": "Waiting for summary generation retry.",
                "quality_notes": "Partial source metadata is visible before enrichment completes.",
            },
            "segments": [
                {
                    "position": 0,
                    "original_text": "Maintainers are reporting queue pressure and delayed worker assignment.",
                    "translated_text": None,
                }
            ],
            "structured_output": None,
        }
    }


def test_article_processing_status_endpoint_returns_explicit_state(monkeypatch, tmp_path: Path) -> None:
    configure_article_api(monkeypatch, tmp_path)

    response = client.get(
        "/api/v1/articles/ops-backpressure-watch/processing-status",
        headers=build_auth_headers(),
    )

    assert response.status_code == 200
    assert response.json() == {
        "data": {
            "article_id": "ops-backpressure-watch",
            "status": "pending_enrichment",
            "status_reason": "Waiting for summary generation retry.",
            "quality_notes": "Partial source metadata is visible before enrichment completes.",
            "has_structured_output": False,
        }
    }


def test_article_detail_returns_not_found_for_unknown_article(monkeypatch, tmp_path: Path) -> None:
    configure_article_api(monkeypatch, tmp_path)

    response = client.get("/api/v1/articles/unknown-article", headers=build_auth_headers())

    assert response.status_code == 404
    assert response.json() == {
        "error": {
            "code": "article_not_found",
            "message": "Article was not found.",
        }
    }


def configure_article_api(monkeypatch, tmp_path: Path) -> None:
    database_url = f"sqlite+pysqlite:///{tmp_path / 'articles-api.sqlite3'}"
    monkeypatch.setenv("DATABASE_URL", database_url)
    monkeypatch.setenv("MOADEV_INTERNAL_AUTH_SECRET", TEST_INTERNAL_AUTH_SECRET)

    engine = get_engine(database_url)
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)

    session = Session(engine)
    try:
        seed_article_records(session)
        session.commit()
    finally:
        session.close()


def seed_article_records(session: Session) -> None:
    article_source = SourceRegistryEntry(
        slug="keek-news",
        display_name="Keek News",
        base_url="https://keek.com/news",
        content_retention_mode=SourceRetentionMode.NORMALIZED_SEGMENTS,
        content_retention_days=30,
        policy_notes="Keep normalized segments only for the MVP.",
    )
    article = Article(
        source=article_source,
        external_id="state-of-ai-tooling",
        canonical_url="https://keek.com/news/state-of-ai-tooling",
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
            "The generated glossary is complete enough for MVP publishing."
        ],
    )

    watch_source = SourceRegistryEntry(
        slug="github-activity",
        display_name="GitHub Activity",
        base_url="https://github.com",
        content_retention_mode=SourceRetentionMode.METADATA_ONLY,
        content_retention_days=7,
        policy_notes="Track issue and PR metadata for MVP watchlists.",
    )
    watch_article = Article(
        source=watch_source,
        external_id="ops-backpressure-watch",
        canonical_url="https://github.com/example/actions/issues/88",
        title="GitHub Actions Queue Backpressure Watch",
        excerpt="Maintainers are reporting queue pressure and delayed worker assignment.",
        ingested_at=datetime(2026, 4, 20, 9, 0, tzinfo=timezone.utc),
        category_slug="oss-operations",
        tags=["queues", "ci"],
        status=ArticleProcessingStatus.PENDING_ENRICHMENT,
        status_reason="Waiting for summary generation retry.",
        quality_notes="Partial source metadata is visible before enrichment completes.",
    )
    watch_article.segments.append(
        ArticleSegment(
            position=0,
            original_text="Maintainers are reporting queue pressure and delayed worker assignment.",
            translated_text=None,
        )
    )

    session.add_all([article, watch_article])
