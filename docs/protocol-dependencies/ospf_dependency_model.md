# OSPF Dependency Model

## Inter-area reachability

```text
OSPFProcess -> OSPFArea <- CONNECTS - ABR -> BackboneArea
Prefix -> OSPFArea
Prefix -> BusinessService
```

If the ABR loses area-zero connectivity, summary LSAs can be withdrawn and
services depending on non-backbone prefixes lose inter-area reachability.

## Area type and LSA visibility

```text
StubArea - RESTRICTS {action: deny} -> Type 5
ExternalRoute -> ExternalLSA -> Type 5
```

This path explains why an external route is absent without treating the route
as arbitrary configuration text. Default injection is represented separately
and does not imply visibility of every external prefix.

## Adjacency and DR/BDR stability

A broadcast segment elects DR and BDR roles. Reachability depends on a
summarized neighbor, and the neighbor forms over an interface. Repeated
elections or an `exstart` loop can expose an `OSPFAdjacencyRisk` that impacts a
business service.

## Summarization

A summary policy applies at an ABR or ASBR and identifies affected prefixes.
Overbroad summarization can hide a required more-specific route even when the
aggregate remains present.

## OSPF-to-BGP lineage

```text
OSPFProcess -> REDISTRIBUTES_TO -> BGPProcess
BGPRoute -> ORIGINATED_FROM -> OSPFProcess
BGPRoute -> ORIGINATED_FROM -> RedistributionPolicy
RedistributionPolicy -> CONTROLLED_BY -> RouteMap
```

The model distinguishes protocol origin, policy control, and current BGP route
state. Full OSPF and BGP tables remain outside Neo4j.
