"""Structural and semantic validation for ontology YAML documents."""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any, Iterable

try:
    from .ontology_loader import (
        ONTOLOGY_DIR,
        OntologyDocument,
        load_ontology_directory,
        merge_ontologies,
    )
except ImportError:
    from ontology_loader import (
        ONTOLOGY_DIR,
        OntologyDocument,
        load_ontology_directory,
        merge_ontologies,
    )


IDENTIFIER = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")

REQUIRED_NODE_LABELS = {
    "Device",
    "Interface",
    "BusinessService",
    "DesignDomain",
    "DesignDecision",
    "DesignRisk",
    "Evidence",
    "ValidationCheck",
    "OSPFProcess",
    "ISISProcess",
    "EIGRPProcess",
    "BGPProcess",
    "VPNService",
    "IPv6Prefix",
    "MulticastDomain",
    "QoSPolicy",
    "MPLSDomain",
    "IntegrationPhase",
    "WANTransport",
    "SegmentRoutingDomain",
}

REQUIRED_RELATIONSHIP_TYPES = {
    "HAS_INTERFACE",
    "CONNECTED_TO",
    "RUNS",
    "DEPENDS_ON",
    "ADVERTISES",
    "REDISTRIBUTES_TO",
    "CONTROLLED_BY",
    "REFERENCES",
    "SUPPORTS",
    "IMPACTS",
    "INTRODUCES_RISK",
    "MITIGATED_BY",
    "VALIDATED_BY",
    "SATISFIES",
}


class OntologyValidationError(ValueError):
    """Raised when merged ontology semantics are invalid."""


def _require_mapping(
    value: Any,
    location: str,
    errors: list[str],
) -> dict[str, Any]:
    if not isinstance(value, dict):
        errors.append(f"{location} must be a mapping")
        return {}
    return value


def _require_list(
    value: Any,
    location: str,
    errors: list[str],
) -> list[Any]:
    if not isinstance(value, list):
        errors.append(f"{location} must be a list")
        return []
    return value


def validate_documents(documents: Iterable[OntologyDocument]) -> list[str]:
    """Return all format and cross-document semantic errors."""
    docs = list(documents)
    errors: list[str] = []

    ontology_ids = [document.ontology_id for document in docs]
    duplicates = sorted({item for item in ontology_ids if ontology_ids.count(item) > 1})
    if duplicates:
        errors.append(f"duplicate ontology ids: {', '.join(duplicates)}")

    for document in docs:
        data = document.data
        source = document.path.name
        labels = _require_mapping(data["node_labels"], f"{source}.node_labels", errors)
        properties = _require_mapping(data["properties"], f"{source}.properties", errors)
        relationships = _require_mapping(
            data["relationship_types"], f"{source}.relationship_types", errors
        )
        for name in labels:
            if not IDENTIFIER.fullmatch(name):
                errors.append(f"{source}: invalid node label {name!r}")
        for label, definitions in properties.items():
            if label != "*" and not IDENTIFIER.fullmatch(label):
                errors.append(f"{source}: invalid property label {label!r}")
            _require_mapping(definitions, f"{source}.properties.{label}", errors)
        for name, definition in relationships.items():
            if not IDENTIFIER.fullmatch(name):
                errors.append(f"{source}: invalid relationship type {name!r}")
            mapping = _require_mapping(
                definition, f"{source}.relationship_types.{name}", errors
            )
            _require_list(mapping.get("from"), f"{source}.{name}.from", errors)
            _require_list(mapping.get("to"), f"{source}.{name}.to", errors)
        for section in (
            "constraints",
            "dependency_rules",
            "risk_rules",
            "validation_queries",
            "example_scenarios",
        ):
            _require_list(data[section], f"{source}.{section}", errors)

    if errors:
        return errors

    merged = merge_ontologies(docs)
    labels = set(merged["node_labels"])
    relationships = merged["relationship_types"]
    property_labels = set(merged["properties"])

    missing_labels = sorted(REQUIRED_NODE_LABELS - labels)
    if missing_labels:
        errors.append(f"missing required node labels: {', '.join(missing_labels)}")
    missing_relationships = sorted(REQUIRED_RELATIONSHIP_TYPES - set(relationships))
    if missing_relationships:
        errors.append(
            "missing required relationship types: " + ", ".join(missing_relationships)
        )

    for name, definition in relationships.items():
        for direction in ("from", "to"):
            for label in definition[direction]:
                if label not in labels:
                    errors.append(
                        f"relationship {name}.{direction} references unknown label {label}"
                    )

    common_properties = merged["properties"].get("*", {})
    for label in property_labels - {"*"}:
        if label not in labels:
            errors.append(f"properties reference unknown label {label}")

    for constraint in merged["constraints"]:
        label = constraint.get("label")
        property_name = constraint.get("property")
        if label not in labels:
            errors.append(f"constraint references unknown label {label}")
            continue
        label_properties = merged["properties"].get(label, {})
        if property_name not in label_properties and property_name not in common_properties:
            errors.append(
                f"constraint {label}.{property_name} has no property definition"
            )
        if constraint.get("type") not in {"unique", "index"}:
            errors.append(f"constraint {label}.{property_name} has unsupported type")

    for rule in merged["dependency_rules"]:
        rule_id = rule.get("id", "<missing-id>")
        source = rule.get("source")
        relationship = rule.get("relationship")
        targets = rule.get("target", [])
        if source not in labels:
            errors.append(f"dependency rule {rule_id} has unknown source {source}")
        if relationship not in relationships:
            errors.append(
                f"dependency rule {rule_id} has unknown relationship {relationship}"
            )
            continue
        if not isinstance(targets, list) or not targets:
            errors.append(f"dependency rule {rule_id} requires target labels")
            continue
        for target in targets:
            if target not in labels:
                errors.append(
                    f"dependency rule {rule_id} has unknown target {target}"
                )
        definition = relationships[relationship]
        if source not in definition["from"]:
            errors.append(
                f"dependency rule {rule_id}: {source} is not allowed for {relationship}"
            )
        incompatible_targets = sorted(set(targets) - set(definition["to"]))
        if incompatible_targets:
            errors.append(
                f"dependency rule {rule_id}: targets not allowed for {relationship}: "
                + ", ".join(incompatible_targets)
            )

    for rule in merged["risk_rules"]:
        if rule.get("applies_to") not in labels:
            errors.append(
                f"risk rule {rule.get('id', '<missing-id>')} references unknown label"
            )
        for field in ("id", "when", "severity", "response"):
            if not rule.get(field):
                errors.append(f"risk rule missing {field}")

    for query in merged["validation_queries"]:
        if not query.get("id") or not str(query.get("cypher", "")).strip():
            errors.append("validation query requires id and non-empty cypher")

    return errors


def validate_or_raise(documents: Iterable[OntologyDocument]) -> None:
    errors = validate_documents(documents)
    if errors:
        raise OntologyValidationError("\n".join(f"- {error}" for error in errors))


def main(path: Path = ONTOLOGY_DIR) -> None:
    documents = load_ontology_directory(path)
    validate_or_raise(documents)
    merged = merge_ontologies(documents)
    print(
        f"Validated {len(documents)} ontology files: "
        f"{len(merged['node_labels'])} labels, "
        f"{len(merged['relationship_types'])} relationships, "
        f"{len(merged['dependency_rules'])} dependency rules."
    )


if __name__ == "__main__":
    main()
