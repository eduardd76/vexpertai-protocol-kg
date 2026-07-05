# Chapter 3 OSPF Ontology

The OSPF ontology models hierarchy, adjacency, LSA lineage, path calculation,
local repair, policy boundaries, and business impact. It stores summarized
control-plane truth rather than complete link-state databases.

## Process and area hierarchy

An `OSPFProcess` runs on an `OSPFRouter` and contains `OSPFArea` objects. Area
subtypes make propagation behavior explicit:

- `BackboneArea`
- `NormalArea`
- `StubArea`
- `TotallyStubbyArea`
- `NSSAArea`
- `TotallyNSSAArea`

An `ABR` connects a non-backbone area to area zero. Inter-area service impact
can therefore be found by traversing from an ABR through its areas, originating
prefixes, and supported services.

## Interfaces and adjacency

An area contains `OSPFInterface` objects. `OSPFNeighbor` forms over an
interface, whose `OSPFNetworkType` explains adjacency and election behavior.
On a `BroadcastSegment`, separate `DR` and `BDR` role nodes resolve to their
hosting routers.

Adjacency risk is modeled independently from raw hello packets. A summarized
neighbor state and Evidence pointer are sufficient for graph reasoning.

## LSA lineage

All concrete LSA classes also carry the generic `LSA` label:

- `RouterLSA`
- `NetworkLSA`
- `SummaryLSA`
- `ExternalLSA`
- `NSSALSA`
- `OpaqueLSA`

A prefix is `ADVERTISED_BY` an LSA, the LSA has an `LSAType`, and an installed
route `DEPENDS_ON` that LSA. This provides explainable lineage without placing
the full LSDB in Neo4j.

## Area restrictions and external routes

Area subtypes `RESTRICT` LSA types. An `ASBR` redistributes an
`ExternalRoute`, represented by an `ExternalLSA` or `NSSALSA`. A required type
5 route linked to a stub-area deny restriction produces a deterministic
visibility explanation.

## Convergence and repair

`OSPFConvergence` depends on `SPFComputation`. Interface and route cost are
modeled through `OSPFMetric` and `Cost`. Important reachability can be protected
with `LFA` and `FastReroute` objects.

## Policy boundaries

`SummarizationPolicy` applies on an ABR or ASBR and points to affected prefixes.
`RedistributionPolicy` governs route movement and is controlled by a
`RouteMap`. `BGPRoute` lineage can therefore trace back through the policy to an
OSPF process and source route.
