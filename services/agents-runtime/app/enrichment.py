"""Deterministic enrichment stub for GeekNews articles.

Provides pass-through translation (Korean source, no-op) and deterministic
summary generation from a fixed template.  No LLM API calls, no API keys,
no cost.

Enrichment produces exactly two fields:
  - translated_text: pass-through copy of original_text
  - summary: deterministic template string of the title
"""
from __future__ import annotations


def translate_text(text: str) -> str:
    """Return pass-through copy of *text* (no-op translation for Korean source).

    For the GeekNews source (Korean content), translation is a pass-through
    so that the translated_text field contains the original Korean text
    verbatim.  This is the correct semantic for a Korean-language source when
    no translation model is invoked.

    Args:
        text: Original Korean text from the feed.

    Returns:
        Identical copy of the input text.
    """
    return text


def generate_summary(title: str) -> str:
    """Return a deterministic Korean summary for *title*.

    The template is fixed so that identical input always yields identical
    output.  The result is non-empty and at least 10 characters long.

    Template shape: ``"{title} 요약 - 자동 생성된 예시 요약"``

    Args:
        title: Article title (Korean).

    Returns:
        Deterministic summary string in Korean.
    """
    return f"{title} 요약 - 자동 생성된 예시 요약"
