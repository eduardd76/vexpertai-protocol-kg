"""Load validated design ontology schema and seed data into Neo4j."""

from __future__ import annotations

import os
from pathlib import Path

from dotenv import load_dotenv
from neo4j import Driver, GraphDatabase
from neo4j.exceptions import AuthError, Neo4jError, ServiceUnavailable
from rich.console import Console
from rich.table import Table

try:
    from .kg_schema import PROJECT_ROOT, split_cypher_statements
    from .ontology_loader import ONTOLOGY_DIR, load_ontology_directory, merge_ontologies
    from .schema_generator import generate_schema_cypher
    from .validation import validate_or_raise
except ImportError:
    from kg_schema import PROJECT_ROOT, split_cypher_statements
    from ontology_loader import ONTOLOGY_DIR, load_ontology_directory, merge_ontologies
    from schema_generator import generate_schema_cypher
    from validation import validate_or_raise


DATASET = "vexpertai-design-ontology"
SEED_DIR = PROJECT_ROOT / "cypher" / "seed"
console = Console()


def execute_statements(driver: Driver, statements: list[str]) -> int:
    with driver.session() as session:
        for statement in statements:
            session.run(statement).consume()
    return len(statements)


def clear_design_data(driver: Driver) -> int:
    """Delete only design-ontology seed nodes."""
    with driver.session() as session:
        record = session.run(
            """
            MATCH (node)
            WHERE node.dataset = $dataset
            WITH collect(node) AS nodes
            FOREACH (node IN nodes | DETACH DELETE node)
            RETURN size(nodes) AS deleted
            """,
            dataset=DATASET,
        ).single(strict=True)
    return int(record["deleted"])


def apply_generated_schema(driver: Driver) -> int:
    documents = load_ontology_directory(ONTOLOGY_DIR)
    validate_or_raise(documents)
    cypher = generate_schema_cypher(merge_ontologies(documents))
    return execute_statements(driver, split_cypher_statements(cypher))


def load_seed_cypher(driver: Driver, seed_dir: Path = SEED_DIR) -> dict[str, int]:
    results: dict[str, int] = {}
    for path in sorted(seed_dir.glob("*.cypher")):
        statements = split_cypher_statements(path.read_text(encoding="utf-8"))
        results[path.name] = execute_statements(driver, statements)
    return results


def graph_summary(driver: Driver) -> tuple[int, int]:
    with driver.session() as session:
        record = session.run(
            """
            MATCH (node)
            WHERE node.dataset = $dataset
            WITH count(node) AS node_count
            MATCH (source)-[relationship]->(target)
            WHERE source.dataset = $dataset AND target.dataset = $dataset
            RETURN node_count, count(relationship) AS relationship_count
            """,
            dataset=DATASET,
        ).single(strict=True)
    return int(record["node_count"]), int(record["relationship_count"])


def main() -> None:
    load_dotenv()
    uri = os.getenv("NEO4J_URI", "bolt://localhost:7687")
    username = os.getenv("NEO4J_USERNAME", "neo4j")
    password = os.getenv("NEO4J_PASSWORD", "password123")
    driver = GraphDatabase.driver(uri, auth=(username, password))

    try:
        driver.verify_connectivity()
        schema_count = apply_generated_schema(driver)
        deleted_count = clear_design_data(driver)
        seed_results = load_seed_cypher(driver)
        node_count, relationship_count = graph_summary(driver)
    except (
        AuthError,
        ServiceUnavailable,
        Neo4jError,
        ValueError,
    ) as error:
        console.print(f"[bold red]Design graph load failed:[/bold red] {error}")
        raise SystemExit(1) from error
    finally:
        driver.close()

    table = Table(title="vExpertAI design ontology load complete")
    table.add_column("Item")
    table.add_column("Result", justify="right")
    table.add_row("Generated schema statements", str(schema_count))
    table.add_row("Previous design nodes deleted", str(deleted_count))
    for filename, count in seed_results.items():
        table.add_row(filename, f"{count} statements")
    table.add_row("Design nodes", str(node_count))
    table.add_row("Design relationships", str(relationship_count))
    console.print(table)


if __name__ == "__main__":
    main()
