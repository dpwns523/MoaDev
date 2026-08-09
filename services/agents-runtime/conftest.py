"""Pytest configuration for agents-runtime.

Adds the service root to sys.path so that `app.*` imports resolve when pytest
is invoked from the repository root (e.g.
``python -m pytest services/agents-runtime/tests/... -q``).
"""
import os
import sys

# Ensure the services/agents-runtime directory is on sys.path so that the
# `app` package is importable regardless of where pytest is invoked from.
_SERVICE_ROOT = os.path.dirname(__file__)
if _SERVICE_ROOT not in sys.path:
    sys.path.insert(0, _SERVICE_ROOT)
