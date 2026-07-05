# Demo Scenarios

Payment-App is reached from User VLAN 100 through FHRP, OSPF, BGP
redistribution, MPLS L3VPN, VRF PROD, firewall policy, QoS, and application
endpoint `10.20.30.10`.

Four incidents demonstrate boundary reasoning:

1. STP root on Dist-01 and FHRP active on Dist-02 create suboptimal transit.
2. CHG-8821 changes PL-PROD and withdraws `10.20.30.0/24` from BGP.
3. VPNv4 and route-target state are correct but the MPLS label path is missing.
4. Payment traffic remains best effort during WAN congestion and violates SLA.

Each incident has evidence, a bounded recommendation, and a validation run.
