# BGP Dependency Model

## Policy withdrawal

```text
Change -> RoutePolicy -> BGPRoute -> Prefix -> ServiceReachability
```

A policy change can remove a prefix even when the peer session remains
established. The model therefore separates session health from route
visibility and records the prefix-list or community match that produced the
decision.

## Recursive next-hop reachability

```text
BGPRoute -> BGPNextHop -> IGPReachability -> underlay state
```

A learned route is unusable when its next hop cannot resolve. The safe
diagnostic order is to validate IGP or underlay reachability before modifying
BGP policy.

## Route reflection

```text
RouteReflector -> BGPRoute -> RouteReflectorClient
```

The reflection path identifies which prefixes and clients share a failure
domain. Multiple reflectors can be represented against the same route to
validate control-plane redundancy.

## Exit selection

Hot-potato selection depends on IGP distance to acceptable exits. Cold-potato
selection depends on explicit policy preference. `BGPBestPathDecision` stores
the observed winning reason, and `SelectedBGPPath` records the forwarding exit.
This makes an IGP cost change traceable to a BGP path change without treating
the protocols as independent.

## Protection and blackholing

`BGPPIC` protects a next-hop failure by pointing to a prepared alternate.
Community-triggered `BlackholeRoute` objects intentionally discard traffic,
but expose critical risk when they match a live service prefix.

## BGP-free core

A `BGPFreeCore` design requires edge-to-edge IGP and label reachability.
Service prefixes stay at the edges, while the graph retains the transport
dependency needed to explain forwarding failure.
