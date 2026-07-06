"""Bounded graph views for protocol, interaction, service, failure, and change."""

from __future__ import annotations

from typing import Any

from neo4j import Driver
from neo4j.graph import Node, Path

try:
    from .config import get_settings
    from .graph_projection import project_nodes, project_paths
except ImportError:
    from config import get_settings
    from graph_projection import project_nodes, project_paths


class GraphQueries:
    def __init__(self, driver: Driver):
        self.driver = driver
        self.database = get_settings().neo4j_database

    def _paths(
        self, cypher: str, parameters: dict[str, Any] | None = None
    ) -> list[Path]:
        with self.driver.session(database=self.database) as session:
            return [
                record["path"]
                for record in session.run(cypher, parameters or {})
                if record["path"] is not None
            ]

    def _recommendations(
        self, cypher: str, parameters: dict[str, Any]
    ) -> list[dict[str, Any]]:
        with self.driver.session(database=self.database) as session:
            return [record.data() for record in session.run(cypher, parameters)]

    def health(self) -> dict[str, Any]:
        with self.driver.session(database=self.database) as session:
            count = session.run("MATCH (node) RETURN count(node) AS count").single(
                strict=True
            )["count"]
        return {"status": "ok", "database": self.database, "nodes": int(count)}

    def protocol_view(self, protocol: str) -> dict[str, Any]:
        normalized = protocol.strip().lower()
        paths = self._paths(
            """
            MATCH path=(source)-[relationship]-(target)
            WHERE source.dataset = $dataset
              AND toLower(coalesce(source.module, '')) = $protocol
              AND (
                toLower(coalesce(target.module, '')) = $protocol
                OR relationship.interaction IS NOT NULL
              )
            RETURN path
            LIMIT 250
            """,
            {"dataset": "vexpertai-design-ontology", "protocol": normalized},
        )
        return project_paths(paths, f"{protocol.upper()} local protocol view.")

    def interaction_view(self, source: str, target: str) -> dict[str, Any]:
        keys = {
            f"{source.strip().lower()}-{target.strip().lower()}",
            f"{target.strip().lower()}-{source.strip().lower()}",
        }
        paths = self._paths(
            """
            MATCH path=(source)-[relationship]-(target)
            WHERE relationship.interaction IN $keys
            RETURN path
            LIMIT 200
            """,
            {"keys": sorted(keys)},
        )
        return project_paths(
            paths,
            f"Interaction points between {source.upper()} and {target.upper()}.",
        )

    def service_view(self, service_name: str) -> dict[str, Any]:
        paths = self._paths(
            """
            MATCH path=(dependency)-[:SUPPORTS_LAYER*1..12]->
                  (service:BusinessService)
            WHERE toLower(service.name) = toLower($service_name)
            RETURN path
            UNION
            MATCH path=(service:BusinessService)-[:HAS_SLA|OWNED_BY|DEPENDS_ON*1..2]->
                  (dependency)
            WHERE toLower(service.name) = toLower($service_name)
            RETURN path
            LIMIT 300
            """,
            {"service_name": service_name},
        )
        recommendations = self._recommendations(
            """
            MATCH (incident:Incident)-[:IMPACTS]->(service:BusinessService)
            MATCH (evidence:Evidence)-[:SUPPORTS]->(incident)
            MATCH (recommendation:Recommendation)-[:BASED_ON]->(evidence)
            WHERE toLower(service.name) = toLower($service_name)
            RETURN DISTINCT recommendation.name AS name,
                   recommendation.action AS action,
                   evidence.name AS evidence,
                   evidence.summary AS evidence_summary,
                   evidence.source AS evidence_source
            """,
            {"service_name": service_name},
        )
        return project_paths(
            paths,
            f"End-to-end dependencies for {service_name}.",
            recommendations,
        )

    def failure_view(self, entity_name: str) -> dict[str, Any]:
        paths = self._paths(
            """
            MATCH path=(entity)-[:SUPPORTS_LAYER*1..12]->(service:BusinessService)
            WHERE toLower(coalesce(entity.name, '')) = toLower($entity_name)
               OR toLower(coalesce(entity.id, '')) = toLower($entity_name)
            RETURN path
            UNION
            MATCH path=(entity)<-[:OBSERVED_ON]-(:Alert)<-[:CONTAINS]-(:Incident)
                  -[:IMPACTS]->(:BusinessService)
            WHERE toLower(coalesce(entity.name, '')) = toLower($entity_name)
               OR toLower(coalesce(entity.id, '')) = toLower($entity_name)
            RETURN path
            LIMIT 250
            """,
            {"entity_name": entity_name},
        )
        return project_paths(
            paths, f"Failure propagation and service impact for {entity_name}."
        )

    def change_view(self, change_id: str) -> dict[str, Any]:
        paths = self._paths(
            """
            MATCH (change:Change)
            WHERE toLower(change.id) = toLower($change_id)
               OR toLower(coalesce(change.external_id, '')) = toLower($change_id)
            WITH change
            ORDER BY CASE WHEN change.dataset = $dataset THEN 0 ELSE 1 END
            LIMIT 1
            MATCH path=(change)-[
              :MODIFIES|AFFECTS|INTRODUCES_RISK|EVIDENCES|REFERENCES|
              ROUTE_MAP_CONTROLS_REDISTRIBUTION|
              PREFIX_LIST_CONTROLS_PREFIX_VISIBILITY|
              REDISTRIBUTION_PRODUCES_BGP_ROUTE|BGP_ROUTE_CARRIES_PREFIX|
              OSPF_ROUTE_REDISTRIBUTED_INTO_BGP|SUPPORTS_LAYER|IMPACTS|
              BASED_ON|REQUIRES|SUPPORTS
              *1..6
            ]-(related)
            RETURN path
            LIMIT 300
            """,
            {"change_id": change_id, "dataset": "vexpertai-design-ontology"},
        )
        recommendations = self._recommendations(
            """
            MATCH (change:Change)<-[:EVIDENCES]-(evidence:Evidence)
                  <-[:BASED_ON]-(recommendation:Recommendation)
            WHERE toLower(change.id) = toLower($change_id)
               OR toLower(coalesce(change.external_id, '')) = toLower($change_id)
            RETURN DISTINCT recommendation.name AS name,
                   recommendation.action AS action,
                   evidence.name AS evidence,
                   evidence.summary AS evidence_summary,
                   evidence.source AS evidence_source
            """,
            {"change_id": change_id},
        )
        return project_paths(
            paths, f"Change blast radius for {change_id}.", recommendations
        )

    def search(self, query: str) -> dict[str, Any]:
        with self.driver.session(database=self.database) as session:
            nodes: list[Node] = [
                record["node"]
                for record in session.run(
                    """
                    MATCH (node)
                    WHERE node.dataset = $dataset
                      AND (
                        toLower(coalesce(node.name, '')) CONTAINS toLower($query)
                        OR toLower(coalesce(node.id, '')) CONTAINS toLower($query)
                        OR toLower(coalesce(node.cidr, '')) CONTAINS toLower($query)
                        OR toLower(coalesce(node.address, '')) CONTAINS toLower($query)
                      )
                    RETURN node
                    LIMIT 50
                    """,
                    {
                        "query": query,
                        "dataset": "vexpertai-design-ontology",
                    },
                )
            ]
        return project_nodes(nodes, f"Search results for {query}.")
