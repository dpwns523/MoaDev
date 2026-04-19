import os
from dataclasses import dataclass
from typing import Optional


DEFAULT_INTERNAL_AUTH_MAX_AGE_SECONDS = 300


@dataclass(frozen=True)
class Settings:
    internal_auth_secret: Optional[str]
    internal_auth_max_age_seconds: int


def get_settings() -> Settings:
    return Settings(
        internal_auth_secret=read_optional_env("MOADEV_INTERNAL_AUTH_SECRET"),
        internal_auth_max_age_seconds=read_positive_int_env(
            "MOADEV_INTERNAL_AUTH_MAX_AGE_SECONDS",
            DEFAULT_INTERNAL_AUTH_MAX_AGE_SECONDS,
        ),
    )


def read_optional_env(name: str) -> Optional[str]:
    value = os.getenv(name)
    if value is None:
        return None

    normalized_value = value.strip()
    return normalized_value or None


def read_positive_int_env(name: str, default: int) -> int:
    raw_value = os.getenv(name)
    if raw_value is None:
        return default

    try:
        parsed_value = int(raw_value)
    except ValueError:
        return default

    return parsed_value if parsed_value > 0 else default
