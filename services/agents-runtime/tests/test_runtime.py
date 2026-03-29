from app.runtime import RuntimeSignal, plan_runtime_batch


def test_plan_runtime_batch_deduplicates_by_title() -> None:
    plan = plan_runtime_batch(
        [
            RuntimeSignal(source="news", title="AI release", priority=2),
            RuntimeSignal(source="prs", title="AI release", priority=5, tags=("follow-up",)),
        ]
    )

    assert len(plan.signals) == 1
    assert plan.signals[0].priority == 5
    assert plan.follow_up_required is True


def test_plan_runtime_batch_orders_by_priority_descending() -> None:
    plan = plan_runtime_batch(
        [
            RuntimeSignal(source="news", title="B item", priority=2),
            RuntimeSignal(source="news", title="A item", priority=3),
            RuntimeSignal(source="prs", title="C item", priority=1),
        ],
        max_batch_size=2,
    )

    assert [signal.title for signal in plan.signals] == ["A item", "B item"]
    assert plan.max_batch_size == 2
