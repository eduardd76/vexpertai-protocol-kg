# Ontology

The ontology describes a small set of operational objects and the meaningful
connections between them. Every seeded node has a stable `id`, a human-readable
`name`, and a `dataset` marker used for safe demo reloads.

## Infrastructure and topology

- **Site** contains the physical operating location.
- **Device** is a managed network element.
- **Interface** is a physical or logical device interface.
- **Link** / **PhysicalLink** represents a physical connection between
  interfaces.
- **VRF**, **VLAN**, **VNI**, and **Prefix** describe network segmentation and
  reachability.

## Protocol and policy

- **OSPFProcess** and **BGPProcess** are protocol instances run by devices.
- **BGPNeighbor** represents a BGP peering endpoint and session state.
- **EVPNControlPlane**, **VXLANOverlay**, and **VTEP** represent overlay control,
  data-plane encapsulation, and tunnel endpoints.
- **UnderlayRouting** summarizes the reachability service on which VTEPs depend.
- **RedistributionRule** represents movement of reachability between protocol
  domains.
- **RouteMap**, **PrefixList**, and **Community** represent policy controls and
  attributes applied during redistribution.
- **Route** captures summarized lineage and current disposition for an important
  route, not every entry in a routing table.

## Service and operations

- **Application** is an application workload.
- **BusinessService** is a customer- or business-facing capability.
- **Alert** and **Symptom** capture observed failure signals.
- **Incident** groups alerts and records service impact.
- **Change** identifies a policy or infrastructure modification.
- **Evidence** points to supporting telemetry or configuration-diff facts.
- **Recommendation** is a safe next action supported by evidence.
- **ValidationRun** records a test that should validate a recommendation.

## Modeling principle

Relationships carry meaning such as `DEPENDS_ON`, `REDISTRIBUTES_TO`,
`CONTROLLED_BY`, `MODIFIES`, and `IMPACTS`. Raw telemetry remains external; an
Evidence node stores a concise observation and a source pointer.
