from __future__ import annotations

from datetime import datetime, timezone
from enum import Enum
from typing import Any, Optional
from uuid import uuid4

from sqlalchemy import JSON, Boolean, DateTime, Enum as SqlEnum, ForeignKey, Integer, MetaData
from sqlalchemy import String, Text, UniqueConstraint
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship, validates


def generate_uuid() -> str:
    return str(uuid4())


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def build_enum(enum_type: type[Enum], name: str) -> SqlEnum:
    return SqlEnum(
        enum_type,
        name=name,
        values_callable=lambda enum_values: [item.value for item in enum_values],
        validate_strings=True,
    )


class SourceRetentionMode(str, Enum):
    METADATA_ONLY = "metadata_only"
    NORMALIZED_SEGMENTS = "normalized_segments"
    RAW_SNAPSHOT = "raw_snapshot"


class ArticleProcessingStatus(str, Enum):
    PENDING_INTAKE = "pending_intake"
    PENDING_NORMALIZATION = "pending_normalization"
    PENDING_ENRICHMENT = "pending_enrichment"
    PUBLISHED = "published"
    NEEDS_REVIEW = "needs_review"
    FAILED = "failed"


class Base(DeclarativeBase):
    metadata = MetaData(
        naming_convention={
            "ix": "ix_%(column_0_label)s",
            "uq": "uq_%(table_name)s_%(column_0_name)s",
            "ck": "ck_%(table_name)s_%(constraint_name)s",
            "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
            "pk": "pk_%(table_name)s",
        }
    )


class SourceRegistryEntry(Base):
    __tablename__ = "source_registry"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    slug: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    display_name: Mapped[str] = mapped_column(String(255), nullable=False)
    base_url: Mapped[str] = mapped_column(String(2048), nullable=False)
    default_language: Mapped[str] = mapped_column(String(16), nullable=False, default="en")
    content_retention_mode: Mapped[SourceRetentionMode] = mapped_column(
        build_enum(SourceRetentionMode, "source_retention_mode"),
        nullable=False,
        default=SourceRetentionMode.NORMALIZED_SEGMENTS,
    )
    content_retention_days: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    policy_notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=now_utc
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=now_utc,
        onupdate=now_utc,
    )

    articles: Mapped[list["Article"]] = relationship(
        back_populates="source",
        cascade="all, delete-orphan",
    )

    @validates("slug", "display_name", "base_url", "default_language")
    def validate_required_text(self, key: str, value: str) -> str:
        return normalize_required_string(key, value)

    @validates("content_retention_days")
    def validate_content_retention_days(self, key: str, value: Optional[int]) -> Optional[int]:
        if value is None:
            return None

        if value <= 0:
            raise ValueError(f"{key} must be a positive integer when provided.")

        return value


class Article(Base):
    __tablename__ = "articles"
    __table_args__ = (
        UniqueConstraint("source_id", "canonical_url", name="uq_articles_source_id_canonical_url"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    source_id: Mapped[str] = mapped_column(ForeignKey("source_registry.id", ondelete="CASCADE"))
    external_id: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    canonical_url: Mapped[str] = mapped_column(String(2048), nullable=False)
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    excerpt: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    published_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    ingested_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    category_slug: Mapped[Optional[str]] = mapped_column(String(100), nullable=True)
    tags: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    status: Mapped[ArticleProcessingStatus] = mapped_column(
        build_enum(ArticleProcessingStatus, "article_processing_status"),
        nullable=False,
        default=ArticleProcessingStatus.PENDING_INTAKE,
    )
    quality_notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    status_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=now_utc
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=now_utc,
        onupdate=now_utc,
    )

    source: Mapped[SourceRegistryEntry] = relationship(back_populates="articles")
    segments: Mapped[list["ArticleSegment"]] = relationship(
        back_populates="article",
        cascade="all, delete-orphan",
        order_by="ArticleSegment.position",
    )
    structured_output: Mapped[Optional["ArticleStructuredOutput"]] = relationship(
        back_populates="article",
        cascade="all, delete-orphan",
        uselist=False,
    )

    @validates("canonical_url", "title")
    def validate_required_text(self, key: str, value: str) -> str:
        return normalize_required_string(key, value)

    @validates("category_slug")
    def validate_optional_text(self, key: str, value: Optional[str]) -> Optional[str]:
        return normalize_optional_string(key, value)

    @validates("tags")
    def validate_tags(self, key: str, value: list[Any]) -> list[str]:
        if not isinstance(value, list):
            raise ValueError(f"{key} must be a list of strings.")

        normalized_tags: list[str] = []
        for item in value:
            normalized_tags.append(normalize_required_string(key, item))

        return normalized_tags


class ArticleSegment(Base):
    __tablename__ = "article_segments"
    __table_args__ = (
        UniqueConstraint("article_id", "position", name="uq_article_segments_article_id_position"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=generate_uuid)
    article_id: Mapped[str] = mapped_column(
        ForeignKey("articles.id", ondelete="CASCADE"), nullable=False
    )
    position: Mapped[int] = mapped_column(Integer, nullable=False)
    original_text: Mapped[str] = mapped_column(Text, nullable=False)
    translated_text: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=now_utc
    )

    article: Mapped[Article] = relationship(back_populates="segments")

    @validates("position")
    def validate_position(self, key: str, value: int) -> int:
        if value < 0:
            raise ValueError(f"{key} must be zero or greater.")

        return value

    @validates("original_text")
    def validate_required_text(self, key: str, value: str) -> str:
        return normalize_required_string(key, value)

    @validates("translated_text")
    def validate_optional_text(self, key: str, value: Optional[str]) -> Optional[str]:
        return normalize_optional_string(key, value)


class ArticleStructuredOutput(Base):
    __tablename__ = "article_structured_outputs"

    article_id: Mapped[str] = mapped_column(
        ForeignKey("articles.id", ondelete="CASCADE"),
        primary_key=True,
    )
    summary: Mapped[str] = mapped_column(Text, nullable=False)
    glossary_entries: Mapped[list[dict[str, str]]] = mapped_column(
        JSON, nullable=False, default=list
    )
    concept_explanations: Mapped[list[dict[str, str]]] = mapped_column(
        JSON, nullable=False, default=list
    )
    related_concepts: Mapped[list[dict[str, str]]] = mapped_column(
        JSON, nullable=False, default=list
    )
    quality_notes: Mapped[list[str]] = mapped_column(JSON, nullable=False, default=list)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=now_utc
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=now_utc,
        onupdate=now_utc,
    )

    article: Mapped[Article] = relationship(back_populates="structured_output")

    @validates("summary")
    def validate_summary(self, key: str, value: str) -> str:
        return normalize_required_string(key, value)

    @validates("glossary_entries", "concept_explanations", "related_concepts")
    def validate_object_lists(self, key: str, value: list[Any]) -> list[dict[str, str]]:
        if not isinstance(value, list):
            raise ValueError(f"{key} must be a list.")

        normalized_items: list[dict[str, str]] = []
        for item in value:
            if not isinstance(item, dict):
                raise ValueError(f"{key} must contain only object entries.")
            normalized_items.append(
                {str(dict_key): str(dict_value) for dict_key, dict_value in item.items()}
            )

        return normalized_items

    @validates("quality_notes")
    def validate_quality_notes(self, key: str, value: list[Any]) -> list[str]:
        if not isinstance(value, list):
            raise ValueError(f"{key} must be a list of strings.")

        normalized_notes: list[str] = []
        for item in value:
            normalized_notes.append(normalize_required_string(key, item))

        return normalized_notes


def normalize_required_string(key: str, value: Any) -> str:
    if not isinstance(value, str):
        raise ValueError(f"{key} must be a string.")

    normalized_value = value.strip()
    if not normalized_value:
        raise ValueError(f"{key} must not be blank.")

    return normalized_value


def normalize_optional_string(key: str, value: Any) -> Optional[str]:
    if value is None:
        return None

    return normalize_required_string(key, value)
