"""Load and merge reusable network ontology YAML documents."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

import yaml


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ONTOLOGY_DIR = PROJECT_ROOT / "ontology"
REQUIRED_TOP_LEVEL_KEYS = (
    "ontology",
    "node_labels",
    "properties",
    "relationship_types",
    "constraints",
    "dependency_rules",
    "risk_rules",
    "validation_queries",
    "example_scenarios",
)


class OntologyFormatError(ValueError):
    """Raised when an ontology document cannot be safely merged."""


@dataclass(frozen=True)
class OntologyDocument:
    path: Path
    data: dict[str, Any]

    @property
    def ontology_id(self) -> str:
        return str(self.data["ontology"]["id"])


def load_ontology_file(path: Path) -> OntologyDocument:
    """Load one YAML ontology document."""
    try:
        raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    except yaml.YAMLError as error:
        raise OntologyFormatError(f"{path}: invalid YAML: {error}") from error

    if not isinstance(raw, dict):
        raise OntologyFormatError(f"{path}: top-level YAML value must be a mapping")

    missing = [key for key in REQUIRED_TOP_LEVEL_KEYS if key not in raw]
    if missing:
        raise OntologyFormatError(f"{path}: missing keys: {', '.join(missing)}")

    metadata = raw.get("ontology")
    if not isinstance(metadata, dict) or not metadata.get("id"):
        raise OntologyFormatError(f"{path}: ontology.id is required")

    return OntologyDocument(path=path, data=raw)


def load_ontology_directory(path: Path = ONTOLOGY_DIR) -> list[OntologyDocument]:
    """Load all ontology YAML files in deterministic filename order."""
    files = sorted(path.rglob("*.yaml"), key=lambda item: item.relative_to(path).as_posix())
    if not files:
        raise OntologyFormatError(f"{path}: no ontology YAML files found")
    return [load_ontology_file(file_path) for file_path in files]


def _merge_mapping(
    target: dict[str, Any],
    incoming: dict[str, Any],
    source: Path,
    section: str,
) -> None:
    for key, value in incoming.items():
        if key in target and target[key] != value:
            raise OntologyFormatError(
                f"{source}: conflicting {section} definition for {key}"
            )
        target[key] = value


def merge_ontologies(
    documents: Iterable[OntologyDocument],
) -> dict[str, Any]:
    """Merge ontology documents into one validated-shape dictionary."""
    merged: dict[str, Any] = {
        "ontology_ids": [],
        "node_labels": {},
        "properties": {},
        "relationship_types": {},
        "constraints": [],
        "dependency_rules": [],
        "risk_rules": [],
        "validation_queries": [],
        "example_scenarios": [],
    }

    for document in documents:
        data = document.data
        merged["ontology_ids"].append(document.ontology_id)
        _merge_mapping(
            merged["node_labels"], data["node_labels"], document.path, "node label"
        )
        _merge_mapping(
            merged["relationship_types"],
            data["relationship_types"],
            document.path,
            "relationship",
        )

        for label, definitions in data["properties"].items():
            existing = merged["properties"].setdefault(label, {})
            _merge_mapping(existing, definitions, document.path, f"{label} property")

        for section in (
            "constraints",
            "dependency_rules",
            "risk_rules",
            "validation_queries",
            "example_scenarios",
        ):
            merged[section].extend(data[section])

    return merged
