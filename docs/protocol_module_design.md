# Protocol Module Design

Protocol modules live under `ontology/protocols/`. Each module adds only its
own concepts, properties, relationships, constraints, dependency rules, risk
rules, validation queries, and scenarios.

Current modules cover Layer 2/STP/FHRP, OSPF, BGP, MPLS, VPN, Segment Routing,
QoS, and security policy. Existing IS-IS, EIGRP, IPv6, and multicast models
remain loadable modules in the same graph.

Modules attach to core objects such as `Device`, `Interface`, `Prefix`, `VRF`,
`Policy`, `Application`, and `BusinessService`. Tests reject duplicate
ownership of core labels.
