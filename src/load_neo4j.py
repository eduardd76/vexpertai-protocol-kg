"""Apply the schema and load deterministic MVP data into Neo4j."""

import os

from dotenv import load_dotenv
from neo4j import Driver, GraphDatabase
from neo4j.exceptions import AuthError, Neo4jError, ServiceUnavailable
from rich.console import Console
from rich.table import Table

from kg_schema import apply_schema
from seed_data import load_seed_data
from graph_loader import (
    apply_generated_schema,
    clear_design_data,
    graph_summary as design_graph_summary,
    load_seed_cypher,
)


DATASET = "vexpertai-mvp"
console = Console()


def connection_settings() -> tuple[str, str, str]:
    """Read Neo4j settings from the environment with local defaults."""
    load_dotenv()
    return (
        os.getenv("NEO4J_URI", "bolt://localhost:7687"),
        os.getenv("NEO4J_USERNAME", "neo4j"),
        os.getenv("NEO4J_PASSWORD", "password123"),
    )


def clear_mvp_data(driver: Driver) -> int:
    """Delete only data owned by this MVP and return the deleted node count."""
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


def graph_summary(driver: Driver) -> tuple[int, int]:
    """Return node and relationship counts for the MVP dataset."""
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
    uri, username, password = connection_settings()
    driver = GraphDatabase.driver(uri, auth=(username, password))

    try:
        driver.verify_connectivity()
        schema_statements = apply_schema(driver)
        deleted_nodes = clear_mvp_data(driver)
        loaded_files = load_seed_data(driver)
        node_count, relationship_count = graph_summary(driver)
        design_schema_statements = apply_generated_schema(driver)
        deleted_design_nodes = clear_design_data(driver)
        design_loaded_files = load_seed_cypher(driver)
        design_node_count, design_relationship_count = design_graph_summary(driver)
    except (AuthError, ServiceUnavailable, Neo4jError, ValueError) as error:
        console.print(f"[bold red]Neo4j load failed:[/bold red] {error}")
        raise SystemExit(1) from error
    finally:
        driver.close()

    table = Table(title="vExpertAI KG load complete")
    table.add_column("Item")
    table.add_column("Result", justify="right")
    table.add_row("Schema statements", str(schema_statements))
    table.add_row("Previous MVP nodes deleted", str(deleted_nodes))
    for filename, count in loaded_files.items():
        table.add_row(filename, f"{count} statements")
    table.add_row("MVP nodes", str(node_count))
    table.add_row("MVP relationships", str(relationship_count))
    table.add_row("Design schema statements", str(design_schema_statements))
    table.add_row("Previous design nodes deleted", str(deleted_design_nodes))
    for filename, count in design_loaded_files.items():
        table.add_row(f"design/{filename}", f"{count} statements")
    table.add_row("Design nodes", str(design_node_count))
    table.add_row("Design relationships", str(design_relationship_count))
    console.print(table)


if __name__ == "__main__":
    main()
