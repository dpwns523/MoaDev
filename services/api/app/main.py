from fastapi import FastAPI
from pydantic import BaseModel

from app.services.feed_catalog import list_curated_feeds


class FeedItem(BaseModel):
    id: str
    kind: str
    title: str
    source: str


class FeedResponse(BaseModel):
    data: list[FeedItem]
    meta: dict[str, int]


app = FastAPI(title="MoaDev API")


@app.get("/health")
def read_health() -> dict[str, dict[str, str]]:
    return {"data": {"status": "ok"}}


@app.get("/api/v1/feeds", response_model=FeedResponse)
def read_feeds() -> FeedResponse:
    feeds = [FeedItem.model_validate(feed.__dict__) for feed in list_curated_feeds()]
    return FeedResponse(data=feeds, meta={"total": len(feeds)})
