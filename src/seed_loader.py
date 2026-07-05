"""Load all protocol modules and interaction scenarios into one Neo4j graph."""

from __future__ import annotations

from pathlib import Path

from neo4j import Driver
from neo4j.exceptions import Neo4jError
from rich.console import Console
from rich.table import Table

try:
    from .config import PROJECT_ROOT, get_settings
    from .db import create_driver
    from .kg_schema import split_cypher_statements
    from .schema_loader import load_schema
except ImportError:
    from config import PROJECT_ROOT, get_settings
    from db import create_driver
    from kg_schema import split_cypher_statements
    from schema_loader import load_schema


SEED_DIR = PROJECT_ROOT / "cypher" / "seed"
console = Console()


def clear_dataset(driver: Driver, dataset: str) -> int:
    with driver.session() as session:
        record = session.run(
            """
            MATCH (node {dataset: $dataset})
            WITH collect(node) AS nodes
            FOREACH (node IN nodes | DETACH DELETE node)
            RETURN size(nodes) AS deleted
            """,
            dataset=dataset,
        ).single(strict=True)
    return int(record["deleted"])


def _seed_order(path: Path) -> tuple[int, str]:
    explicit = {
        "global_seed.cypher": 100,
        "protocol_modules_seed.cypher": 101,
        "interaction_scenarios_seed.cypher": 102,
    }
    return explicit.get(path.name, 0), path.name


def load_seeds(driver: Driver) -> dict[str, int]:
    results: dict[str, int] = {}
    for path in sorted(SEED_DIR.glob("*.cypher"), key=_seed_order):
        statements = split_cypher_statements(path.read_text(encoding="utf-8"))
        with driver.session() as session:
            for statement in statements:
                session.run(statement).consume()
        results[path.name] = len(statements)
    return results


def graph_summary(driver: Driver, dataset: str) -> tuple[int, int]:
    with driver.session() as session:
        record = session.run(
            """
            MATCH (node {dataset: $dataset})
            WITH count(node) AS nodes
            MATCH (source {dataset: $dataset})-[relationship]->(target {dataset: $dataset})
            RETURN nodes, count(relationship) AS relationships
            """,
            dataset=dataset,
        ).single(strict=True)
    return int(record["nodes"]), int(record["relationships"])


def main() -> None:
    settings = get_settings()
    driver = create_driver(settings)
    try:
        driver.verify_connectivity()
        schema_results = load_schema(driver)
        deleted = clear_dataset(driver, settings.dataset)
        seed_results = load_seeds(driver)
        nodes, relationships = graph_summary(driver, settings.dataset)
    except (Neo4jError, ValueError) as error:
        console.print(f"[bold red]Seed load failed:[/bold red] {error}")
        raise SystemExit(1) from error
    finally:
        driver.close()

    table = Table(title="vExpertAI unified graph load complete")
    table.add_column("Item")
    table.add_column("Result", justify="right")
    for name, count in schema_results.items():
        table.add_row(f"schema/{name}", str(count))
    table.add_row("Previous design nodes deleted", str(deleted))
    for name, count in seed_results.items():
        table.add_row(f"seed/{name}", str(count))
    table.add_row("Design nodes", str(nodes))
    table.add_row("Design relationships", str(relationships))
    console.print(table)


if __name__ == "__main__":
    main()
