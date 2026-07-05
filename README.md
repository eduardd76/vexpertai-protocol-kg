# vExpertAI Protocol-Aware Knowledge Graph

This project is a Neo4j network design and operations knowledge graph. It
integrates protocol, policy, dependency, evidence, change, risk, validation,
application, and business-service semantics rather than storing configuration
as undifferentiated text.

The included data demonstrates chapter-specific scenarios plus a global
Payment-App dependency chain:

1. A Payment-App outage where a VXLAN tunnel alert traces through EVPN and VTEP
   dependencies to a degraded underlay interface.
2. A missing route where `10.20.30.0/24` traces from OSPF through an
   OSPF-to-BGP redistribution rule, route-map, prefix-list, and recent change.
3. Branch Payment-App access across VLAN, FHRP, OSPF, BGP redistribution, MPLS
   VPN, firewall, QoS, application, SLA, risk, ownership, and validation.

The graph deliberately contains summarized operational truth. Raw routes, logs,
flows, and telemetry should remain in their source systems and be referenced as
evidence.

## Prerequisites

- Docker with Docker Compose
- Python 3.9 or newer

## Start Neo4j

```bash
docker compose up -d
```

Neo4j Browser is available at <http://localhost:7474>. Sign in with username
`neo4j` and password `password123`. Bolt listens on
`bolt://localhost:7687`.

## Install and load

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python src/load_neo4j.py
```

The loader applies both MVP and generated design-ontology schemas, safely
replaces only their owned datasets, and loads every chapter plus the global
scenario. Connection settings can be overridden:

```bash
export NEO4J_URI=bolt://localhost:7687
export NEO4J_USERNAME=neo4j
export NEO4J_PASSWORD=password123
```

## Run the demo

```bash
python src/demo.py
```

The CLI prints four default sections:

- Overlay/Underlay RCA
- Redistribution Impact Analysis
- Evidence and Recommendation
- Global Network Design KG

The same questions are available as standalone Cypher in
`cypher/demo_queries.cypher`.

## Network design ontology

The design ontology extends the operational MVP without replacing it. YAML
documents under `ontology/` define labels, properties, relationships,
constraints, dependency rules, risk rules, validation queries, and original
example scenarios.

Validate the ontology and generate Neo4j schema:

```bash
python src/validation.py
python src/schema_generator.py \
  --output cypher/schema/generated_ontology_constraints.cypher
pytest -q
```

`load_neo4j.py` already loads both datasets. Use `graph_loader.py` only when a
design-only reload is useful. Run chapter and global query packs with:

```bash
python src/graph_loader.py
python src/query_runner.py
python src/demo.py --chapter-1
python src/demo.py --chapter-2
python src/query_runner.py cypher/queries/chapter_03_ospf_queries.cypher
python src/query_runner.py cypher/queries/chapter_04_isis_queries.cypher
python src/query_runner.py cypher/queries/chapter_05_eigrp_queries.cypher
python src/query_runner.py cypher/queries/chapter_06_vpn_queries.cypher
python src/query_runner.py cypher/queries/chapter_08_bgp_queries.cypher
python src/query_runner.py cypher/queries/chapter_09_multicast_queries.cypher
python src/query_runner.py cypher/queries/chapter_10_qos_queries.cypher
python src/query_runner.py cypher/queries/chapter_11_mpls_queries.cypher
python src/query_runner.py cypher/queries/global_network_design_queries.cypher
```

`--chapter-1` adds the optional Layer 2 section to the original demo. It covers
STP/FHRP alignment, blocked ports, BPDU guard, unused VLAN carriage,
service-impacting Layer 2 risks, and access design tradeoffs.

`--chapter-2` adds requirement coverage, option/risk ranking, assumption
validation, migration dependency safety, monitoring impact, operational
complexity, and unmitigated-risk analysis. Both chapter flags can be used
together.

The design loader deletes only nodes marked
`dataset: vexpertai-design-ontology`. The original loader continues to own only
`dataset: vexpertai-mvp`, so both models can coexist.

### Global ontology

Shared labels have one canonical definition in `ontology/core.yaml`.
Chapter-specific nodes receive generic parent labels such as `Protocol`,
`RoutingProtocolInstance`, `Policy`, `OverlayService`, `Risk`, `Requirement`,
and `Constraint`.

`ControlPlaneDependency` and `DataPlaneDependency` provide reusable dependency
patterns across VPN, MPLS, VXLAN, SR, and other overlays. `SUPPORTS_LAYER`
connects the physical-to-business chain for global impact queries while
chapter relationships retain detailed protocol causality.

See:

- `docs/ontology/global_network_design_ontology.md`
- `docs/protocol-dependencies/global_protocol_dependency_model.md`
- `docs/scenarios/end_to_end_rca_scenarios.md`

### Chapter-to-KG domain map

The chapter names provide design scope only. The ontology and scenario content
is original to this project.

| Scope | KG domain |
|---|---|
| Core | Objectives, constraints, decisions, options, tradeoffs, risk, evidence, validation, service impact |
| Layer 2 | Broadcast domains, loop control, link aggregation, gateway resiliency, failure scope |
| Design principles | Requirement traceability, availability, convergence, capacity, operability |
| OSPF | Areas, adjacency, summaries, flooding scope, external route policy |
| IS-IS | Level hierarchy, adjacency, metrics, leaking, overload behavior |
| EIGRP | Query boundaries, stub behavior, summaries, metrics |
| VPN | Segmentation, attachments, route-target policy, encryption |
| IPv6 | Address planning, transition, neighbor discovery, policy parity |
| BGP | Autonomous systems, address families, policy, route reflection |
| Multicast | Sources, receivers, groups, rendezvous points, RPF dependency |
| QoS | Classification, marking, queuing, congestion points, SLA objectives |
| MPLS | Label distribution, LSPs, traffic engineering, fast reroute |
| Merger scenario | Protocol boundaries, overlap, migration phases, exit validation |
| Enterprise scenario | Campus, branch, WAN, internet edge, segmentation, service policy |
| Appendix | Complexity budgets, segment routing, carrier Ethernet demarcation |

## Repository layout

- `ontology/`: reusable core and network design domain definitions
- `cypher/`: backward-compatible MVP files plus generated schema, design seeds,
  and design queries
- `src/`: MVP helpers plus ontology validation, schema generation, and graph
  loading
- `docs/`: ontology format, protocol dependency model, and scenario narratives
- `tests/`: ontology integrity and required relationship checks

This milestone intentionally excludes agents, LangGraph, APIs, vector
databases, full telemetry ingestion, and a frontend.
