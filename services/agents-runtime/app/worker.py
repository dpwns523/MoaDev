import json
import logging
import os
import signal
import threading
from dataclasses import dataclass
from typing import Any, Callable, Mapping, Optional, Sequence

from app.runtime import RuntimeBatchPlan, RuntimeSignal, plan_runtime_batch


LOGGER = logging.getLogger(__name__)

SignalProvider = Callable[[], Sequence[RuntimeSignal]]
PlanEmitter = Callable[[RuntimeBatchPlan], None]
WaitForNextCycle = Callable[[threading.Event, float], bool]


@dataclass(frozen=True)
class WorkerConfig:
    poll_interval_seconds: float = 30.0
    max_batch_size: int = 3
    run_once: bool = False


def load_worker_config(environ: Optional[Mapping[str, str]] = None) -> WorkerConfig:
    env = os.environ if environ is None else environ

    max_batch_size = _parse_positive_int(
        env.get("AGENTS_RUNTIME_MAX_BATCH_SIZE", "3"),
        field_name="AGENTS_RUNTIME_MAX_BATCH_SIZE",
    )
    poll_interval_seconds = _parse_positive_float(
        env.get("AGENTS_RUNTIME_POLL_INTERVAL_SECONDS", "30"),
        field_name="AGENTS_RUNTIME_POLL_INTERVAL_SECONDS",
    )
    run_once = _parse_bool(
        env.get("AGENTS_RUNTIME_RUN_ONCE", "false"),
        field_name="AGENTS_RUNTIME_RUN_ONCE",
    )

    return WorkerConfig(
        poll_interval_seconds=poll_interval_seconds,
        max_batch_size=max_batch_size,
        run_once=run_once,
    )


def load_seed_signals(environ: Optional[Mapping[str, str]] = None) -> tuple[RuntimeSignal, ...]:
    env = os.environ if environ is None else environ
    payload = env.get("AGENTS_RUNTIME_SIGNALS_JSON", "[]")

    try:
        raw_signals = json.loads(payload)
    except json.JSONDecodeError as exc:
        raise ValueError("AGENTS_RUNTIME_SIGNALS_JSON must contain valid JSON") from exc

    if not isinstance(raw_signals, list):
        raise ValueError("AGENTS_RUNTIME_SIGNALS_JSON must decode to a list of objects")

    return tuple(_parse_runtime_signal(raw_signal) for raw_signal in raw_signals)


def build_static_signal_provider(signals: Sequence[RuntimeSignal]) -> SignalProvider:
    frozen_signals = tuple(signals)

    def provide_signals() -> Sequence[RuntimeSignal]:
        return frozen_signals

    return provide_signals


def run_worker(
    signal_provider: SignalProvider,
    *,
    config: WorkerConfig,
    emit_plan: PlanEmitter,
    stop_event: Optional[threading.Event] = None,
    wait_for_next_cycle: Optional[WaitForNextCycle] = None,
) -> int:
    shutdown_event = stop_event or threading.Event()
    wait = wait_for_next_cycle or _wait_for_next_cycle
    iterations = 0

    while not shutdown_event.is_set():
        plan = plan_runtime_batch(
            signal_provider(),
            max_batch_size=config.max_batch_size,
        )
        emit_plan(plan)
        iterations += 1

        if config.run_once:
            break

        if wait(shutdown_event, config.poll_interval_seconds):
            break

    return iterations


def log_runtime_plan(plan: RuntimeBatchPlan, *, logger: logging.Logger = LOGGER) -> None:
    if not plan.signals:
        logger.info("runtime worker is idle; no signals available")
        return

    logger.info(
        "planned runtime batch size=%s follow_up_required=%s titles=%s",
        len(plan.signals),
        plan.follow_up_required,
        [signal.title for signal in plan.signals],
    )


def main() -> int:
    logging.basicConfig(
        level=os.environ.get("AGENTS_RUNTIME_LOG_LEVEL", "INFO").upper(),
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )

    try:
        config = load_worker_config()
        seed_signals = load_seed_signals()
    except ValueError as exc:
        LOGGER.error("invalid agents-runtime configuration: %s", exc)
        return 2

    stop_event = threading.Event()
    _install_signal_handlers(stop_event, logger=LOGGER)

    # Until upstream integrations land, the worker replays env-provided seed signals.
    signal_provider = build_static_signal_provider(seed_signals)

    LOGGER.info(
        "starting agents-runtime worker poll_interval_seconds=%s max_batch_size=%s run_once=%s seed_signal_count=%s",
        config.poll_interval_seconds,
        config.max_batch_size,
        config.run_once,
        len(seed_signals),
    )

    run_worker(
        signal_provider,
        config=config,
        emit_plan=lambda plan: log_runtime_plan(plan, logger=LOGGER),
        stop_event=stop_event,
    )

    LOGGER.info("stopping agents-runtime worker")
    return 0


def _parse_runtime_signal(raw_signal: Any) -> RuntimeSignal:
    if not isinstance(raw_signal, dict):
        raise ValueError("AGENTS_RUNTIME_SIGNALS_JSON entries must be objects")

    source = _require_string(raw_signal.get("source"), field_name="source")
    title = _require_string(raw_signal.get("title"), field_name="title")
    priority = _require_int(raw_signal.get("priority"), field_name="priority")
    raw_tags = raw_signal.get("tags", [])

    if not isinstance(raw_tags, list):
        raise ValueError("AGENTS_RUNTIME_SIGNALS_JSON field 'tags' must be a list")

    return RuntimeSignal(
        source=source,
        title=title,
        priority=priority,
        tags=tuple(_require_string(tag, field_name="tags") for tag in raw_tags),
    )


def _require_string(value: Any, *, field_name: str) -> str:
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"AGENTS_RUNTIME_SIGNALS_JSON field '{field_name}' must be a non-empty string")

    return value


def _require_int(value: Any, *, field_name: str) -> int:
    if not isinstance(value, int) or isinstance(value, bool):
        raise ValueError(f"AGENTS_RUNTIME_SIGNALS_JSON field '{field_name}' must be an integer")

    return value


def _parse_positive_int(raw_value: str, *, field_name: str) -> int:
    try:
        value = int(raw_value)
    except ValueError as exc:
        raise ValueError(f"{field_name} must be an integer") from exc

    if value < 1:
        raise ValueError(f"{field_name} must be greater than or equal to 1")

    return value


def _parse_positive_float(raw_value: str, *, field_name: str) -> float:
    try:
        value = float(raw_value)
    except ValueError as exc:
        raise ValueError(f"{field_name} must be a number") from exc

    if value <= 0:
        raise ValueError(f"{field_name} must be greater than 0")

    return value


def _parse_bool(raw_value: str, *, field_name: str) -> bool:
    normalized = raw_value.strip().lower()

    if normalized in {"1", "true", "yes", "on"}:
        return True

    if normalized in {"0", "false", "no", "off", ""}:
        return False

    raise ValueError(f"{field_name} must be a boolean")


def _wait_for_next_cycle(stop_event: threading.Event, poll_interval_seconds: float) -> bool:
    return stop_event.wait(poll_interval_seconds)


def _install_signal_handlers(stop_event: threading.Event, *, logger: logging.Logger) -> None:
    def handle_shutdown(signum: int, _frame: Any) -> None:
        logger.info("received shutdown signal=%s", signum)
        stop_event.set()

    signal.signal(signal.SIGINT, handle_shutdown)
    signal.signal(signal.SIGTERM, handle_shutdown)


if __name__ == "__main__":
    raise SystemExit(main())
