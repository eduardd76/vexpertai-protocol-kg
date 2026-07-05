from pathlib import Path

from src.ontology_loader import load_ontology_directory, merge_ontologies
from src.validation import REQUIRED_NODE_LABELS, REQUIRED_RELATIONSHIP_TYPES


ROOT = Path(__file__).resolve().parents[1]

CHAPTER_01_LABELS = {
    "EthernetSegment",
    "Switch",
    "BridgeDomain",
    "VLAN",
    "Trunk",
    "AccessPort",
    "PortChannel",
    "LAG",
    "MLAG",
    "STPInstance",
    "STPRegion",
    "STPRootBridge",
    "STPBlockedPort",
    "BPDU",
    "PortFast",
    "RootGuard",
    "LoopGuard",
    "BPDUGuard",
    "BPDUFilter",
    "VTPDomain",
    "NativeVLAN",
    "FirstHopRedundancyGroup",
    "HSRPGroup",
    "VRRPGroup",
    "GLBPGroup",
    "VirtualIP",
    "VirtualMAC",
    "DefaultGateway",
    "FHRPActiveGateway",
    "FHRPStandbyGateway",
    "ActiveVirtualGateway",
    "ActiveVirtualForwarder",
    "STPRootPlacement",
    "VLANHoppingRisk",
    "UnidirectionalLinkFailure",
    "AccessLayer",
    "DistributionLayer",
    "LoopFreeL2Design",
    "LoopedL2Design",
    "RoutedAccessDesign",
}

CHAPTER_01_RELATIONSHIPS = {
    "CARRIED_BY",
    "MAPPED_TO",
    "ELECTS",
    "BLOCKS",
    "BELONGS_TO",
    "AGGREGATES",
    "SPANS",
    "PROVIDES",
    "HAS_ACTIVE_GATEWAY",
    "HAS_STANDBY_GATEWAY",
    "HAS_AVG",
    "HAS_AVF",
    "SHOULD_ALIGN_WITH",
    "MAY_ENABLE",
    "PROTECTS",
}

CHAPTER_02_LABELS = {
    "DesignRequirement",
    "BusinessRequirement",
    "TechnicalRequirement",
    "Constraint",
    "Assumption",
    "Risk",
    "Tradeoff",
    "DesignOption",
    "DesignDecision",
    "MigrationPlan",
    "MigrationStep",
    "RollbackPlan",
    "HighAvailabilityRequirement",
    "ScalabilityRequirement",
    "ConvergenceRequirement",
    "SecurityRequirement",
    "OperationalRequirement",
    "MonitoringRequirement",
    "CostConstraint",
    "SkillConstraint",
    "HardwareConstraint",
    "TechnologyReplacement",
    "TechnologyAddition",
    "MergerDesign",
    "DivestmentDesign",
    "BrownfieldNetwork",
    "GreenfieldNetwork",
}

CHAPTER_02_RELATIONSHIPS = {
    "SATISFIES",
    "VIOLATES",
    "CHOOSES",
    "CREATES_RISK",
    "DEPENDS_ON",
    "IMPACTS",
    "REQUIRES",
    "HAS_TRADEOFF",
    "MITIGATED_BY",
    "PRIORITIZED_BY",
    "COVERS",
}

CHAPTER_03_LABELS = {
    "OSPFProcess",
    "OSPFArea",
    "BackboneArea",
    "NormalArea",
    "StubArea",
    "TotallyStubbyArea",
    "NSSAArea",
    "TotallyNSSAArea",
    "OSPFRouter",
    "OSPFNeighbor",
    "DR",
    "BDR",
    "OSPFInterface",
    "OSPFNetworkType",
    "RouterLSA",
    "NetworkLSA",
    "SummaryLSA",
    "ASBR",
    "ABR",
    "ExternalLSA",
    "NSSALSA",
    "OpaqueLSA",
    "OSPFMetric",
    "Cost",
    "SummarizationPolicy",
    "RedistributionPolicy",
    "DefaultRouteInjection",
    "SPFComputation",
    "LFA",
    "FastReroute",
    "OSPFAdjacencyRisk",
}

CHAPTER_03_RELATIONSHIPS = {
    "RUNS_ON",
    "CONTAINS",
    "FORMED_OVER",
    "ELECTS",
    "CONNECTS",
    "REDISTRIBUTES",
    "RESTRICTS",
    "APPLIED_ON",
    "ADVERTISED_BY",
    "DEPENDS_ON",
    "CONTROLLED_BY",
}

CHAPTER_04_LABELS = {
    "ISISProcess",
    "ISISLevel",
    "Level1",
    "Level2",
    "Level1Level2Router",
    "ISISArea",
    "NET",
    "SystemID",
    "ISISAdjacency",
    "ISISInterface",
    "DIS",
    "Pseudonode",
    "LSP",
    "TLV",
    "MetricStyle",
    "NarrowMetric",
    "WideMetric",
    "OverloadBit",
    "RouteLeakingPolicy",
    "SummarizationPolicy",
    "IPv6Topology",
    "MultiTopologyISIS",
    "SingleTopologyISIS",
    "SegmentRoutingExtension",
    "PrefixSID",
    "NodeSID",
    "AdjacencySID",
}

CHAPTER_04_RELATIONSHIPS = {
    "RUNS_ON",
    "HAS_LEVEL",
    "FORMED_OVER",
    "CONTAINS",
    "GENERATED_BY",
    "ADVERTISES",
    "LEAKED_TO",
    "LEAKED_BY",
    "SUPPRESSES",
    "DEPENDS_ON",
    "ADVERTISED_BY",
}

CHAPTER_05_LABELS = {
    "EIGRPProcess",
    "EIGRPASN",
    "EIGRPNamedMode",
    "EIGRPNeighbor",
    "EIGRPInterface",
    "EIGRPTopologyTable",
    "SuccessorRoute",
    "FeasibleSuccessorRoute",
    "FeasibilityCondition",
    "QueryDomain",
    "StubRouter",
    "SummaryRoute",
    "Variance",
    "UnequalCostLoadBalancing",
    "PassiveInterface",
    "EIGRPMetric",
    "Delay",
    "Bandwidth",
    "Reliability",
    "Load",
    "MTU",
    "RedistributionPolicy",
    "HubAndSpokeTopology",
    "DMVPNDependency",
}

CHAPTER_05_RELATIONSHIPS = {
    "RUNS_ON",
    "FORMED_OVER",
    "LEARNED_BY",
    "SELECTED_BY",
    "PROTECTS",
    "REDUCES",
    "HIDES",
    "ENABLES",
    "CONTROLLED_BY",
    "DEPENDS_ON",
    "MAY_DEPEND_ON",
}

CHAPTER_06_LABELS = {
    "VPNService",
    "SiteToSiteVPN",
    "RemoteAccessVPN",
    "MPLSL3VPN",
    "MPLSL2VPN",
    "DMVPN",
    "GRE",
    "IPsecTunnel",
    "IKEPolicy",
    "CryptoMap",
    "TunnelInterface",
    "VRF",
    "RouteTarget",
    "RouteDistinguisher",
    "CustomerEdge",
    "ProviderEdge",
    "Hub",
    "Spoke",
    "OverlayTunnel",
    "UnderlayTransport",
    "EncryptionDomain",
    "SplitTunnelPolicy",
    "NATTraversal",
    "TunnelHealth",
    "VPNSLA",
    "VPNFailoverPolicy",
}

CHAPTER_06_RELATIONSHIPS = {
    "CONNECTS",
    "DEPENDS_ON",
    "PROTECTS",
    "USES",
    "IMPORTED_BY",
}

CHAPTER_08_LABELS = {
    "BGPProcess",
    "AutonomousSystem",
    "BGPNeighbor",
    "IBGPSession",
    "EBGPSession",
    "RouteReflector",
    "RouteReflectorClient",
    "Confederation",
    "BGPUpdate",
    "NLRI",
    "BGPRoute",
    "PathAttribute",
    "ASPath",
    "LocalPreference",
    "MED",
    "NextHop",
    "Community",
    "ExtendedCommunity",
    "LargeCommunity",
    "RoutePolicy",
    "PrefixList",
    "ASPathList",
    "CommunityList",
    "BGPBestPathDecision",
    "AddPath",
    "BGPFreeCore",
    "BGPPIC",
    "BGPBestExternal",
    "HotPotatoRouting",
    "ColdPotatoRouting",
    "InternetEdge",
    "PeeringPolicy",
    "TransitProvider",
    "CustomerRoute",
    "BlackholeRoute",
}

CHAPTER_08_RELATIONSHIPS = {
    "RUNS_ON",
    "BELONGS_TO",
    "ADVERTISED_TO",
    "SELECTED_BY",
    "FILTERS",
    "MODIFIES_ROUTE",
    "MATCHES",
    "INFLUENCES",
    "REFLECTS",
    "PROTECTS",
    "DEPENDS_ON",
    "REQUIRES",
}

CHAPTER_09_LABELS = {
    "MulticastDomain",
    "MulticastGroup",
    "Source",
    "Receiver",
    "IGMP",
    "IGMPVersion",
    "PIMProcess",
    "PIMDenseMode",
    "PIMSparseMode",
    "PIMSSM",
    "PIMBidir",
    "RendezvousPoint",
    "RPMapping",
    "BootstrapRouter",
    "AutoRP",
    "SharedTree",
    "SourceTree",
    "RPFCheck",
    "RPFInterface",
    "MulticastRoute",
    "OIL",
    "MulticastBoundary",
    "AnycastRP",
    "MSDP",
    "MulticastApplication",
    "IPTVService",
    "MarketDataService",
}

CHAPTER_09_RELATIONSHIPS = {
    "JOINS",
    "SIGNALS",
    "BUILDS",
    "DEPENDS_ON",
    "FILTERS",
}

CHAPTER_10_LABELS = {
    "QoSPolicy",
    "ClassMap",
    "PolicyMap",
    "QoSClass",
    "TrafficClass",
    "DSCP",
    "CoS",
    "MarkingPolicy",
    "PolicingPolicy",
    "ShapingPolicy",
    "QueuingPolicy",
    "PriorityQueue",
    "BandwidthGuarantee",
    "WRED",
    "CongestionEvent",
    "InterfaceQueue",
    "ApplicationTraffic",
    "VoiceTraffic",
    "VideoTraffic",
    "CriticalDataTraffic",
    "BestEffortTraffic",
    "SLARequirement",
    "LatencyRequirement",
    "JitterRequirement",
    "LossRequirement",
    "WANLink",
    "OversubscriptionRisk",
}

CHAPTER_10_RELATIONSHIPS = {
    "CLASSIFIED_BY",
    "BELONGS_TO",
    "APPLIED_TO",
    "MARKED_WITH",
    "ALLOCATES",
    "PROTECTS",
    "MAY_DROP",
    "SMOOTHS",
    "MAPS_TO",
    "AFFECTS",
    "DEPENDS_ON",
}

CHAPTER_11_LABELS = {
    "MPLSDomain",
    "LabelSwitchRouter",
    "ProviderEdge",
    "ProviderRouter",
    "CustomerEdge",
    "LDP",
    "RSVPTE",
    "SegmentRoutingMPLS",
    "Label",
    "LabelBinding",
    "FEC",
    "LSP",
    "MPLSForwardingTable",
    "LFIB",
    "MPLSL3VPN",
    "MPLSL2VPN",
    "VPWS",
    "VPLS",
    "Pseudowire",
    "VRF",
    "RouteDistinguisher",
    "RouteTarget",
    "MPBGPVPNv4",
    "MPBGPVPNv6",
    "TrafficEngineeringTunnel",
    "FastReroute",
    "LDPIGPSynchronization",
    "LDPSessionProtection",
    "PenultimateHopPopping",
    "TransportUnderlay",
    "ServiceOverlay",
}

CHAPTER_11_RELATIONSHIPS = {
    "DEPENDS_ON",
    "CREATED_BY",
    "IMPORTS_VPN_ROUTE",
    "PREVENTS",
    "PROTECTS",
}

GLOBAL_LABELS = {
    "Protocol",
    "Policy",
    "RoutingProtocolInstance",
    "OverlayService",
    "ControlPlaneDependency",
    "DataPlaneDependency",
    "ServiceOwner",
    "UserGroup",
}

GLOBAL_RELATIONSHIPS = {
    "HAS_CONTROL_PLANE_DEPENDENCY",
    "HAS_DATA_PLANE_DEPENDENCY",
    "DEPENDS_ON_COMPONENT",
    "SUPPORTS_LAYER",
    "OWNED_BY",
    "HAS_SLA",
    "EVIDENCES",
}


def merged_ontology() -> dict:
    documents = load_ontology_directory(ROOT / "ontology")
    return merge_ontologies(documents)


def test_required_labels_and_relationships_exist() -> None:
    ontology = merged_ontology()

    assert REQUIRED_NODE_LABELS <= set(ontology["node_labels"])
    assert REQUIRED_RELATIONSHIP_TYPES <= set(ontology["relationship_types"])
    assert CHAPTER_01_LABELS <= set(ontology["node_labels"])
    assert CHAPTER_01_RELATIONSHIPS <= set(ontology["relationship_types"])
    assert CHAPTER_02_LABELS <= set(ontology["node_labels"])
    assert CHAPTER_02_RELATIONSHIPS <= set(ontology["relationship_types"])
    assert CHAPTER_03_LABELS <= set(ontology["node_labels"])
    assert CHAPTER_03_RELATIONSHIPS <= set(ontology["relationship_types"])
    assert CHAPTER_04_LABELS <= set(ontology["node_labels"])
    assert CHAPTER_04_RELATIONSHIPS <= set(ontology["relationship_types"])
    assert CHAPTER_05_LABELS <= set(ontology["node_labels"])
    assert CHAPTER_05_RELATIONSHIPS <= set(ontology["relationship_types"])
    assert CHAPTER_06_LABELS <= set(ontology["node_labels"])
    assert CHAPTER_06_RELATIONSHIPS <= set(ontology["relationship_types"])
    assert CHAPTER_08_LABELS <= set(ontology["node_labels"])
    assert CHAPTER_08_RELATIONSHIPS <= set(ontology["relationship_types"])
    assert CHAPTER_09_LABELS <= set(ontology["node_labels"])
    assert CHAPTER_09_RELATIONSHIPS <= set(ontology["relationship_types"])
    assert CHAPTER_10_LABELS <= set(ontology["node_labels"])
    assert CHAPTER_10_RELATIONSHIPS <= set(ontology["relationship_types"])
    assert CHAPTER_11_LABELS <= set(ontology["node_labels"])
    assert CHAPTER_11_RELATIONSHIPS <= set(ontology["relationship_types"])
    assert GLOBAL_LABELS <= set(ontology["node_labels"])
    assert GLOBAL_RELATIONSHIPS <= set(ontology["relationship_types"])


def test_dependency_rules_use_declared_endpoints() -> None:
    ontology = merged_ontology()
    relationships = ontology["relationship_types"]

    for rule in ontology["dependency_rules"]:
        definition = relationships[rule["relationship"]]
        assert rule["source"] in definition["from"], rule["id"]
        assert set(rule["target"]) <= set(definition["to"]), rule["id"]


def test_every_relationship_endpoint_is_a_known_label() -> None:
    ontology = merged_ontology()
    labels = set(ontology["node_labels"])

    for name, definition in ontology["relationship_types"].items():
        assert set(definition["from"]) <= labels, name
        assert set(definition["to"]) <= labels, name
