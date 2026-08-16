"""Tests for the deterministic enrichment stub (app.enrichment)."""
from __future__ import annotations

from app.enrichment import generate_summary, translate_text


def test_translate_text_is_passthrough() -> None:
    """translate_text returns the input unchanged (no-op for Korean source)."""
    text = "GeekNews 소스 최초 기사 본문입니다."
    assert translate_text(text) == text


def test_translate_text_empty_string() -> None:
    """translate_text handles an empty string without error."""
    assert translate_text("") == ""


def test_generate_summary_is_deterministic() -> None:
    """Same title always produces the same summary."""
    title = "인공지능 최신 동향"
    assert generate_summary(title) == generate_summary(title)


def test_generate_summary_minimum_length() -> None:
    """Summary is at least 10 characters long."""
    summary = generate_summary("짧은")
    assert len(summary) >= 10, f"Summary too short: {summary!r}"


def test_generate_summary_not_empty() -> None:
    """Summary is non-empty."""
    assert generate_summary("어떤 제목이든") != ""


def test_generate_summary_contains_title() -> None:
    """Summary contains the input title."""
    title = "테스트 제목 문자열"
    assert title in generate_summary(title)
