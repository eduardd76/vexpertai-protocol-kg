from pathlib import Path
from collections import defaultdict

from src.ontology_loader import (
    REQUIRED_TOP_LEVEL_KEYS,
    load_ontology_directory,
    merge_ontologies,
)
from src.schema_generator import generate_schema_cypher
from src.validation import validate_documents


ROOT = Path(__file__).resolve().parents[1]


def test_all_ontology_documents_have_required_sections() -> None:
    documents = load_ontology_directory(ROOT / "ontology")

    assert len(documents) == 26
    for document in documents:
        assert set(REQUIRED_TOP_LEVEL_KEYS).issubset(document.data)


def test_merged_ontology_is_semantically_valid() -> None:
    documents = load_ontology_directory(ROOT / "ontology")

    assert validate_documents(documents) == []


def test_schema_generation_is_idempotent_and_declarative() -> None:
    documents = load_ontology_directory(ROOT / "ontology")
    merged = merge_ontologies(documents)
    cypher = generate_schema_cypher(merged)

    assert "IF NOT EXISTS" in cypher
    assert "DesignDecision" in cypher
    assert "IntegrationPhase" in cypher
    assert cypher == generate_schema_cypher(merged)
    assert (
        ROOT / "cypher" / "schema" / "generated_ontology_constraints.cypher"
    ).read_text(encoding="utf-8") == cypher


def test_each_domain_has_rules_and_examples() -> None:
    for document in load_ontology_directory(ROOT / "ontology"):
        assert document.data["dependency_rules"], document.path.name
        assert document.data["risk_rules"], document.path.name
        assert document.data["validation_queries"], document.path.name
        assert document.data["example_scenarios"], document.path.name


def test_each_node_label_has_one_canonical_owner() -> None:
    owners: dict[str, list[str]] = defaultdict(list)
    for document in load_ontology_directory(ROOT / "ontology"):
        for label in document.data["node_labels"]:
            owners[label].append(document.path.name)

    assert {label: files for label, files in owners.items() if len(files) > 1} == {}
