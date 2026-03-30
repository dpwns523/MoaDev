from dataclasses import dataclass


ALLOWED_FEED_KINDS = {"news", "pull-request"}


@dataclass(frozen=True)
class FeedDescriptor:
    id: str
    kind: str
    title: str
    source: str

    def __post_init__(self) -> None:
        _validate_feed_field("id", self.id)
        _validate_feed_field("title", self.title)
        _validate_feed_field("source", self.source)

        if self.kind not in ALLOWED_FEED_KINDS:
            raise ValueError("kind must be one of the curated feed kinds")


def _validate_feed_field(field_name: str, value: str) -> None:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{field_name} must be a non-empty string")


def list_curated_feeds() -> list[FeedDescriptor]:
    return [
        FeedDescriptor(
            id="tech-news",
            kind="news",
            title="Technology news highlights",
            source="global-tech-signal",
        ),
        FeedDescriptor(
            id="oss-prs",
            kind="pull-request",
            title="Open-source pull request watchlist",
            source="github-activity",
        ),
    ]
