# MPLS Dependency Model

## Route and label forwarding

```text
VPNRoute -> Prefix -> IGPReachability
     |
MPLSService -> MPLSLSP -> LabelBinding -> Label + FEC
```

A VPN route and reachable next hop do not prove forwarding. The service also
requires an installed label binding and usable LSP.

## LDP dependency

```text
MPLSLSP -> LabelBinding -> LDP -> LDPAdjacency
                                      |
                                IGPReachability
```

IGP reachability is necessary but not sufficient for LDP. Discovery,
transport-address selection, TCP reachability, and policy can independently
break the LDP session.

## L3VPN route-target policy

```text
VPNRoute -> exported RouteTarget
     |
 intended VRF -> imported RouteTarget
```

The route is visible in a VRF only when export and import policy match.
Route-target analysis remains separate from label-path validation.

## Layer 2 VPN signaling

```text
VPWS / VPLS -> Pseudowire -> TargetedLDP or L2VPNSignaling
                    |
                 MPLSLSP
```

Attachment circuits may remain up while pseudowire signaling or MPLS
transport is unavailable.

## Traffic engineering and protection

```text
TrafficEngineeringTunnel -> RSVPTE
                         -> IGPTEExtensions

FastReroute -> MPLSLSP
```

RSVP state requires IGP TE topology information for constrained path
calculation. Fast reroute is modeled independently as local repair protecting
the resulting LSP.

## Synchronization and overlay impact

```text
LDPIGPSynchronization -> prevents TrafficBlackhole

BusinessService -> MPLSService -> ServiceOverlay -> TransportUnderlay
```

This separates safe convergence behavior from the dependency path used for
service-impact analysis.
