# Layer 2, STP, and FHRP Dependencies

## STP and gateway alignment

STP determines which Layer 2 path forwards toward the root. FHRP determines
which distribution switch routes endpoint traffic. If the roles are on
different switches, traffic from the access layer can traverse the
inter-distribution link before routing. The graph records both elected roles,
their host switches, the expected alignment, the resulting risk, and affected
business services.

## Blocked path reasoning

A blocked port is linked to the exact `STPInstance` that selected its state.
The port stores a summarized reason such as an alternate path to the root.
Evidence and detailed BPDU histories remain in telemetry systems.

## BPDU guard failure path

```text
BPDU -> RECEIVED_ON -> AccessPort
BPDU -> TRIGGERS -> BPDUGuard -> SHUTS_DOWN -> AccessPort
BPDUGuard -> PROTECTS -> AccessPort
```

The shutdown is a protective outcome: it limits a possible loop but can still
impact the endpoint's business service. Both protection and impact should be
visible during incident analysis.

## Native VLAN mismatch

Each trunk endpoint has its own `NativeVLAN`. A `MISMATCHED_WITH` relationship
captures inconsistent untagged-frame interpretation. The mismatch
`MAY_ENABLE` a `VLANHoppingRisk`, which can then be connected to service impact
and validation work.

## Guard responsibilities

- BPDU guard protects edge ports from unexpected switching.
- Root guard protects the intended STP root location.
- Loop guard protects alternate or root ports when BPDUs disappear because of
  a unidirectional failure.
- BPDU filter changes control-message visibility and is modeled separately; it
  is not treated as equivalent protection.

## Access design choice

Looped Layer 2 retains physical redundancy but depends heavily on STP state.
Loop-free Layer 2 uses a single logical topology, often with multichassis
aggregation. Routed access reduces Layer 2 failure scope and removes STP from
uplink convergence, but constrains VLAN extension. Suitability depends on the
service requirement and operational constraints.
