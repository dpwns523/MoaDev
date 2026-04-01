from types import SimpleNamespace

from fastapi.testclient import TestClient

import app.api.v1.endpoints.feeds as feeds_route_module

from app.main import app


client = TestClient(app)


def test_health_returns_data_envelope() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"data": {"status": "ok"}}


def test_feeds_returns_curated_collection() -> None:
    response = client.get("/api/v1/feeds")

    payload = response.json()

    assert response.status_code == 200
    assert payload["meta"]["total"] == 2
    assert [item["id"] for item in payload["data"]] == ["tech-news", "oss-prs"]


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

    response = fail_safe_client.get("/api/v1/feeds")

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

    response = fail_safe_client.get("/api/v1/feeds")

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

    response = fail_safe_client.get("/api/v1/feeds")

    assert response.status_code == 500
    assert response.json() == {
        "error": {
            "code": "feed_validation_error",
            "message": "Failed to build curated feed response.",
        }
    }
