from fastapi import APIRouter

from app.api.v1.endpoints.feeds import router as feeds_router


router = APIRouter()
router.include_router(feeds_router)
