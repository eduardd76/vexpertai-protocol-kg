# Global Core Ontology

vExpertAI uses one Neo4j graph. The core ontology owns concepts shared by every
network domain: devices, interfaces, sites, prefixes, routes, protocol
instances, policies, applications, services, incidents, changes, evidence,
recommendations, validation, risk, requirements, and constraints.

Protocol modules reference these labels rather than redefining them. A BGP
process and an OSPF process, for example, are both `ProtocolInstance` and
`RoutingProtocolInstance` nodes running on a `Device`.

The graph stores semantic state and evidence pointers. Raw telemetry, complete
RIBs, logs, and packet captures remain in their operational systems.
