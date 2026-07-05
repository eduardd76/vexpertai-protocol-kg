from pathlib import Path

from src.ontology_loader import load_ontology_directory, merge_ontologies


ROOT = Path(__file__).resolve().parents[1]
ONTOLOGY = ROOT / "ontology"

PROTOCOL_FILES = {
    "layer2_stp_fhrp.yaml",
    "ospf.yaml",
    "bgp.yaml",
    "mpls.yaml",
    "vpn.yaml",
    "segment_routing.yaml",
    "qos.yaml",
    "security_policy.yaml",
}

INTERACTION_TYPES = {
    "STP_ROOT_SHOULD_ALIGN_WITH_FHRP_ACTIVE",
    "FHRP_ACTIVE_SHOULD_TRACK_IGP_REACHABILITY",
    "BGP_NEIGHBOR_DEPENDS_ON_IGP_REACHABILITY",
    "BGP_ROUTE_DEPENDS_ON_NEXT_HOP_REACHABILITY",
    "BGP_BEST_PATH_DEPENDS_ON_IGP_METRIC",
    "OSPF_ROUTE_REDISTRIBUTED_INTO_BGP",
    "ROUTE_MAP_CONTROLS_REDISTRIBUTION",
    "PREFIX_LIST_CONTROLS_PREFIX_VISIBILITY",
    "MPLS_LSP_DEPENDS_ON_IGP_UNDERLAY",
    "VPN_ROUTE_DEPENDS_ON_MPLS_LABEL",
    "SR_POLICY_DEPENDS_ON_IGP_SID_ADVERTISEMENT",
    "QOS_POLICY_PROTECTS_APPLICATION_SLA",
    "FIREWALL_POLICY_CONTROLS_APPLICATION_PATH",
    "OVERLAY_DEPENDS_ON_UNDERLAY",
}


def test_expected_protocol_and_interaction_modules_exist() -> None:
    assert {path.name for path in (ONTOLOGY / "protocols").glob("*.yaml")} == (
        PROTOCOL_FILES
    )
    assert len(list((ONTOLOGY / "interactions").glob("*.yaml"))) == 9


def test_protocol_modules_do_not_redefine_core_labels() -> None:
    documents = load_ontology_directory(ONTOLOGY)
    core = next(document for document in documents if document.ontology_id == "core")
    core_labels = set(core.data["node_labels"])

    for document in documents:
        if document.path.parent.name == "protocols":
            assert not (set(document.data["node_labels"]) & core_labels), document.path


def test_every_protocol_module_attaches_to_core() -> None:
    documents = load_ontology_directory(ONTOLOGY)
    merged = merge_ontologies(documents)
    core = next(document for document in documents if document.ontology_id == "core")
    core_labels = set(core.data["node_labels"])
    core_relationships = core.data["relationship_types"].values()
    core_endpoints = {
        label
        for relationship in core_relationships
        for direction in ("from", "to")
        for label in relationship[direction]
    }

    for document in documents:
        if document.path.parent.name != "protocols":
            continue
        module_labels = set(document.data["node_labels"])
        assert module_labels & core_endpoints, document.path.name
        assert module_labels <= set(merged["node_labels"])


def test_required_cross_protocol_relationships_exist() -> None:
    merged = merge_ontologies(load_ontology_directory(ONTOLOGY))
    assert INTERACTION_TYPES <= set(merged["relationship_types"])
