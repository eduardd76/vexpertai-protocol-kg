# Multicast Dependency Model

## Receiver-to-source forwarding

```text
Receiver -> MulticastGroup <- Source
    |              |
   IGMP       MulticastRoute -> OIL
                         |
                      RPFCheck
```

A receiver join proves requested membership, not traffic delivery. Forwarding
also requires a built multicast tree, valid RPF state, and a populated outgoing
interface list.

## Sparse-mode RP dependency

```text
PIMSparseMode -> RPMapping -> RendezvousPoint
```

A missing mapping prevents shared-tree construction even when the RP itself is
healthy. The model separates RP availability from group-to-RP mapping
distribution by BSR or Auto-RP.

`AnycastRP` adds a second dependency on `MSDP` or equivalent `SharedState`.
The shared address alone does not guarantee that source-active state is
available at every RP node.

## RPF dependency on unicast routing

```text
MulticastRoute -> RPFCheck -> UnicastRoutingTable
                                 |
                             UnicastRoute
                                 |
                            RPFInterface
```

RPF failure is therefore traced to the unicast route and selected incoming
interface before changing IGMP, PIM mode, or application settings.

## Source-specific multicast

```text
PIMSSM -> SourceSpecificJoin -> Source
                    |
              MulticastGroup
```

Each `(S,G)` membership is independent. One source may forward while another
fails because its IGMPv3 source membership is absent.

## Service impact

```text
BusinessService -> MulticastApplication -> MulticastGroup
                                              |
                                      MulticastRoute
                                              |
                                         PIMNeighbor
```

This path translates adjacency, RPF, RP, and boundary failures into
application and business impact while leaving raw counters and packet captures
in their operational stores.
