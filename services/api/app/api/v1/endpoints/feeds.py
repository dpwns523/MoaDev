from typing import Union

from fastapi import APIRouter
from fastapi.responses import JSONResponse
from pydantic import ValidationError

from app.schemas.common import ErrorResponse
from app.schemas.feed import FeedItem, FeedResponse
from app.services.feed_catalog import list_curated_feeds


router = APIRouter(prefix="/feeds", tags=["feeds"])


def build_feed_response() -> FeedResponse:
    feeds = [FeedItem.model_validate(feed, from_attributes=True) for feed in list_curated_feeds()]
    return FeedResponse(data=feeds, meta={"total": len(feeds)})


@router.get("", response_model=FeedResponse, responses={500: {"model": ErrorResponse}})
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
