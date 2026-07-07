# Root conftest.py.
#
# Its mere presence makes pytest add the repository root to sys.path (default
# "prepend" import mode), so `from src....` imports resolve when running the
# suite with a plain `pytest` invocation — the command documented in CLAUDE.md.
# Without it, only `python -m pytest` works (which puts cwd on the path).
