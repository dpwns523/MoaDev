from dataclasses import dataclass


@dataclass(frozen=True)
class FeedDescriptor:
    id: str
    kind: str
    title: str
    source: str


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
