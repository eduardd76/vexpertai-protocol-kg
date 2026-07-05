"""Helpers for applying the Neo4j schema."""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from neo4j import Driver


PROJECT_ROOT = Path(__file__).resolve().parents[1]
CYPHER_DIR = PROJECT_ROOT / "cypher"
SCHEMA_FILE = CYPHER_DIR / "schema.cypher"


def split_cypher_statements(script: str) -> list[str]:
    """Split a Cypher script on semicolons outside strings and comments."""
    statements: list[str] = []
    current: list[str] = []
    in_single_quote = False
    in_double_quote = False
    in_line_comment = False
    index = 0

    while index < len(script):
        char = script[index]
        next_char = script[index + 1] if index + 1 < len(script) else ""

        if in_line_comment:
            if char == "\n":
                in_line_comment = False
                current.append("\n")
            index += 1
            continue

        if not in_single_quote and not in_double_quote and char == "/" and next_char == "/":
            in_line_comment = True
            index += 2
            continue

        if (in_single_quote or in_double_quote) and char == "\\" and next_char:
            current.extend((char, next_char))
            index += 2
            continue

        if char == "'" and not in_double_quote:
            in_single_quote = not in_single_quote
            current.append(char)
        elif char == '"' and not in_single_quote:
            in_double_quote = not in_double_quote
            current.append(char)
        elif char == ";" and not in_single_quote and not in_double_quote:
            statement = "".join(current).strip()
            if statement:
                statements.append(statement)
            current = []
        else:
            current.append(char)

        index += 1

    trailing = "".join(current).strip()
    if trailing:
        statements.append(trailing)

    if in_single_quote or in_double_quote:
        raise ValueError("Unterminated string in Cypher script")

    return statements


def load_cypher_file(path: Path) -> list[str]:
    """Read a Cypher file and return executable statements."""
    return split_cypher_statements(path.read_text(encoding="utf-8"))


def execute_cypher_file(driver: Driver, path: Path) -> int:
    """Execute all statements in a Cypher file and return their count."""
    statements = load_cypher_file(path)
    with driver.session() as session:
        for statement in statements:
            session.run(statement).consume()
    return len(statements)


def apply_schema(driver: Driver) -> int:
    """Apply constraints and indexes."""
    return execute_cypher_file(driver, SCHEMA_FILE)
