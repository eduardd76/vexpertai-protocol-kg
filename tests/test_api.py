from fastapi.testclient import TestClient

from src.api import app, get_graph_queries


EMPTY_GRAPH = {
    "nodes": [],
    "edges": [],
    "summary": "test",
    "recommendations": [],
}


class StubGraphQueries:
    def health(self):
        return {"status": "ok", "database": "neo4j", "nodes": 1}

    def protocol_view(self, protocol):
        return EMPTY_GRAPH

    def interaction_view(self, source, target):
        return EMPTY_GRAPH

    def service_view(self, service):
        return EMPTY_GRAPH

    def failure_view(self, entity):
        assert entity == "Ethernet1/49"
        return EMPTY_GRAPH

    def change_view(self, change):
        return EMPTY_GRAPH

    def search(self, query):
        return EMPTY_GRAPH


def test_api_contract_and_slash_in_failure_entity() -> None:
    app.dependency_overrides[get_graph_queries] = lambda: StubGraphQueries()
    try:
        with TestClient(app) as client:
            assert client.get("/health").status_code == 200
            for path in (
                "/views/protocol/ospf",
                "/views/interaction/ospf/bgp",
                "/views/service/Payment-App",
                "/views/failure/Ethernet1%2F49",
                "/views/change/CHG-8821",
                "/search?q=Payment",
            ):
                response = client.get(path)
                assert response.status_code == 200
                assert response.json() == EMPTY_GRAPH
    finally:
        app.dependency_overrides.clear()
