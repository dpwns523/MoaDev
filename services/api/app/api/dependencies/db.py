from typing import Iterator

from fastapi import Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.core.db import get_required_database_url, get_session_factory


def get_db_session(settings: Settings = Depends(get_settings)) -> Iterator[Session]:
    try:
        database_url = get_required_database_url(settings)
    except RuntimeError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "code": "database_not_configured",
                "message": "The article read model is not configured.",
            },
        ) from exc

    session = get_session_factory(database_url)()
    try:
        yield session
    finally:
        session.close()
