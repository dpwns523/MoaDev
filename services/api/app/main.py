from typing import Literal, Union

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, ValidationError

from app.services.feed_catalog import list_curated_feeds


class FeedItem(BaseModel):
    id: str = Field(min_length=1)
    kind: Literal["news", "pull-request"]
    title: str = Field(min_length=1)
    source: str = Field(min_length=1)


class FeedResponse(BaseModel):
    data: list[FeedItem]
    meta: dict[str, int]


class ErrorDetail(BaseModel):
    code: str
    message: str


class ErrorResponse(BaseModel):
    error: ErrorDetail


app = FastAPI(title="MoaDev API")


@app.get("/health")
def read_health() -> dict[str, dict[str, str]]:
    return {"data": {"status": "ok"}}


def build_feed_response() -> FeedResponse:
    feeds = [FeedItem.model_validate(feed.__dict__) for feed in list_curated_feeds()]
    return FeedResponse(data=feeds, meta={"total": len(feeds)})


@app.get("/api/v1/feeds", response_model=FeedResponse, responses={500: {"model": ErrorResponse}})
def read_feeds() -> Union[FeedResponse, JSONResponse]:
    try:
        return build_feed_response()
    except (ValidationError, ValueError):
        return JSONResponse(
            status_code=500,
            content={
                "error": {
                    "code": "feed_validation_error",
                    "message": "Failed to build curated feed response.",
                }
            },
        )
