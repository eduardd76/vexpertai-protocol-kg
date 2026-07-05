# Chapter 11 MPLS Ontology

The MPLS ontology models label distribution, data-plane bindings, transport
paths, VPN services, pseudowires, traffic engineering, protection, and
underlay dependencies. It stores summarized forwarding meaning and evidence
instead of complete LFIB or VPN routing tables.

## LSP naming

`LSP` is ambiguous across networking domains: IS-IS uses it for a link-state
PDU, while MPLS uses it for a label-switched path. The ontology preserves the
shared `LSP` term for compatibility and requires a domain-specific companion
label:

- `ISISLSP` identifies an IS-IS link-state PDU.
- `MPLSLSP` and `LabelSwitchedPath` identify MPLS transport.

Seed nodes use both the compatibility and domain-specific labels.

## MPLS transport and forwarding

`MPLSDomain` contains `LabelSwitchRouter`, `ProviderRouter`, and
`ProviderEdge` roles. `LDP`, `RSVPTE`, or `SegmentRoutingMPLS` creates a
`LabelBinding`, which binds a `Label` to a `FEC`.

`MPLSForwardingTable` and `LFIB` contain installed bindings. An MPLS LSP
depends on those bindings, making control-plane route availability distinct
from usable label forwarding.

## VPN services

`MPLSL3VPN` depends on:

- `VRF`
- `RouteDistinguisher`
- `RouteTarget`
- `MPBGPVPNv4` or `MPBGPVPNv6`
- an MPLS LSP

`RouteTarget` imports eligible `VPNRoute` objects into a VRF. Separate export
and intended-VRF relationships expose route-target mismatches.

`MPLSL2VPN`, `VPWS`, and `VPLS` use `Pseudowire` objects. Pseudowire state
depends on `TargetedLDP` or another `L2VPNSignaling` mechanism.

## Traffic engineering and protection

`TrafficEngineeringTunnel` depends on `RSVPTE` signaling and
`IGPTEExtensions`. `FastReroute` protects an MPLS LSP with local repair.
`PenultimateHopPopping` records egress label-stack behavior.

## Convergence and underlay

An `LDPAdjacency` depends on `IGPReachability`, but IGP-up does not prove that
label distribution is healthy. `LDPIGPSynchronization` prevents a
`TrafficBlackhole` by holding the IGP metric until required labels converge.

`ServiceOverlay` depends on `TransportUnderlay`, providing a direct path from
underlay failure to MPLS service and business impact.
