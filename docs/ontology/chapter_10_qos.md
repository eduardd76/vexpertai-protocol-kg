# Chapter 10 QoS Ontology

The QoS ontology models performance intent from application classification
through interface enforcement and observed SLA outcomes. It stores policy
meaning, queue allocation, summarized congestion state, and evidence pointers
rather than packet-level telemetry.

## Classification and marking

`ApplicationTraffic` is specialized as `VoiceTraffic`, `VideoTraffic`,
`CriticalDataTraffic`, or `BestEffortTraffic`. Traffic is `CLASSIFIED_BY` a
`ClassMap`, which belongs to a `QoSPolicy` and assigns a `QoSClass`.

A class is `MARKED_WITH` a `DSCP` or `CoS`. Application traffic separately
points to its required marking, allowing the graph to compare intended and
actual treatment.

## Policy structure and attachment

`QoSPolicy` owns a `PolicyMap`, class maps, and marking, policing, shaping, and
queuing actions. Policy definition and interface attachment are distinct:

- `REQUIRES_QOS_POLICY` records design intent on an interface.
- `APPLIED_TO` records actual enforcement.

This distinction exposes a correctly defined policy that has never been
attached or is attached in the wrong direction.

## Policing, shaping, and queuing

`PolicingPolicy` may drop excess traffic immediately. `ShapingPolicy` smooths
traffic by buffering toward a configured rate. `QueuingPolicy` allocates
`BandwidthGuarantee` objects and uses `InterfaceQueue`, `PriorityQueue`, and
optional `WRED` behavior.

A priority queue protects voice only when its offered load is bounded. Excess
priority allocation is modeled as an `OversubscriptionRisk` because it can
starve classes outside the priority queue.

## SLA and congestion

`SLARequirement` is specialized into latency, jitter, and loss requirements
and maps to a QoS class. A business service depends directly on these
requirements.

`CongestionEvent` affects an interface queue and can cause an `SLAViolation`.
Evidence supports the event, queue, or violation, giving a traceable
correlation without loading raw time-series samples into Neo4j.

## Design necessity

`QoSDesignAssessment` evaluates measured `WANLink` capacity and utilization.
QoS policy may be unnecessary when there is no bandwidth constraint or
differentiated SLA. The graph records this as an explicit design conclusion,
not an assumption that every WAN link requires complex QoS.
