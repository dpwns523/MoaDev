from dataclasses import dataclass
from typing import Iterable


@dataclass(frozen=True)
class RuntimeSignal:
    source: str
    title: str
    priority: int
    tags: tuple[str, ...] = ()


@dataclass(frozen=True)
class RuntimeBatchPlan:
    signals: tuple[RuntimeSignal, ...]
    follow_up_required: bool
    max_batch_size: int


def plan_runtime_batch(
    signals: Iterable[RuntimeSignal],
    max_batch_size: int = 3,
) -> RuntimeBatchPlan:
    deduped: dict[str, RuntimeSignal] = {}

    for signal in signals:
        existing = deduped.get(signal.title)
        if existing is None or signal.priority > existing.priority:
            deduped[signal.title] = signal

    ordered = tuple(
        sorted(deduped.values(), key=lambda signal: (-signal.priority, signal.title))[:max_batch_size]
    )

    return RuntimeBatchPlan(
        signals=ordered,
        follow_up_required=any("follow-up" in signal.tags for signal in ordered),
        max_batch_size=max_batch_size,
    )
