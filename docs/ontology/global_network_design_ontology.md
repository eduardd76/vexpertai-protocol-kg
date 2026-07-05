# Global Network Design Ontology

The global ontology is the canonical semantic layer above the chapter domains.
It does not replace protocol detail. It gives shared concepts one owner and
makes cross-domain paths queryable without knowing every vendor feature name.

## Canonical concepts

`core.yaml` owns concepts reused across domains:

- infrastructure: `Device`, `Interface`, `Site`
- reachability: `Prefix`, `Route`
- control and intent: `Protocol`, `RoutingProtocolInstance`, `Policy`
- service: `Application`, `BusinessService`, `OverlayService`
- governance: `Requirement`, `Constraint`, `DesignDecision`
- assurance: `Risk`, `Evidence`, `Recommendation`, `ValidationRun`

Each node label is defined in one ontology file. Domain files can add
properties, constraints, relationships, and rules to the canonical label
without redefining it.

## Specialization

Neo4j nodes use multiple labels for practical inheritance:

```text
Protocol
└── RoutingProtocolInstance
    ├── OSPFProcess
    ├── ISISProcess
    ├── EIGRPProcess
    └── BGPProcess

OverlayService
├── VPNService / DMVPN
├── MPLSL3VPN / MPLSL2VPN
├── VXLANOverlay
├── SegmentRoutingPolicy
└── CarrierEthernetService

Policy
├── RouteMap / PrefixList / RoutePolicy
├── FirewallRule / SecurityPolicy
└── QoSPolicy
```

Chapter-specific risk and requirement nodes receive the generic `Risk` and
`Requirement` labels. This retains detailed semantics while enabling global
queries.

## Reusable dependency patterns

Two reified dependency nodes avoid inventing a new relationship type for every
technology:

- `ControlPlaneDependency` represents routing, signaling, discovery, or policy
  state.
- `DataPlaneDependency` represents interface, forwarding, label, tunnel, or
  queue state.

An overlay links to these nodes with `HAS_CONTROL_PLANE_DEPENDENCY` and
`HAS_DATA_PLANE_DEPENDENCY`. Each dependency resolves to concrete objects using
`DEPENDS_ON_COMPONENT`. Dependency nodes carry status and can be supported by
evidence.

`SUPPORTS_LAYER` provides a compact end-to-end chain from physical access
through protocols and policies to applications and business services. Detailed
chapter relationships remain available for root-cause analysis.

## Data boundary

The graph stores semantic objects, summarized state, dependency, policy
lineage, risk, evidence pointers, ownership, and validation intent. Full route
tables, telemetry samples, logs, and packet captures remain in their source
systems.
