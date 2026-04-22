from typing import Optional

from pydantic import BaseModel, Field


class CategoryReferenceItem(BaseModel):
    slug: str = Field(min_length=1)
    display_name: str = Field(min_length=1)


class CategoryListItem(CategoryReferenceItem):
    article_count: int = Field(ge=0)


class CategoryListResponse(BaseModel):
    data: list[CategoryListItem]
    meta: dict[str, int]


class SourceReferenceItem(BaseModel):
    slug: str = Field(min_length=1)
    display_name: str = Field(min_length=1)


class ArticleListItem(BaseModel):
    id: str = Field(min_length=1)
    title: str = Field(min_length=1)
    excerpt: Optional[str] = None
    source: SourceReferenceItem
    category: Optional[CategoryReferenceItem] = None
    published_at: Optional[str] = None
    processing_status: str = Field(min_length=1)


class ArticleListResponse(BaseModel):
    data: list[ArticleListItem]
    meta: dict[str, int]


class ArticleProcessingStateItem(BaseModel):
    status: str = Field(min_length=1)
    status_reason: Optional[str] = None
    quality_notes: Optional[str] = None


class ArticleSegmentItem(BaseModel):
    position: int = Field(ge=0)
    original_text: str = Field(min_length=1)
    translated_text: Optional[str] = None


class StructuredOutputItem(BaseModel):
    summary: str = Field(min_length=1)
    glossary_entries: list[dict[str, str]]
    concept_explanations: list[dict[str, str]]
    related_concepts: list[dict[str, str]]
    quality_notes: list[str]


class ArticleDetailItem(BaseModel):
    id: str = Field(min_length=1)
    title: str = Field(min_length=1)
    excerpt: Optional[str] = None
    canonical_url: str = Field(min_length=1)
    source: SourceReferenceItem
    category: Optional[CategoryReferenceItem] = None
    tags: list[str]
    published_at: Optional[str] = None
    processing: ArticleProcessingStateItem
    segments: list[ArticleSegmentItem]
    structured_output: Optional[StructuredOutputItem] = None


class ArticleDetailResponse(BaseModel):
    data: ArticleDetailItem


class ArticleProcessingStatusItem(BaseModel):
    article_id: str = Field(min_length=1)
    status: str = Field(min_length=1)
    status_reason: Optional[str] = None
    quality_notes: Optional[str] = None
    has_structured_output: bool


class ArticleProcessingStatusResponse(BaseModel):
    data: ArticleProcessingStatusItem
