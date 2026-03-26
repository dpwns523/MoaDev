from fastapi.testclient import TestClient

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
