from dataclasses import dataclass
from typing import Optional

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.config import Settings, get_settings
from app.core.security import (
    ExpiredAuthTokenError,
    InvalidAuthTokenError,
    verify_internal_auth_token,
)


bearer_scheme = HTTPBearer(auto_error=False)


@dataclass(frozen=True)
class AuthenticatedUser:
    user_id: str
    email: Optional[str]
    name: Optional[str]
    provider: Optional[str]


def require_authenticated_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
    settings: Settings = Depends(get_settings),
) -> AuthenticatedUser:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise build_http_error(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="auth_required",
            message="Authenticated bearer token is required.",
        )

    if not settings.internal_auth_secret:
        raise build_http_error(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            code="auth_not_configured",
            message="The authenticated session boundary is not configured.",
        )

    try:
        claims = verify_internal_auth_token(
            token=credentials.credentials,
            secret=settings.internal_auth_secret,
            max_age_seconds=settings.internal_auth_max_age_seconds,
        )
    except ExpiredAuthTokenError:
        raise build_http_error(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="token_expired",
            message="Authenticated token expired.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except InvalidAuthTokenError:
        raise build_http_error(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="invalid_token",
            message="Authenticated token could not be verified.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return AuthenticatedUser(
        user_id=claims.user_id,
        email=claims.email,
        name=claims.name,
        provider=claims.provider,
    )


def build_http_error(
    *,
    status_code: int,
    code: str,
    message: str,
    headers: Optional[dict[str, str]] = None,
) -> HTTPException:
    return HTTPException(status_code=status_code, detail={"code": code, "message": message}, headers=headers)
