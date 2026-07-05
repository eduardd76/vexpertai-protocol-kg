# Chapter 6 VPN Ontology

The VPN ontology models service type, tunnel components, underlay dependency,
encryption selectors, MPLS route distribution, health, failover, evidence, and
application impact. It stores summarized operational meaning rather than every
security association or routing entry.

## VPN service types

`VPNService` is specialized by `SiteToSiteVPN`, `RemoteAccessVPN`,
`MPLSL3VPN`, `MPLSL2VPN`, and `DMVPN`. A service connects sites and depends on
an `UnderlayTransport`.

Applications depend on VPN services, while business services depend on
applications. This gives tunnel and route-distribution failures a direct impact
path to business capabilities.

## IPsec and tunnel health

`IPsecTunnel` depends on `IKEPolicy` and protects an `EncryptionDomain`.
`CryptoMap` binds IKE and selectors. `NATTraversal`, `TunnelInterface`, and
`OverlayTunnel` remain distinct because crypto establishment, encapsulation,
and routed forwarding can fail independently.

`TunnelHealth` depends on both `IKEState` and `RoutingState`. An established
security association with missing routes is therefore represented as
crypto-up/routing-down, not simply tunnel-up.

## MPLS L3VPN

`MPLSL3VPN` uses:

- `VRF`
- `RouteDistinguisher`
- `RouteTarget`
- `MPBGP`

A `VPNRoute` is imported by a route target, and VRFs explicitly import or
export route targets. A target with no intended importer exposes a
route-distribution mismatch.

## DMVPN

`DMVPN` uses `GRE`, `NHRP`, and `IPsecTunnel`, with explicit `Hub` and `Spoke`
endpoints. A broken NHRP dependency can remove spoke-to-spoke reachability even
when GRE and IPsec remain up.

## Failover and evidence

`VPNFailoverPolicy` tracks `VPNSLA` or tunnel health and owns an alternate
`VPNRoute`. The policy protects a VPN service only when tracking can trigger.

Evidence links independently to IKE state, routing state, tunnel health, or
encryption-domain state. This supports root-cause separation between tunnel
negotiation, routing, and selector failures.
