"""create article persistence baseline"""

from alembic import op
import sqlalchemy as sa


revision = "20260421_0001"
down_revision = None
branch_labels = None
depends_on = None


source_retention_mode = sa.Enum(
    "metadata_only",
    "normalized_segments",
    "raw_snapshot",
    name="source_retention_mode",
)
article_processing_status = sa.Enum(
    "pending_intake",
    "pending_normalization",
    "pending_enrichment",
    "published",
    "needs_review",
    "failed",
    name="article_processing_status",
)


def upgrade() -> None:
    bind = op.get_bind()
    source_retention_mode.create(bind, checkfirst=True)
    article_processing_status.create(bind, checkfirst=True)

    op.create_table(
        "source_registry",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("slug", sa.String(length=100), nullable=False),
        sa.Column("display_name", sa.String(length=255), nullable=False),
        sa.Column("base_url", sa.String(length=2048), nullable=False),
        sa.Column("default_language", sa.String(length=16), nullable=False),
        sa.Column("content_retention_mode", source_retention_mode, nullable=False),
        sa.Column("content_retention_days", sa.Integer(), nullable=True),
        sa.Column("policy_notes", sa.Text(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id", name="pk_source_registry"),
        sa.UniqueConstraint("slug", name="uq_source_registry_slug"),
    )

    op.create_table(
        "articles",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("source_id", sa.String(length=36), nullable=False),
        sa.Column("external_id", sa.String(length=255), nullable=True),
        sa.Column("canonical_url", sa.String(length=2048), nullable=False),
        sa.Column("title", sa.String(length=500), nullable=False),
        sa.Column("excerpt", sa.Text(), nullable=True),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ingested_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("category_slug", sa.String(length=100), nullable=True),
        sa.Column("tags", sa.JSON(), nullable=False),
        sa.Column("status", article_processing_status, nullable=False),
        sa.Column("quality_notes", sa.Text(), nullable=True),
        sa.Column("status_reason", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["source_id"],
            ["source_registry.id"],
            name="fk_articles_source_id_source_registry",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_articles"),
        sa.UniqueConstraint(
            "source_id", "canonical_url", name="uq_articles_source_id_canonical_url"
        ),
    )
    op.create_index("ix_articles_category_slug", "articles", ["category_slug"], unique=False)
    op.create_index("ix_articles_published_at", "articles", ["published_at"], unique=False)
    op.create_index("ix_articles_status", "articles", ["status"], unique=False)

    op.create_table(
        "article_segments",
        sa.Column("id", sa.String(length=36), nullable=False),
        sa.Column("article_id", sa.String(length=36), nullable=False),
        sa.Column("position", sa.Integer(), nullable=False),
        sa.Column("original_text", sa.Text(), nullable=False),
        sa.Column("translated_text", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["article_id"],
            ["articles.id"],
            name="fk_article_segments_article_id_articles",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id", name="pk_article_segments"),
        sa.UniqueConstraint(
            "article_id",
            "position",
            name="uq_article_segments_article_id_position",
        ),
    )

    op.create_table(
        "article_structured_outputs",
        sa.Column("article_id", sa.String(length=36), nullable=False),
        sa.Column("summary", sa.Text(), nullable=False),
        sa.Column("glossary_entries", sa.JSON(), nullable=False),
        sa.Column("concept_explanations", sa.JSON(), nullable=False),
        sa.Column("related_concepts", sa.JSON(), nullable=False),
        sa.Column("quality_notes", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["article_id"],
            ["articles.id"],
            name="fk_article_structured_outputs_article_id_articles",
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("article_id", name="pk_article_structured_outputs"),
    )


def downgrade() -> None:
    op.drop_table("article_structured_outputs")
    op.drop_table("article_segments")
    op.drop_index("ix_articles_status", table_name="articles")
    op.drop_index("ix_articles_published_at", table_name="articles")
    op.drop_index("ix_articles_category_slug", table_name="articles")
    op.drop_table("articles")
    op.drop_table("source_registry")

    bind = op.get_bind()
    article_processing_status.drop(bind, checkfirst=True)
    source_retention_mode.drop(bind, checkfirst=True)
