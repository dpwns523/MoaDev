from app.main import create_app


def test_create_app_registers_expected_routes() -> None:
    app = create_app()

    route_paths = {route.path for route in app.routes}

    assert "/health" in route_paths
    assert "/api/v1/feeds" in route_paths
