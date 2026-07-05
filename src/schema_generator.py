"""Generate Neo4j constraints and indexes from ontology YAML."""

from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Any

try:
    from .ontology_loader import ONTOLOGY_DIR, load_ontology_directory, merge_ontologies
    from .validation import validate_or_raise
except ImportError:
    from ontology_loader import ONTOLOGY_DIR, load_ontology_directory, merge_ontologies
    from validation import validate_or_raise


def _snake_case(value: str) -> str:
    normalized = value.replace("IPv6", "IPV6").replace("QoS", "QOS")
    acronym_boundary = re.sub(r"([A-Z]+)([A-Z][a-z])", r"\1_\2", normalized)
    return re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", acronym_boundary).lower()


def generate_schema_cypher(ontology: dict[str, Any]) -> str:
    """Generate idempotent Neo4j DDL from merged ontology constraints."""
    statements: list[str] = []
    seen: set[tuple[str, str, str]] = set()

    for constraint in ontology["constraints"]:
        label = constraint["label"]
        property_name = constraint["property"]
        constraint_type = constraint["type"]
        key = (label, property_name, constraint_type)
        if key in seen:
            continue
        seen.add(key)

        base_name = f"ontology_{_snake_case(label)}_{property_name}"
        if constraint_type == "unique":
            statements.append(
                f"CREATE CONSTRAINT {base_name}_unique IF NOT EXISTS "
                f"FOR (n:{label}) REQUIRE n.{property_name} IS UNIQUE;"
            )
        elif constraint_type == "index":
            statements.append(
                f"CREATE INDEX {base_name}_index IF NOT EXISTS "
                f"FOR (n:{label}) ON (n.{property_name});"
            )
        else:
            raise ValueError(f"Unsupported constraint type: {constraint_type}")

    return "\n".join(statements) + "\n"


def build_schema(ontology_path: Path = ONTOLOGY_DIR) -> str:
    documents = load_ontology_directory(ontology_path)
    validate_or_raise(documents)
    return generate_schema_cypher(merge_ontologies(documents))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ontology-dir", type=Path, default=ONTOLOGY_DIR)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    cypher = build_schema(args.ontology_dir)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(cypher, encoding="utf-8")
        print(f"Wrote {args.output}")
    else:
        print(cypher, end="")


if __name__ == "__main__":
    main()
