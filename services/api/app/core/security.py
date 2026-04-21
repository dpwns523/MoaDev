import base64
import hashlib
import hmac
import json
import time
from dataclasses import dataclass
from typing import Any, Dict, Optional


class InvalidAuthTokenError(Exception):
    pass


class ExpiredAuthTokenError(InvalidAuthTokenError):
    pass


@dataclass(frozen=True)
class AuthTokenClaims:
    user_id: str
    email: Optional[str]
    name: Optional[str]
    provider: Optional[str]
    issued_at: int


def create_internal_auth_token(payload: Dict[str, Any], secret: str) -> str:
    encoded_payload = encode_base64url(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    signature = build_token_signature(encoded_payload, secret)
    return f"{encoded_payload}.{signature}"


def verify_internal_auth_token(token: str, secret: str, max_age_seconds: int) -> AuthTokenClaims:
    encoded_payload, signature = split_token(token)
    expected_signature = build_token_signature(encoded_payload, secret)
    if not hmac.compare_digest(expected_signature, signature):
        raise InvalidAuthTokenError()

    payload = decode_token_payload(encoded_payload)
    issued_at = payload.get("iat")
    if not isinstance(issued_at, int):
        raise InvalidAuthTokenError()

    if int(time.time()) - issued_at > max_age_seconds:
        raise ExpiredAuthTokenError()

    user_id = payload.get("sub")
    if not isinstance(user_id, str) or not user_id.strip():
        raise InvalidAuthTokenError()

    return AuthTokenClaims(
        user_id=user_id,
        email=read_optional_string(payload, "email"),
        name=read_optional_string(payload, "name"),
        provider=read_optional_string(payload, "provider"),
        issued_at=issued_at,
    )


def build_token_signature(encoded_payload: str, secret: str) -> str:
    digest = hmac.new(secret.encode("utf-8"), encoded_payload.encode("utf-8"), hashlib.sha256).digest()
    return encode_base64url(digest)


def split_token(token: str) -> tuple[str, str]:
    parts = token.split(".")
    if len(parts) != 2 or not parts[0] or not parts[1]:
        raise InvalidAuthTokenError()

    return parts[0], parts[1]


def decode_token_payload(encoded_payload: str) -> Dict[str, Any]:
    try:
        payload = json.loads(decode_base64url(encoded_payload).decode("utf-8"))
    except (ValueError, json.JSONDecodeError):
        raise InvalidAuthTokenError()

    if not isinstance(payload, dict):
        raise InvalidAuthTokenError()

    return payload


def read_optional_string(payload: Dict[str, Any], key: str) -> Optional[str]:
    value = payload.get(key)
    if not isinstance(value, str):
        return None

    normalized_value = value.strip()
    return normalized_value or None


def decode_base64url(value: str) -> bytes:
    return base64.urlsafe_b64decode(add_base64_padding(value))


def encode_base64url(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).decode("utf-8").rstrip("=")


def add_base64_padding(value: str) -> str:
    padding_length = (-len(value)) % 4
    return f"{value}{'=' * padding_length}"
