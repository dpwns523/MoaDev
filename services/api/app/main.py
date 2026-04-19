from fastapi import FastAPI, HTTPException, Request
from fastapi.exception_handlers import http_exception_handler
from fastapi.responses import JSONResponse, Response

from app.api.router import api_router


def create_app() -> FastAPI:
    app = FastAPI(title="MoaDev API")

    @app.exception_handler(HTTPException)
    async def handle_http_exception(request: Request, exc: HTTPException) -> Response:
        if isinstance(exc.detail, dict) and "code" in exc.detail and "message" in exc.detail:
            return JSONResponse(
                status_code=exc.status_code,
                content={"error": exc.detail},
                headers=exc.headers,
            )

        return await http_exception_handler(request, exc)

    app.include_router(api_router)
    return app


app = create_app()
