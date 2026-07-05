"""Neo4j driver construction and query helpers."""

from __future__ import annotations

from collections.abc import Mapping
from typing import Any

from neo4j import Driver, GraphDatabase

try:
    from .config import Settings, get_settings
except ImportError:
    from config import Settings, get_settings


def create_driver(settings: Settings | None = None) -> Driver:
    config = settings or get_settings()
    return GraphDatabase.driver(
        config.neo4j_uri,
        auth=(config.neo4j_username, config.neo4j_password),
    )


def run_query(
    driver: Driver,
    cypher: str,
    parameters: Mapping[str, Any] | None = None,
) -> list[dict[str, Any]]:
    settings = get_settings()
    with driver.session(database=settings.neo4j_database) as session:
        return [record.data() for record in session.run(cypher, parameters or {})]
