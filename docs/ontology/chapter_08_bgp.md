# Chapter 8 BGP Ontology

The BGP ontology represents path propagation, policy, recursive reachability,
best-path selection, reflection, edge behavior, and service impact. It stores
route meaning and summarized state, not a full BGP routing table.

## Routing domains and sessions

`BGPProcess` runs on a `Device` and belongs to an `AutonomousSystem` or
`Confederation`. A process owns `IBGPSession` and `EBGPSession` objects whose
peer endpoints are `BGPNeighbor` nodes. `InternetEdge`, `TransitProvider`, and
`PeeringPolicy` capture the design and commercial boundary around eBGP.

## Updates, routes, and attributes

A `BGPUpdate` carries `NLRI` and path attributes. `BGPRoute` represents the
resulting semantic route and points to a `Prefix` or `NLRI`. Attributes remain
first-class objects:

- `ASPath`, `LocalPreference`, and `MED` participate in selection.
- `NextHop` and `BGPNextHop` represent forwarding recursion.
- `Community`, `ExtendedCommunity`, and `LargeCommunity` drive policy.

`BGPBestPathDecision` records why a route won. This avoids inferring intent
from raw configuration or a route-table snapshot.

## Policy and propagation

`RoutePolicy` filters or modifies a BGP route. `PrefixList`, `ASPathList`, and
`CommunityList` capture reusable match criteria. A community can influence a
policy or trigger a `BlackholeRoute`.

`RouteReflector` reflects routes to `RouteReflectorClient` nodes through an
explicit cluster. This exposes the prefixes and clients dependent on each
reflection function.

## Resiliency and exit selection

`BGPPIC` represents precomputed next-hop protection, while `AddPath` and
`BGPBestExternal` capture additional-path capabilities. `HotPotatoRouting`
depends on the IGP metric to an exit; `ColdPotatoRouting` depends on an
explicit policy preference.

`BGPFreeCore` requires edge-to-edge transport reachability. Core nodes do not
need service BGP routes, but BGP next hops still must resolve through the
underlay.

## Service and evidence boundary

`ServiceReachability` links a business service to a selected path or summarized
BGP route. `BGPPathRisk` records policy, reflection, recursion, or blackhole
risk. Raw updates, RIB history, packet captures, and telemetry remain external;
the graph keeps state summaries and evidence pointers.
