---
name: cost-aware-llm-pipeline
description: Cost optimization patterns for LLM API usage — model routing by task complexity, budget tracking, retry logic, and prompt caching.
origin: ECC
---

# Cost-Aware LLM Pipeline

Patterns for controlling LLM API costs while maintaining quality. Combines model routing, budget tracking, retry logic, and caching into a composable pipeline that fits Codex-driven projects and other provider-backed systems.

## When to Activate

- Building applications that call LLM APIs from Codex workflows or product code
- Processing batches of items with varying complexity
- Need to stay within a budget for API spend
- Optimizing cost without sacrificing quality on complex tasks

## Core Concepts

### 1. Model Routing by Task Complexity

Automatically select cheaper models for simple tasks, reserving expensive models for complex ones.

```python
MODEL_COMPLEX = "high-reasoning"
MODEL_EFFICIENT = "low-cost"

_COMPLEX_TEXT_THRESHOLD = 10_000  # chars
_COMPLEX_ITEM_THRESHOLD = 30      # items

def select_model(
    text_length: int,
    item_count: int,
    force_model: str | None = None,
) -> str:
    """Select model based on task complexity."""
    if force_model is not None:
        return force_model
    if text_length >= _COMPLEX_TEXT_THRESHOLD or item_count >= _COMPLEX_ITEM_THRESHOLD:
        return MODEL_COMPLEX
    return MODEL_EFFICIENT
```

### 2. Immutable Cost Tracking

Track cumulative spend with frozen dataclasses. Each API call returns a new tracker — never mutates state.

```python
from dataclasses import dataclass

@dataclass(frozen=True, slots=True)
class CostRecord:
    model: str
    input_tokens: int
    output_tokens: int
    cost_usd: float

@dataclass(frozen=True, slots=True)
class CostTracker:
    budget_limit: float = 1.00
    records: tuple[CostRecord, ...] = ()

    def add(self, record: CostRecord) -> "CostTracker":
        """Return new tracker with added record (never mutates self)."""
        return CostTracker(
            budget_limit=self.budget_limit,
            records=(*self.records, record),
        )

    @property
    def total_cost(self) -> float:
        return sum(r.cost_usd for r in self.records)

    @property
    def over_budget(self) -> bool:
        return self.total_cost > self.budget_limit
```

### 3. Narrow Retry Logic

Retry only on transient errors. Fail fast on authentication or bad request errors.

```python
import time
import httpx

_MAX_RETRIES = 3
_RETRYABLE_STATUS_CODES = {429, 500, 502, 503, 504}

def call_with_retry(func, *, max_retries: int = _MAX_RETRIES):
    """Retry only on transport failures and retryable HTTP responses."""
    for attempt in range(max_retries):
        try:
            return func()
        except httpx.HTTPStatusError as exc:
            retryable = exc.response.status_code in _RETRYABLE_STATUS_CODES
            if not retryable or attempt == max_retries - 1:
                raise
        except httpx.TransportError:
            if attempt == max_retries - 1:
                raise
        time.sleep(2 ** attempt)
```

### 4. Prompt And Result Caching

Cache repeated prompt prefixes or normalized request payloads so repeated work does not always hit the provider.

```python
import hashlib
import json

def cache_key(*, model: str, system_prompt: str, user_input: str) -> str:
    payload = {
        "model": model,
        "system_prompt": system_prompt,
        "user_input": user_input,
    }
    return hashlib.sha256(json.dumps(payload, sort_keys=True).encode()).hexdigest()
```

## Composition

Combine all four techniques in a single pipeline function:

```python
def process(text: str, config: Config, tracker: CostTracker) -> tuple[Result, CostTracker]:
    # 1. Route model
    model = select_model(len(text), estimated_items, config.force_model)

    # 2. Check budget
    if tracker.over_budget:
        raise BudgetExceededError(tracker.total_cost, tracker.budget_limit)

    # 3. Reuse cache when possible; otherwise call provider with retry
    key = cache_key(model=model, system_prompt=system_prompt, user_input=text)
    response = cache.get(key)
    if response is None:
        response = call_with_retry(lambda: client.generate(
            model=model,
            prompt=build_prompt(system_prompt, text),
        ))
        cache.set(key, response)

    # 4. Track cost (immutable)
    record = CostRecord(model=model, input_tokens=..., output_tokens=..., cost_usd=...)
    tracker = tracker.add(record)

    return parse_result(response), tracker
```

## Budgeting Reference

Keep a small local table for the providers and model tiers your project actually uses. Do not hardcode vendor pricing into the skill body because those rates change frequently.

| Tier | Typical Use | Track Per Tier |
|------|-------------|----------------|
| Low-cost | classification, extraction, routing | input rate, output rate, daily volume |
| Mid-tier | structured synthesis, multi-step transforms | input rate, output rate, retry rate |
| High-reasoning | ambiguous or high-stakes tasks | input rate, output rate, escalation threshold |

## Best Practices

- **Start with the cheapest model** and only route to expensive models when complexity thresholds are met
- **Set explicit budget limits** before processing batches — fail early rather than overspend
- **Log model selection decisions** so you can tune thresholds based on real data
- **Use caching for repeated prompt prefixes or repeated inputs** when your provider or application stack supports it
- **Never retry on authentication or validation errors** — only transient failures (network, rate limit, server error)

## Anti-Patterns to Avoid

- Using the most expensive model for all requests regardless of complexity
- Retrying on all errors (wastes budget on permanent failures)
- Mutating cost tracking state (makes debugging and auditing difficult)
- Hardcoding model names throughout the codebase (use constants or config)
- Ignoring prompt caching for repetitive system prompts

## When to Use

- Any application calling OpenAI, Anthropic, or similar LLM APIs
- Batch processing pipelines where cost adds up quickly
- Multi-model architectures that need intelligent routing
- Production systems that need budget guardrails
