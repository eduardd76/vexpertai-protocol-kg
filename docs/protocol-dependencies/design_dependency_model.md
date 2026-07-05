# Design Dependency Model

The graph separates four connected forms of reasoning.

## Operational dependency

Protocol and forwarding objects describe what must work for a service to
operate. Examples include VXLAN depending on EVPN and VTEP reachability,
multicast RPF depending on unicast underlay routing, or an MPLS LSP depending on
its IGP and label-distribution domain.

## Policy and lineage

Policy objects explain why reachability is accepted, rejected, transformed, or
exported. Redistribution rules, route-maps, prefix-lists, communities, BGP
policies, route targets, and QoS class mappings remain first-class objects.

## Design causality

A `DesignDomain` has objectives and constraints. A `DesignDecision` considers
options, selects one, records tradeoffs, and supports objectives. Decisions and
options can introduce risks that impact services or failure domains.

```text
Objective <- SUPPORTS - Decision - SELECTS -> Option
                         |                    |
                         +-- HAS_TRADEOFF --> Tradeoff
                         +-- INTRODUCES_RISK -> Risk
```

## Evidence and validation

Decisions can be based on evidence pointers. Risks are mitigated by a design,
recommendation, or validation check and are independently linked to validation.
This preserves a distinction between a plausible design choice and a tested
one.

Validation queries detect missing policy, unbounded failure scope, absent
mitigation, or incomplete requirement traceability. They are design assertions,
not high-volume telemetry queries.
