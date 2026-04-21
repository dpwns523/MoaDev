from functools import lru_cache
from typing import Dict

from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import Settings


def get_required_database_url(settings: Settings) -> str:
    if not settings.database_url:
        raise RuntimeError("DATABASE_URL is required for the article persistence baseline.")

    return settings.database_url


@lru_cache(maxsize=None)
def get_engine(database_url: str) -> Engine:
    return create_engine(
        database_url,
        future=True,
        pool_pre_ping=not database_url.startswith("sqlite"),
        connect_args=build_connect_args(database_url),
    )


def get_session_factory(database_url: str) -> sessionmaker[Session]:
    return sessionmaker(bind=get_engine(database_url), autoflush=False, expire_on_commit=False)


def build_connect_args(database_url: str) -> Dict[str, object]:
    if database_url.startswith("sqlite"):
        return {"check_same_thread": False}

    return {}
