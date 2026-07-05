"""Apply modular and generated ontology schema to one Neo4j database."""

from __future__ import annotations

from pathlib import Path

from neo4j import Driver

try:
    from .config import PROJECT_ROOT
    from .kg_schema import split_cypher_statements
    from .ontology_loader import ONTOLOGY_DIR, load_ontology_directory, merge_ontologies
    from .schema_generator import generate_schema_cypher
    from .validation import validate_or_raise
except ImportError:
    from config import PROJECT_ROOT
    from kg_schema import split_cypher_statements
    from ontology_loader import ONTOLOGY_DIR, load_ontology_directory, merge_ontologies
    from schema_generator import generate_schema_cypher
    from validation import validate_or_raise


SCHEMA_DIR = PROJECT_ROOT / "cypher" / "schema"
MODULAR_SCHEMA_FILES = (
    SCHEMA_DIR / "core_schema.cypher",
    SCHEMA_DIR / "protocol_schema.cypher",
    SCHEMA_DIR / "interaction_schema.cypher",
)


def _execute(driver: Driver, statements: list[str]) -> int:
    with driver.session() as session:
        for statement in statements:
            session.run(statement).consume()
    return len(statements)


def load_schema(driver: Driver) -> dict[str, int]:
    documents = load_ontology_directory(ONTOLOGY_DIR)
    validate_or_raise(documents)
    results: dict[str, int] = {}

    for path in MODULAR_SCHEMA_FILES:
        statements = split_cypher_statements(path.read_text(encoding="utf-8"))
        results[path.name] = _execute(driver, statements)

    generated = generate_schema_cypher(merge_ontologies(documents))
    results["generated_ontology_constraints"] = _execute(
        driver, split_cypher_statements(generated)
    )
    return results
