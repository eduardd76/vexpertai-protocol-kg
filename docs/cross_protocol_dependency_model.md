# Cross-Protocol Dependency Model

Protocol boundaries are modeled in `ontology/interactions/`. The important
edges are explicit and queryable:

- STP root placement to FHRP active placement
- FHRP active role to IGP reachability
- BGP session and route recursion to IGP
- OSPF redistribution through route-map and prefix-list into BGP
- BGP VPN routes to MPLS labels
- MPLS VPN services to LSPs
- SR policies to IGP SID advertisements
- QoS policies to application SLA
- firewall rules to application flows
- overlays to underlays

These edges let RCA distinguish a healthy protocol-local state from a failed
boundary dependency. For example, a VPNv4 route can exist while the MPLS label
path is missing.
