# VPN Dependency Model

## End-to-end service dependency

```text
BusinessService -> Application -> VPNService -> UnderlayTransport
VPNService -> IPsecTunnel -> IKEPolicy
IPsecTunnel -> EncryptionDomain
```

This chain distinguishes business impact, overlay service, transport, and
cryptographic policy.

## Crypto-up versus routing-down

```text
TunnelHealth -> IKEState {up}
TunnelHealth -> RoutingState {down}
Evidence -> IKEState
Evidence -> RoutingState
```

An active IKE state proves negotiation, not application reachability. Missing
routing state directs investigation toward route exchange, tunnel interfaces,
or traffic selectors.

## MPLS route distribution

```text
VPNRoute -> RouteTarget <- IMPORTS - VRF
VRF -> EXPORTS -> RouteTarget
MPLSL3VPN -> VRF, RouteDistinguisher, RouteTarget, MPBGP
```

An exported route target with no intended VRF importer explains absent VPN
reachability. Import/export mismatch can also create asymmetric routing.

## DMVPN dependency

DMVPN depends on GRE encapsulation, NHRP resolution, and IPsec protection.
Spoke-to-spoke failure with working IPsec can still be caused by missing NHRP
registration or resolution.

## Failover

A failover policy tracks a VPN SLA and owns an alternate route. The alternate
route alone does not protect the service if tracking is failed or detached.

## Data-volume boundary

Neo4j stores VPN service identity, summarized states, policy, dependency,
evidence pointers, and impact. Detailed IKE exchanges, packet captures,
flow logs, and complete VPN routing tables remain external.
