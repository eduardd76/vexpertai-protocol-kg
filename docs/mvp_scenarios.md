# MVP Scenarios

## 1. VXLAN/EVPN overlay-underlay RCA

### Business view

Payment-App is unavailable in the production segment. The incident identifies
the impacted business service and provides a safe recommendation: validate
underlay health before changing VXLAN configuration.

### Technical view

An alert reports a down VXLAN tunnel on `leaf-01`. Dependency traversal reaches
the EVPN control plane, the leaf VTEP, underlay routing, and physical link
`leaf-01:Ethernet1/49--spine-01:Ethernet1/1`. Evidence reports CRC errors and an
underlay adjacency flap on `leaf-01` Ethernet1/49. This makes the underlay link
the likely cause of the overlay symptom.

## 2. OSPF-to-BGP redistribution impact

### Business view

Payment-App loses branch reachability after change `CHG-8821`. The incident
links the outage to the missing production prefix and the policy change.

### Technical view

Prefix `10.20.30.0/24` originates in OSPF process `100` on `dc-edge-01`. Rule
`REDIST-OSPF-BGP-PROD` redistributes it into BGP AS `65001`, controlled by
route-map `RM-OSPF-TO-BGP` and prefix-list `PL-PROD`. Change `CHG-8821` changed
the prefix-list action from permit to deny. Evidence shows the prefix
disappearing from the BGP advertisement immediately afterward.

The scenario demonstrates deterministic change correlation and policy lineage;
it does not require storing the complete OSPF or BGP route tables.
