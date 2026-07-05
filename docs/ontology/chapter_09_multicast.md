# Chapter 9 Multicast Ontology

The multicast ontology models receiver membership, distribution trees,
rendezvous-point discovery, reverse-path forwarding, group boundaries,
adjacency health, and application impact. It keeps semantic forwarding state
and evidence references rather than complete multicast route tables.

## Membership and groups

`Receiver` joins a `MulticastGroup`, while `IGMP` signals the corresponding
`ReceiverMembership`. `IGMPVersion` distinguishes behavior such as IGMPv3
source-specific membership. `Source` identifies a producer independently from
the group it sends to.

`MulticastSource` and `MulticastReceiver` are compatibility labels. Seed nodes
carry both the requested and compatibility labels so existing graph consumers
continue to work.

## PIM and distribution trees

`PIMProcess` is specialized with `PIMDenseMode`, `PIMSparseMode`, `PIMSSM`, and
`PIMBidir`. A PIM process builds a `MulticastTree`, specialized as a
`SharedTree` or `SourceTree`.

Sparse mode depends on a `RendezvousPoint`. `RPMapping` connects a group range
to an RP and records whether the mapping is active or missing.
`BootstrapRouter` and `AutoRP` distribute these mappings.

SSM depends on `SourceSpecificJoin`, which points independently to its source
and group. This represents partial failures where one source works and another
does not.

## Reverse-path forwarding

A `MulticastRoute` has an `RPFCheck`. The check depends on a
`UnicastRoutingTable`, resolves through a summarized `UnicastRoute`, and
selects an `RPFInterface`. This makes unicast path changes visible as multicast
failures without copying the complete unicast RIB into Neo4j.

The multicast route also owns an `OIL` and can depend on a `PIMNeighbor`.
These separate incoming-path validation, tree state, adjacency, and outgoing
forwarding.

## Applications, boundaries, and evidence

`MulticastApplication` depends on a group; a `BusinessService` depends on the
application. `IPTVService` and `MarketDataService` are application
specializations.

`MulticastBoundary` filters a group and exposes service risk when a required
group is denied. Evidence links to RP mapping, RPF, membership, PIM-neighbor,
or boundary state, enabling diagnostic separation without storing raw logs.
