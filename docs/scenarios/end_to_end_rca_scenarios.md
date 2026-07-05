# End-to-End RCA Scenarios

## Payment-App redistribution failure

Branch users reach Payment-App through:

```text
Access port
-> VLAN 110
-> HSRP default gateway
-> OSPF 110
-> BGP 65110 redistribution
-> Payment MPLS L3VPN
-> firewall permit policy
-> critical-data QoS
-> Payment-App
-> Payment-App Branch Service
```

The business service also links to its transaction SLA and Payments SRE owner.

### Simulated change

Change `global-change-pl-payment` modifies `PL-PAYMENT-APP`, changing
`10.50.10.0/24` from permit to deny. OSPF still owns the prefix and the MPLS
data plane remains available, but BGP no longer receives the redistributed
route.

The graph concludes:

- impacted prefix: `10.50.10.0/24`
- responsible policy: `RM-OSPF-TO-BGP-PAYMENT` and `PL-PAYMENT-APP`
- impacted application: Payment-App
- impacted business service: Payment-App Branch Service
- accountable owner: Payment Platform Operations
- root-cause class: control-plane policy failure

The recommendation validates the intended prefix, stages permit restoration,
checks OSPF-to-BGP propagation, runs branch application and SLA probes, and
retains rollback. It explicitly avoids broadly permitting unrelated prefixes.

## Interface blast-radius simulation

The branch access interface retains its actual `up` state and carries a
`simulated_status: failed` marker. The global query follows `SUPPORTS_LAYER`
from that interface to Payment-App without modifying live graph state.

## Underlay-to-overlay RCA

Existing chapter scenarios are normalized with the `OverlayService` parent
label. The global underlay query therefore finds VPN, MPLS, VXLAN, or SR
overlays affected by failed `TransportUnderlay`, `UnderlayRouting`,
`ISISUnderlay`, or `IGPReachability` state.
