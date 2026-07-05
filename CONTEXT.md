# vExpertAI Protocol-Aware Knowledge Graph Context

We are building a private semantic operating model for vExpertAI, an AI platform for network and security operations.

The system should model:
- Taxonomy
- Ontology
- Semantic mapping
- Knowledge graph
- AI agents
- Digital twin validation
- Safe remediation

The key idea:
vExpertAI should not only connect to tools. It should create a semantic model of the enterprise network/security environment so AI agents can reason over incidents, changes, risk, and remediation.

Core use cases:
1. Alert-to-action
2. Root cause analysis
3. Change impact analysis
4. Security exposure reasoning
5. Overlay/underlay troubleshooting
6. Route redistribution analysis
7. Digital twin generation
8. Agent routing and governance

Important thesis:
A normal RAG system retrieves documents.
vExpertAI should reason over connected operational truth.

The KG must model protocols as first-class semantic objects, not just config text.

Important protocol relationships:
- OSPF to BGP redistribution
- Static to BGP redistribution
- EVPN overlay dependency on underlay reachability
- VXLAN dependency on VTEP loopbacks
- BGP EVPN dependency on route reflectors
- Prefix dependency on route-map / prefix-list / community
- Business service dependency on VRF / VNI / route / firewall rule

Required ontology objects:
- Device
- Interface
- Link
- Site
- VRF
- VLAN
- Prefix
- Route
- RoutingProtocolInstance
- BGPProcess
- BGPNeighbor
- OSPFProcess
- EVPNControlPlane
- VXLANOverlay
- VTEP
- VNI
- RouteMap
- PrefixList
- Community
- RedistributionRule
- FirewallRule
- SecurityZone
- TrafficFlow
- Application
- BusinessService
- Alert
- Incident
- Change
- Evidence
- Recommendation
- Remediation
- ValidationRun
- Agent
- Tool
- Runbook

Required relationships:
- Device HAS_INTERFACE Interface
- Interface CONNECTED_TO Interface
- Device LOCATED_IN Site
- Device RUNS RoutingProtocolInstance
- BGPProcess HAS_NEIGHBOR BGPNeighbor
- OSPFProcess ADVERTISES Prefix
- BGPProcess ADVERTISES Prefix
- OSPFProcess REDISTRIBUTES_TO BGPProcess
- RedistributionRule CONTROLLED_BY RouteMap
- RouteMap REFERENCES PrefixList
- RouteMap SETS Community
- Prefix SUPPORTS BusinessService
- VXLANOverlay DEPENDS_ON EVPNControlPlane
- EVPNControlPlane DEPENDS_ON VTEPReachability
- VTEPReachability DEPENDS_ON UnderlayRouting
- UnderlayRouting DEPENDS_ON PhysicalLink
- Alert OBSERVED_ON Device
- Alert INDICATES Symptom
- Incident CONTAINS Alert
- Incident IMPACTS BusinessService
- Change MODIFIES RouteMap
- Change AFFECTS BusinessService
- Remediation REQUIRES ValidationRun

Critical design rule:
Do not dump every route, MAC, log, flow, and telemetry point into the KG.
The KG stores meaning, dependency, lineage, summarized state, and pointers to evidence.
Full raw telemetry should live in time-series DB, data lake, or logs.

MVP goal:
Build a protocol-aware KG demo for:
1. VXLAN/EVPN overlay-underlay RCA
2. OSPF-to-BGP redistribution change impact analysis

Expected output:
- Python project
- Neo4j schema
- Seed data
- Cypher queries
- FastAPI API
- Simple demo scripts
- Optional LangGraph agent later
