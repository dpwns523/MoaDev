from types import SimpleNamespace

from fastapi.testclient import TestClient

import app.api.v1.endpoints.feeds as feeds_route_module

from app.main import app
from tests.auth_token_helpers import TEST_INTERNAL_AUTH_SECRET, build_auth_headers


client = TestClient(app)


def make_auth_headers(monkeypatch, **overrides):
    monkeypatch.setenv("MOADEV_INTERNAL_AUTH_SECRET", TEST_INTERNAL_AUTH_SECRET)
    return build_auth_headers(**overrides)


def test_health_returns_data_envelope() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"data": {"status": "ok"}}


def test_feeds_requires_authenticated_user_context() -> None:
    response = client.get("/api/v1/feeds")

    assert response.status_code == 401
    assert response.json() == {
        "error": {
            "code": "auth_required",
            "message": "Authenticated bearer token is required.",
        }
    }


def test_feeds_returns_curated_collection(monkeypatch) -> None:
    response = client.get("/api/v1/feeds", headers=make_auth_headers(monkeypatch))

    payload = response.json()

    assert response.status_code == 200
    assert payload["meta"]["total"] == 2
    assert [item["id"] for item in payload["data"]] == ["tech-news", "oss-prs"]


def test_feeds_rejects_invalid_token(monkeypatch) -> None:
    monkeypatch.setenv("MOADEV_INTERNAL_AUTH_SECRET", TEST_INTERNAL_AUTH_SECRET)

    response = client.get("/api/v1/feeds", headers={"Authorization": "Bearer invalid-token"})

    assert response.status_code == 401
    assert response.json() == {
        "error": {
            "code": "invalid_token",
            "message": "Authenticated token could not be verified.",
        }
    }


def test_feeds_rejects_expired_token(monkeypatch) -> None:
    response = client.get("/api/v1/feeds", headers=make_auth_headers(monkeypatch, issued_at=1))

    assert response.status_code == 401
    assert response.json() == {
        "error": {
            "code": "token_expired",
            "message": "Authenticated token expired.",
        }
    }


def test_feeds_returns_error_envelope_for_invalid_feed_boundary(monkeypatch) -> None:
    fail_safe_client = TestClient(app, raise_server_exceptions=False)

    monkeypatch.setattr(
        feeds_route_module,
        "list_curated_feeds",
        lambda: [
            SimpleNamespace(
                id="tech-news",
                kind="news",
                title="Technology news highlights",
                source=None,
            )
        ],
    )

    response = fail_safe_client.get("/api/v1/feeds", headers=make_auth_headers(monkeypatch))

    assert response.status_code == 500
    assert response.json() == {
        "error": {
            "code": "feed_validation_error",
            "message": "Failed to build curated feed response.",
        }
    }


def test_feeds_returns_error_envelope_for_invalid_mapping_feed_boundary(monkeypatch) -> None:
    fail_safe_client = TestClient(app, raise_server_exceptions=False)

    monkeypatch.setattr(
        feeds_route_module,
        "list_curated_feeds",
        lambda: [
            {
                "id": "tech-news",
                "kind": "news",
                "title": "Technology news highlights",
                "source": None,
            }
        ],
    )

    response = fail_safe_client.get("/api/v1/feeds", headers=make_auth_headers(monkeypatch))

    assert response.status_code == 500
    assert response.json() == {
        "error": {
            "code": "feed_validation_error",
            "message": "Failed to build curated feed response.",
        }
    }


def test_feeds_rejects_whitespace_only_feed_fields(monkeypatch) -> None:
    fail_safe_client = TestClient(app, raise_server_exceptions=False)

    monkeypatch.setattr(
        feeds_route_module,
        "list_curated_feeds",
        lambda: [
            SimpleNamespace(
                id="tech-news",
                kind="news",
                title="   ",
                source="global-tech-signal",
            )
        ],
    )

    response = fail_safe_client.get("/api/v1/feeds", headers=make_auth_headers(monkeypatch))

    assert response.status_code == 500
    assert response.json() == {
        "error": {
            "code": "feed_validation_error",
            "message": "Failed to build curated feed response.",
        }
    }
