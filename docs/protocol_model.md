# Protocol Model

## Overlay and underlay

`vxlan-prod` depends on the `evpn-fabric` control plane. EVPN depends on the leaf
VTEPs, and each VTEP depends on summarized underlay reachability. Underlay
reachability depends on physical links, whose endpoint interfaces contain
current summarized health.

This path lets a query move from an overlay alert to a degraded interface
without asserting that the overlay configuration itself is wrong:

```text
VXLANOverlay -> EVPNControlPlane -> VTEP -> UnderlayRouting
             -> PhysicalLink -> Interface
```

The spines run BGP EVPN route-reflector processes. Their BGP neighbors represent
the leaf sessions, making route-reflector behavior explicit rather than an
unstructured configuration fact.

## EVPN, VXLAN, VNI, and VRF

The overlay carries VNI `10010`, the VNI maps to VRF `PROD`, and Payment-App
depends on all three. The service dependency allows an overlay symptom to be
translated into business impact.

## VTEP reachability

A VTEP's loopback is modeled as an address property, while `DEPENDS_ON` links it
to the underlay routing instance. The MVP stores the dependency and current
state, not a full RIB or every reachability probe.

## OSPF-to-BGP redistribution

OSPF process `100` advertises `10.20.30.0/24` and redistributes into BGP AS
`65001`. A separate `RedistributionRule` gives the redistribution policy its own
identity and connects source protocol, target protocol, controlled prefix, and
route-map.

## Route-map and prefix-list control

`REDIST-OSPF-BGP-PROD` is controlled by `RM-OSPF-TO-BGP`. The route-map
references `PL-PROD`, and that prefix-list controls `10.20.30.0/24`. The
route-map also sets community `65001:100`. These nodes expose the policy chain
that can explain a missing advertisement.

## Route lineage and service impact

A summarized Route node records that the important prefix originated in OSPF,
was redistributed by the rule, and is currently withdrawn from BGP. Payment-App
depends on the prefix, while the prefix also explicitly `SUPPORTS` the service.
An incident and change connect the technical failure to service impact and
causal evidence.
