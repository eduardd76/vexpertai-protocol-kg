# EIGRP Dependency Model

## Successor and feasible successor

```text
Prefix -> LEARNED_BY -> EIGRPProcess
SuccessorRoute -> Prefix
SuccessorRoute -> EIGRPMetric -> metric components
FeasibleSuccessorRoute -> PROTECTS -> Prefix
```

A prefix without feasible-successor protection depends on DUAL queries and
neighbor responses after successor failure, increasing convergence time.

## Query-domain containment

Stub spokes remain members of the topology but reduce the routers queried for
lost reachability. The graph distinguishes total query-domain membership from
effective query targets.

## Summary blackhole

```text
SummaryRoute {discard_route: true} -> HIDES -> SpecificPrefix
SpecificPrefix -> BusinessService
```

If the required specific disappears while the summary remains, traffic can
follow the discard route.

## Hub and DMVPN dependency

```text
BusinessService -> HubSpokeReachability -> HubRouter
BusinessService -> DMVPNOverlay
DMVPNOverlay -> EIGRPProcess and HubSpokeReachability
```

This path explains spoke service impact without placing full NHRP or EIGRP
tables in Neo4j.

## Redistribution feedback

An EIGRP process redistributes to BGP through a policy controlled by a
route-map. Missing route tagging or origin filtering exposes a feedback risk.
The risk and any mitigation control remain separately queryable.
