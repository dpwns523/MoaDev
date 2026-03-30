# syntax=docker/dockerfile:1.7

FROM python:3.12-slim AS builder
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV VENV_PATH=/opt/venv
WORKDIR /workspace/services/agents-runtime
RUN python -m venv "${VENV_PATH}"
ENV PATH="${VENV_PATH}/bin:${PATH}"
COPY services/agents-runtime/pyproject.toml ./pyproject.toml
COPY services/agents-runtime/app ./app
RUN pip install --upgrade pip setuptools wheel && pip install .

FROM python:3.12-slim AS runner
ENV PATH="/opt/venv/bin:${PATH}"
ENV PIP_DISABLE_PIP_VERSION_CHECK=1
ENV PIP_NO_CACHE_DIR=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /app
RUN addgroup --system app && adduser --system --ingroup app app
COPY --from=builder /opt/venv /opt/venv
USER app
CMD ["python", "-m", "app.runtime"]
