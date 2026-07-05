# Chapter 1 Layer 2 Ontology

This ontology models Layer 2 control, forwarding, protection, gateway
redundancy, and design choices as semantic objects. It does not store complete
MAC tables, every BPDU, or continuous interface counters.

## Forwarding and segmentation

- `EthernetSegment` represents shared Ethernet attachment.
- `BridgeDomain` bounds MAC learning, flooding, and broadcast behavior.
- `VLAN` provides an administratively identified Layer 2 segment.
- `AccessPort` belongs to one data VLAN.
- `Trunk` carries an explicit VLAN set and records summarized unused VLANs.
- `NativeVLAN` captures untagged-frame interpretation at each trunk endpoint.
- `PortChannel`, `LAG`, and `MLAG` model logical aggregation and multichassis
  scope separately from physical member interfaces.

## Spanning tree

`STPInstance` is a first-class control-plane object. A VLAN maps to an instance,
the instance elects an `STPRootBridge`, and it blocks an `STPBlockedPort` when
needed to produce a loop-free forwarding topology. `STPRegion` records common
MST scope.

Root placement is represented as a role hosted by a switch rather than a
property embedded in configuration text. This supports comparison with the
active first-hop gateway location.

## Edge and topology protection

- `PortFast` identifies intended edge behavior.
- `BPDUGuard` protects an access port and can shut it down after a BPDU.
- `RootGuard` protects intended root placement.
- `LoopGuard` protects against transition to forwarding after a
  unidirectional-link failure.
- `BPDUFilter` is explicit because suppressing control messages changes failure
  behavior and should never be inferred from PortFast.

## First-hop redundancy

`HSRPGroup`, `VRRPGroup`, and `GLBPGroup` specialize
`FirstHopRedundancyGroup`. Groups provide a `DefaultGateway` and reference
`VirtualIP` and `VirtualMAC` objects. HSRP and VRRP have active and standby
roles; GLBP has AVG and AVF roles.

The graph expresses a design expectation:

```text
VLAN -> STPInstance -> STPRootBridge -> Switch
VLAN -> HSRPGroup -> FHRPActiveGateway -> Switch
```

When the terminal switches differ, routed traffic can cross an
inter-distribution Layer 2 link before reaching its gateway.

## Design alternatives

The ontology compares `LoopedL2Design`, `LoopFreeL2Design`, and
`RoutedAccessDesign` using suitability context, failure-domain scope, STP
dependency, operational complexity, benefit, and cost. The score in seed data
is scenario-specific; it is not a universal product ranking.
