# vExpertAI Protocol-Aware Knowledge Graph Context

vExpertAI builds a private semantic operating model for network and security
operations. Its knowledge graph represents operational meaning and connected
truth: protocol dependencies, route redistribution, overlay/underlay
relationships, service impact, evidence, and change correlation.

Protocols are first-class semantic objects. A BGP process, OSPF process, EVPN
control plane, VXLAN overlay, VTEP, redistribution rule, route-map, and
prefix-list can each have identity, state, lineage, and dependencies. This lets
the system explain why an observed symptom affects a service and which evidence
supports that conclusion.

The first milestone covers two scenarios:

1. VXLAN/EVPN overlay failure traced through VTEP and underlay dependencies to a
   physical interface problem.
2. An OSPF-originated prefix missing from BGP after a prefix-list change in its
   redistribution policy.

The graph stores dependencies, summarized state, lineage, evidence pointers,
and service impact. High-volume routes, MAC tables, logs, flows, and telemetry
remain in time-series systems, logs, or data lakes.

This MVP is limited to Neo4j, seed data, and deterministic queries. Agents,
LangGraph, APIs, vector databases, and frontends are outside this milestone.
