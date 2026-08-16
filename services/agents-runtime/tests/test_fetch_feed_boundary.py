"""Tests for fetch_feed's boundary validation against DB column limits.

Found by code review: a title/canonical_url/external_id longer than its DB
column would previously only fail later at INSERT time with an opaque
driver error. fetch_feed now rejects such entries at the parse boundary.
"""
from __future__ import annotations

from unittest.mock import Mock, patch

from app.pipeline import (
    _MAX_CANONICAL_URL_LENGTH,
    _MAX_EXTERNAL_ID_LENGTH,
    _MAX_TITLE_LENGTH,
    fetch_feed,
)

_ATOM_NS = "http://www.w3.org/2005/Atom"


def _atom_feed(entry_xml: str) -> bytes:
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="{_ATOM_NS}">
  <title>GeekNews</title>
  {entry_xml}
</feed>
""".encode()


def _fetch(entry_xml: str) -> list:
    raw = _atom_feed(entry_xml)
    response = Mock()
    response.read.return_value = raw
    response.__enter__ = Mock(return_value=response)
    response.__exit__ = Mock(return_value=False)
    with patch("urllib.request.urlopen", return_value=response):
        return fetch_feed("https://news.hada.io/rss/news")


def test_oversized_title_is_rejected() -> None:
    oversized_title = "제" * (_MAX_TITLE_LENGTH + 1)
    entry_xml = f"""
      <entry>
        <id>https://news.hada.io/topic?id=1</id>
        <title>{oversized_title}</title>
        <link rel="alternate" href="https://news.hada.io/topic?id=1"/>
        <content>본문</content>
      </entry>
    """
    assert _fetch(entry_xml) == []


def test_oversized_canonical_url_is_rejected() -> None:
    oversized_url = "https://news.hada.io/" + ("x" * _MAX_CANONICAL_URL_LENGTH)
    entry_xml = f"""
      <entry>
        <id>{oversized_url}</id>
        <title>정상 제목</title>
        <link rel="alternate" href="{oversized_url}"/>
        <content>본문</content>
      </entry>
    """
    assert _fetch(entry_xml) == []


def test_oversized_external_id_is_rejected() -> None:
    oversized_id = "https://news.hada.io/" + ("x" * _MAX_EXTERNAL_ID_LENGTH)
    entry_xml = f"""
      <entry>
        <id>{oversized_id}</id>
        <title>정상 제목</title>
        <link rel="alternate" href="https://news.hada.io/topic?id=2"/>
        <content>본문</content>
      </entry>
    """
    assert _fetch(entry_xml) == []


def test_well_formed_entry_still_parses_correctly() -> None:
    """Regression guard for the <id>-lookup dedup refactor: canonical_url
    and external_id must still resolve correctly for a normal entry."""
    entry_xml = """
      <entry>
        <id>https://news.hada.io/topic?id=3</id>
        <title>정상 제목</title>
        <link rel="alternate" href="https://news.hada.io/topic?id=3"/>
        <content>본문 내용</content>
      </entry>
    """
    entries = _fetch(entry_xml)
    assert len(entries) == 1
    assert entries[0].title == "정상 제목"
    assert entries[0].canonical_url == "https://news.hada.io/topic?id=3"
    assert entries[0].external_id == "https://news.hada.io/topic?id=3"


def test_entry_without_alternate_link_falls_back_to_id_for_canonical_url() -> None:
    """When there is no <link rel="alternate">, canonical_url must fall back
    to <id> — still correct after the id_el lookup was deduplicated."""
    entry_xml = """
      <entry>
        <id>https://news.hada.io/topic?id=4</id>
        <title>링크 없는 기사</title>
        <content>본문</content>
      </entry>
    """
    entries = _fetch(entry_xml)
    assert len(entries) == 1
    assert entries[0].canonical_url == "https://news.hada.io/topic?id=4"
    assert entries[0].external_id == "https://news.hada.io/topic?id=4"
