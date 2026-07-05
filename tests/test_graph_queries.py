import os
from pathlib import Path

import pytest
from neo4j import GraphDatabase

from src.graph_queries import GraphQueries


ROOT = Path(__file__).resolve().parents[1]
SEED_DIR = ROOT / "cypher" / "seed"


class EmptyGraphQueries(GraphQueries):
    def __init__(self):
        pass

    def _paths(self, cypher, parameters=None):
        return []

    def _recommendations(self, cypher, parameters):
        return []


@pytest.mark.parametrize(
    ("method", "arguments"),
    (
        ("protocol_view", ("ospf",)),
        ("interaction_view", ("ospf", "bgp")),
        ("service_view", ("Payment-App",)),
        ("failure_view", ("Ethernet1/49",)),
        ("change_view", ("CHG-8821",)),
    ),
)
def test_graph_queries_return_stable_json_shape(method: str, arguments: tuple) -> None:
    graph = getattr(EmptyGraphQueries(), method)(*arguments)
    assert set(graph) == {"nodes", "edges", "summary", "recommendations"}
    assert isinstance(graph["nodes"], list)
    assert isinstance(graph["edges"], list)


def test_payment_seed_contains_complete_dependency_chain() -> None:
    seed = (SEED_DIR / "protocol_modules_seed.cypher").read_text(encoding="utf-8")
    for label in (
        "VLAN",
        "FHRPGroup",
        "OSPFProcess",
        "BGPProcess",
        "MPLSL3VPN",
        "VRF",
        "FirewallRule",
        "ApplicationEndpoint",
    ):
        assert f":{label}" in seed


def test_chg_8821_seed_has_policy_to_prefix_lineage() -> None:
    protocol_seed = (SEED_DIR / "protocol_modules_seed.cypher").read_text(
        encoding="utf-8"
    )
    incident_seed = (SEED_DIR / "interaction_scenarios_seed.cypher").read_text(
        encoding="utf-8"
    )
    for relationship in (
        "REFERENCES",
        "ROUTE_MAP_CONTROLS_REDISTRIBUTION",
        "REDISTRIBUTION_PRODUCES_BGP_ROUTE",
        "BGP_ROUTE_CARRIES_PREFIX",
        "PREFIX_LIST_CONTROLS_PREFIX_VISIBILITY",
    ):
        assert relationship in protocol_seed
    assert "CHG-8821" in incident_seed
    assert "[:MODIFIES]" in incident_seed


@pytest.fixture
def live_driver():
    if os.getenv("VEXPERTAI_RUN_NEO4J_TESTS") != "1":
        pytest.skip("Set VEXPERTAI_RUN_NEO4J_TESTS=1 for live graph integrity checks")
    driver = GraphDatabase.driver(
        os.getenv("NEO4J_URI", "bolt://localhost:7687"),
        auth=(
            os.getenv("NEO4J_USERNAME", "neo4j"),
            os.getenv("NEO4J_PASSWORD", "password123"),
        ),
    )
    driver.verify_connectivity()
    yield driver
    driver.close()


def test_live_seed_integrity(live_driver) -> None:
    checks = {
        "services_without_infrastructure": """
            MATCH (service:BusinessService)
            WHERE service.id STARTS WITH 'view-'
              AND NOT (:Interface)-[:SUPPORTS_LAYER*1..12]->(service)
            RETURN count(service) AS count
        """,
        "changes_without_modifies": """
            MATCH (change:Change)
            WHERE change.dataset = 'vexpertai-design-ontology'
              AND NOT (change)-[:MODIFIES]->()
            RETURN count(change) AS count
        """,
        "incidents_without_evidence_or_recommendation": """
            MATCH (incident:Incident)
            WHERE incident.id STARTS WITH 'view-'
              AND (
                NOT (:Evidence)-[:SUPPORTS]->(incident)
                OR NOT (:Recommendation)-[:BASED_ON]->(:Evidence)-[:SUPPORTS]->(incident)
              )
            RETURN count(incident) AS count
        """,
    }
    with live_driver.session() as session:
        for name, cypher in checks.items():
            assert session.run(cypher).single(strict=True)["count"] == 0, name

    queries = GraphQueries(live_driver)
    failure = queries.failure_view("Ethernet1/49")
    assert any(node["type"] == "BusinessService" for node in failure["nodes"])

    service = queries.service_view("Payment-App")
    service_types = {node["type"] for node in service["nodes"]}
    assert {
        "VLAN",
        "FHRPGroup",
        "OSPFProcess",
        "BGPProcess",
        "MPLSL3VPN",
        "VRF",
        "FirewallRule",
        "ApplicationEndpoint",
    } <= service_types
