"""Convert Neo4j graph values into frontend-safe graph JSON."""

from __future__ import annotations

from collections.abc import Iterable, Mapping
from typing import Any

from neo4j.graph import Node, Path, Relationship


GENERIC_LABELS = {
    "Protocol",
    "ProtocolInstance",
    "RoutingProtocolInstance",
    "Policy",
    "Route",
    "OverlayService",
    "Application",
}


def _json_value(value: Any) -> Any:
    if isinstance(value, Mapping):
        return {str(key): _json_value(item) for key, item in value.items()}
    if isinstance(value, (list, tuple, set)):
        return [_json_value(item) for item in value]
    if hasattr(value, "iso_format"):
        return value.iso_format()
    if hasattr(value, "isoformat"):
        return value.isoformat()
    return value


def _node_id(node: Node) -> str:
    return str(node.get("id") or node.element_id)


def _node_type(node: Node) -> str:
    labels = sorted(node.labels)
    specific = [label for label in labels if label not in GENERIC_LABELS]
    return specific[0] if specific else (labels[0] if labels else "Node")


def serialize_node(node: Node) -> dict[str, Any]:
    properties = _json_value(dict(node))
    identifier = _node_id(node)
    return {
        "id": identifier,
        "label": str(properties.get("name") or properties.get("id") or identifier),
        "type": _node_type(node),
        "properties": properties,
    }


def serialize_edge(relationship: Relationship) -> dict[str, Any]:
    semantic_id = relationship.get("id")
    return {
        "id": str(semantic_id or relationship.element_id),
        "source": _node_id(relationship.start_node),
        "target": _node_id(relationship.end_node),
        "type": relationship.type,
        "properties": _json_value(dict(relationship)),
    }


def project_paths(
    paths: Iterable[Path],
    summary: str,
    recommendations: list[dict[str, Any]] | None = None,
) -> dict[str, Any]:
    nodes: dict[str, dict[str, Any]] = {}
    edges: dict[str, dict[str, Any]] = {}

    for path in paths:
        for node in path.nodes:
            projected = serialize_node(node)
            nodes[projected["id"]] = projected
        for relationship in path.relationships:
            projected = serialize_edge(relationship)
            edges[projected["id"]] = projected

    return {
        "nodes": list(nodes.values()),
        "edges": list(edges.values()),
        "summary": summary,
        "recommendations": recommendations or [],
    }


def project_nodes(nodes: Iterable[Node], summary: str) -> dict[str, Any]:
    projected = {item["id"]: item for item in map(serialize_node, nodes)}
    return {
        "nodes": list(projected.values()),
        "edges": [],
        "summary": summary,
        "recommendations": [],
    }
