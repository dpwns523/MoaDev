import pytest

from app.services.feed_catalog import FeedDescriptor


def test_feed_descriptor_rejects_blank_title() -> None:
    with pytest.raises(ValueError, match="title"):
        FeedDescriptor(
            id="tech-news",
            kind="news",
            title="",
            source="global-tech-signal",
        )


def test_feed_descriptor_rejects_unsupported_kind() -> None:
    with pytest.raises(ValueError, match="kind"):
        FeedDescriptor(
            id="tech-news",
            kind="blog",
            title="Technology news highlights",
            source="global-tech-signal",
        )
