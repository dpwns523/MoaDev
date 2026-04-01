from fastapi import APIRouter


router = APIRouter(tags=["health"])


@router.get("/health")
def read_health() -> dict[str, dict[str, str]]:
    return {"data": {"status": "ok"}}
