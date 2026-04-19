import time
from typing import Any, Dict, Optional

from app.core.security import create_internal_auth_token


TEST_INTERNAL_AUTH_SECRET = "test-internal-auth-secret"


def build_auth_token(
    *,
    secret: str = TEST_INTERNAL_AUTH_SECRET,
    user_id: str = "user-123",
    email: str = "dev@moadev.test",
    name: str = "Moa Developer",
    provider: str = "google",
    issued_at: Optional[int] = None,
) -> str:
    return create_internal_auth_token(
        {
            "sub": user_id,
            "email": email,
            "name": name,
            "provider": provider,
            "iat": issued_at or int(time.time()),
        },
        secret,
    )


def build_auth_headers(**kwargs: Any) -> Dict[str, str]:
    return {
        "Authorization": f"Bearer {build_auth_token(**kwargs)}",
    }
