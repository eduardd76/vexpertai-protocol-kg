from fastapi.testclient import TestClient

from src.api import app, get_graph_queries, get_kg_builder


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


class StubKGBuilder:
    def catalog(self):
        return {"technologies": [{"id": "ospf"}], "interactions": []}

    def preview(self, profile):
        return EMPTY_GRAPH

    def save(self, profile):
        return EMPTY_GRAPH

    def list_profiles(self):
        return [{"id": "kg-profile-test", "name": "Test"}]

    def get_profile(self, profile_id):
        return EMPTY_GRAPH if profile_id == "kg-profile-test" else None


def test_api_contract_and_slash_in_failure_entity() -> None:
    app.dependency_overrides[get_graph_queries] = lambda: StubGraphQueries()
    app.dependency_overrides[get_kg_builder] = lambda: StubKGBuilder()
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
            payload = {"name": "Test", "technologies": ["ospf"]}
            assert client.get("/kg-builder/catalog").status_code == 200
            assert client.post("/kg-builder/preview", json=payload).json() == EMPTY_GRAPH
            assert client.post("/kg-builder/profiles", json=payload).json() == EMPTY_GRAPH
            assert client.get("/kg-builder/profiles").status_code == 200
            assert client.get("/views/profile/kg-profile-test").json() == EMPTY_GRAPH
            assert client.get("/views/profile/missing").status_code == 404
    finally:
        app.dependency_overrides.clear()
