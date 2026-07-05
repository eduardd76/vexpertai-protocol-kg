"""Run design-ontology Cypher query files and print readable results."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
from typing import Any

from dotenv import load_dotenv
from neo4j import Driver, GraphDatabase
from rich.console import Console
from rich.table import Table

try:
    from .kg_schema import PROJECT_ROOT, split_cypher_statements
except ImportError:
    from kg_schema import PROJECT_ROOT, split_cypher_statements


DEFAULT_QUERY_FILE = PROJECT_ROOT / "cypher" / "queries" / "design_queries.cypher"
console = Console()


def run_query(driver: Driver, cypher: str) -> list[dict[str, Any]]:
    with driver.session() as session:
        return [record.data() for record in session.run(cypher)]


def run_query_file(driver: Driver, path: Path) -> list[list[dict[str, Any]]]:
    statements = split_cypher_statements(path.read_text(encoding="utf-8"))
    return [run_query(driver, statement) for statement in statements]


def print_results(results: list[list[dict[str, Any]]]) -> None:
    for index, rows in enumerate(results, start=1):
        console.rule(f"[bold blue]Design query {index}")
        if not rows:
            console.print("[yellow]No matching graph data.[/yellow]")
            continue
        table = Table(show_header=True, header_style="cyan")
        for column in rows[0]:
            table.add_column(column.replace("_", " ").title())
        for row in rows:
            table.add_row(*(str(value) if value is not None else "—" for value in row.values()))
        console.print(table)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("query_file", nargs="?", type=Path, default=DEFAULT_QUERY_FILE)
    args = parser.parse_args()

    load_dotenv()
    driver = GraphDatabase.driver(
        os.getenv("NEO4J_URI", "bolt://localhost:7687"),
        auth=(
            os.getenv("NEO4J_USERNAME", "neo4j"),
            os.getenv("NEO4J_PASSWORD", "password123"),
        ),
    )
    try:
        driver.verify_connectivity()
        print_results(run_query_file(driver, args.query_file))
    finally:
        driver.close()


if __name__ == "__main__":
    main()
