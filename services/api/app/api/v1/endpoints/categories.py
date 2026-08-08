from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api.dependencies.db import get_db_session
from app.domain.articles.service import list_category_summaries
from app.schemas.article import CategoryListItem, CategoryListResponse
from app.schemas.common import ErrorResponse


router = APIRouter(prefix="/categories", tags=["categories"])


@router.get(
    "",
    response_model=CategoryListResponse,
    responses={401: {"model": ErrorResponse}, 503: {"model": ErrorResponse}},
)
def read_categories(session: Session = Depends(get_db_session)) -> CategoryListResponse:
    categories = list_category_summaries(session)
    items = [
        CategoryListItem(
            slug=category.slug,
            display_name=category.display_name,
            article_count=category.article_count,
        )
        for category in categories
    ]
    return CategoryListResponse(data=items, meta={"total": len(items)})
