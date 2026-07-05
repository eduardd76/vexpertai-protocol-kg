# Network Design Scenarios

## Merger integration

Two organizations operate independent OSPF and EIGRP domains and have
overlapping use of `10.50.0.0/16`. Immediate renumbering is not feasible.

The graph represents:

- the continuity objective and address-overlap constraint;
- a decision to use a controlled BGP policy boundary;
- mutual redistribution as a considered but unselected option;
- route feedback as a critical design risk;
- explicit prefix allowlisting and origin tagging as the interim control;
- evidence from the address and routing inventory;
- a validation check that rejects route feedback before phase exit.

The intent is not to prescribe one universal merger architecture. It makes the
reasoning, temporary policy, risk, blast radius, and exit criteria queryable.

## Global enterprise connectivity

A critical branch payment service needs improved availability and predictable
traffic treatment. Operations can support only a limited policy set.

The graph represents:

- an availability and performance objective;
- a dual MPLS and encrypted-internet transport decision;
- a production VPN and end-to-end QoS dependency;
- increased policy state as a tradeoff;
- asymmetric failover as a high risk;
- a validation check covering reachability, segmentation, and QoS on both
  transports.

Both scenarios use summarized design truth. Detailed probes and telemetry are
referenced through Evidence nodes rather than copied into Neo4j.
