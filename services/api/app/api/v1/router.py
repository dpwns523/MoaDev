from fastapi import APIRouter, Depends

from app.api.dependencies.auth import require_authenticated_user
from app.api.v1.endpoints.feeds import router as feeds_router


router = APIRouter(dependencies=[Depends(require_authenticated_user)])
router.include_router(feeds_router)
