import json

import pytest

from app.runtime import RuntimeSignal
from app.worker import WorkerConfig, load_seed_signals, load_worker_config, run_worker


def test_load_worker_config_rejects_non_positive_batch_size() -> None:
    with pytest.raises(ValueError, match="AGENTS_RUNTIME_MAX_BATCH_SIZE"):
        load_worker_config({"AGENTS_RUNTIME_MAX_BATCH_SIZE": "0"})


def test_load_seed_signals_reads_json_payload() -> None:
    signals = load_seed_signals(
        {
            "AGENTS_RUNTIME_SIGNALS_JSON": json.dumps(
                [
                    {
                        "source": "news",
                        "title": "AI release",
                        "priority": 4,
                        "tags": ["follow-up"],
                    }
                ]
            )
        }
    )

    assert signals == (
        RuntimeSignal(
            source="news",
            title="AI release",
            priority=4,
            tags=("follow-up",),
        ),
    )


def test_run_worker_emits_prioritized_plan_for_a_single_iteration() -> None:
    config = WorkerConfig(max_batch_size=2, poll_interval_seconds=5, run_once=True)
    emitted_plans = []

    iterations = run_worker(
        lambda: (
            RuntimeSignal(source="news", title="A item", priority=1),
            RuntimeSignal(source="prs", title="B item", priority=5, tags=("follow-up",)),
            RuntimeSignal(source="news", title="C item", priority=3),
        ),
        config=config,
        emit_plan=emitted_plans.append,
    )

    assert iterations == 1
    assert len(emitted_plans) == 1
    assert [signal.title for signal in emitted_plans[0].signals] == ["B item", "C item"]
    assert emitted_plans[0].follow_up_required is True
