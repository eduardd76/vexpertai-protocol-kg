import pytest

from src.kg_builder import KGBuilder, ProfileInput


def test_builder_attaches_selected_modules_to_one_shared_core() -> None:
    graph = KGBuilder().preview(
        ProfileInput(
            name="Branch WAN",
            technologies=("layer2", "ospf", "bgp", "mpls", "security"),
            sites=("Branch-01", "DC-01"),
        )
    )

    node_types = {node["type"] for node in graph["nodes"]}
    edge_types = {edge["type"] for edge in graph["edges"]}
    assert {"KnowledgeGraphProfile", "CoreOntology", "TechnologyModule"} <= node_types
    assert {"USES_CORE", "ENABLES_MODULE", "EXTENDS_CORE"} <= edge_types
    assert {"FHRP_OSPF", "OSPF_BGP", "BGP_MPLS"} <= edge_types
    assert not graph["recommendations"]


def test_builder_warns_about_missing_cross_protocol_prerequisites() -> None:
    graph = KGBuilder().preview(
        ProfileInput(
            name="Incomplete Edge",
            technologies=("bgp", "mpls", "segment-routing"),
        )
    )
    warning_names = {warning["name"] for warning in graph["recommendations"]}
    assert {
        "BGP has no modeled IGP",
        "MPLS has no modeled IGP underlay",
        "Segment Routing has no SID-advertising IGP",
    } <= warning_names


def test_builder_rejects_unknown_or_empty_technology_selection() -> None:
    with pytest.raises(ValueError, match="Profile name is required"):
        KGBuilder().preview(ProfileInput(name="  ", technologies=("ospf",)))
    with pytest.raises(ValueError, match="Select at least one"):
        KGBuilder().preview(ProfileInput(name="Empty", technologies=()))
    with pytest.raises(ValueError, match="Unknown technologies"):
        KGBuilder().preview(ProfileInput(name="Unknown", technologies=("rip",)))
