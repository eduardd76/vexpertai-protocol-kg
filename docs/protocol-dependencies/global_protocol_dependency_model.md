# Global Protocol Dependency Model

The integrated dependency chain is:

```text
Physical interface or link
  -> Layer 2 VLAN and default gateway
  -> IGP underlay
  -> BGP / MPLS / SR / VPN / VXLAN overlay
  -> Security policy
  -> QoS policy and class
  -> Application
  -> Business service
  -> SLA, risk, and owner
```

## Why both layered and detailed relationships exist

`SUPPORTS_LAYER` answers broad blast-radius questions. Protocol-specific
relationships explain the actual cause:

- OSPF redistribution uses `REDISTRIBUTES_TO`.
- A redistribution rule is `CONTROLLED_BY` a route map.
- A route map `REFERENCES` a prefix list.
- The prefix list `CONTROLS_PREFIX`.
- An MPLS service exposes control-plane and data-plane dependency nodes.

The broad chain finds affected services quickly; the detailed chain identifies
the responsible protocol or policy object.

## Control plane versus data plane

```text
OverlayService
  -> ControlPlaneDependency
       -> BGPProcess
       -> RedistributionRule
       -> RouteMap
       -> PrefixList

OverlayService
  -> DataPlaneDependency
       -> Interface / link / LSP / tunnel
```

This prevents a route-policy failure from being misdiagnosed as an MPLS
forwarding failure. Both layers can be healthy, degraded, or failed
independently.

## Change and blast radius

```text
Change -> PrefixList -> Prefix -> Application -> BusinessService
   |                                      |
   -> Risk -> Recommendation              -> Owner
                |
            ValidationRun
```

Evidence links to the change, policy, prefix, and dependency conclusion.
Recommendations are therefore traceable to observations and have an explicit
validation plan.
