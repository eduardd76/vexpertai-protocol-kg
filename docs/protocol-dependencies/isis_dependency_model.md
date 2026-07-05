# IS-IS Dependency Model

## Level visibility

```text
Level2Route -> Prefix
Level2Route -> RouteLeakingPolicy -> Prefix
Level2Route -> LEAKED_TO -> Level1
```

A required external prefix remains Level 2-only when the policy does not permit
the route into Level 1. The route, policy decision, affected prefix, and
dependent service remain separate semantic objects.

## Underlay and overlay impact

```text
BusinessService -> MPLSOverlay or SegmentRoutingOverlay
Overlay -> ISISUnderlay -> Reachability -> ISISAdjacency
```

This path lets adjacency loss explain MPLS or SR service impact. It does not
assert that the overlay configuration is itself defective.

## Overload behavior

An overload bit suppresses transit use, not router identity or all local
prefixes. Queries therefore distinguish a reachable overloaded node from a
valid transit node.

## Segment Routing advertisement

```text
SegmentRouting -> SegmentRoutingExtension
SID -> Capability
SID -> ISISTLV -> LSP -> ISISRouter
```

If a Prefix-SID has no `ADVERTISED_BY` relationship, the graph reports a
missing IS-IS advertisement even when general SR capability is present.

## DIS and pseudonode stability

An IS-IS broadcast segment elects a DIS. The DIS creates a pseudonode, which
generates an LSP. DIS churn changes that representation and can destabilize
adjacencies and SPF inputs. The graph stores summarized churn and evidence
pointers rather than every hello or LSP version.
