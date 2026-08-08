from fastapi import APIRouter, Depends

from app.api.dependencies.auth import require_authenticated_user
from app.api.v1.endpoints.articles import router as articles_router
from app.api.v1.endpoints.categories import router as categories_router
from app.api.v1.endpoints.feeds import router as feeds_router


router = APIRouter(dependencies=[Depends(require_authenticated_user)])
router.include_router(feeds_router)
router.include_router(categories_router)
router.include_router(articles_router)
