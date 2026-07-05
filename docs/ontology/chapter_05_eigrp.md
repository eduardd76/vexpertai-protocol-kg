# Chapter 5 EIGRP Ontology

The EIGRP ontology models route selection, loop-free backup, composite metric
lineage, query scope, summarization, unequal-cost forwarding, DMVPN
dependencies, and redistribution risk. It stores important topology decisions,
not the complete topology table.

## Process, identity, and adjacency

An `EIGRPProcess` runs on an `EIGRPRouter`, has an `EIGRPASN`, and can use
`EIGRPNamedMode`. `EIGRPNeighbor` forms over an `EIGRPInterface`.
`PassiveInterface` is explicit because it advertises connected reachability
without forming a neighbor.

## Topology table and convergence

An `EIGRPTopologyTable` contains `SuccessorRoute` and
`FeasibleSuccessorRoute` objects. A successor represents a prefix and is
selected by an `EIGRPMetric`. A feasible successor satisfies a
`FeasibilityCondition` and protects a prefix.

The absence of a feasible successor is meaningful: after successor loss the
route can enter active state and query the modeled `QueryDomain`.

## Composite metric

`EIGRPMetric` references summarized `Delay`, `Bandwidth`, `Reliability`,
`Load`, and `MTU` components. A change can modify one component, allowing an
incident query to identify the metric input changed immediately beforehand.

MTU is retained as route metadata; it is not implied to participate in the
classic K-value calculation.

## Query containment and DMVPN

`StubRouter` reduces a `QueryDomain`. In a `HubAndSpokeTopology`,
`HubSpokeReachability` depends on a `HubRouter`. A `DMVPNOverlay` may depend on
the EIGRP process and hub reachability. This exposes the central dependency and
the benefit of stub spokes.

## Summarization and variance

A `SummaryRoute` hides a `SpecificPrefix`. When the summary discard route
remains installed but the required more-specific is missing, the graph reports
a blackhole risk.

`Variance` enables `UnequalCostLoadBalancing`; feasible-path status remains a
separate prerequisite from the variance multiplier.

## Redistribution

`RedistributionPolicy` is controlled by a `RouteMap`. Bidirectional EIGRP/BGP
redistribution can expose route feedback when origin tagging and filtering are
missing.
