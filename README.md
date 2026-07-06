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

## Customer demo quick start

```bash
docker compose up -d
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python src/seed_loader.py
python src/demo.py
uvicorn src.api:app --reload
```

Open <http://localhost:8000> for the visualization. FastAPI serves the static
frontend, so there is no separate frontend install or start command. The page
loads Cytoscape.js from `unpkg.com`, which requires browser access to that CDN.

Neo4j Browser is available at <http://localhost:7474>. Sign in with username
`neo4j` and password `password123`. Bolt listens on
`bolt://localhost:7687`.

`seed_loader.py` validates and loads the unified design graph. It safely
replaces only nodes owned by `dataset: vexpertai-design-ontology`. Connection
settings can be overridden:

```bash
export NEO4J_URI=bolt://localhost:7687
export NEO4J_USERNAME=neo4j
export NEO4J_PASSWORD=password123
```

## Run the demo

```bash
python src/demo.py
```

The default CLI prints eight bounded graph views: OSPF, BGP, the FHRP/OSPF,
OSPF/BGP, and BGP/MPLS interaction boundaries, the Payment-App dependency
chain, the CHG-8821 blast radius, and Ethernet1/49 failure propagation.

Use `python src/demo.py --legacy` for the original MVP and chapter-oriented
tabular queries. Standalone Cypher remains available under `cypher/queries/`
and in `cypher/demo_queries.cypher`.

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
python src/demo.py --legacy --chapter-1
python src/demo.py --legacy --chapter-2
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

This milestone intentionally excludes agents, LangGraph, vector databases,
authentication, and full telemetry ingestion.

## Modular graph API and visualization

The repository now runs one unified Neo4j database with:

- shared core ontology in `ontology/core.yaml`
- protocol modules in `ontology/protocols/`
- protocol-boundary modules in `ontology/interactions/`
- FastAPI graph views in `src/api.py`
- a static Cytoscape.js frontend in `frontend/`

After completing the quick start, use these API examples:

```text
GET /health
GET /views/protocol/ospf
GET /views/protocol/bgp
GET /views/interaction/stp/fhrp
GET /views/interaction/fhrp/ospf
GET /views/interaction/ospf/bgp
GET /views/interaction/bgp/mpls
GET /views/service/Payment-App
GET /views/failure/Ethernet1%2F49
GET /views/change/CHG-8821
GET /search?q=Payment
```

For a first customer walkthrough:

1. Open the STP/FHRP interaction to show the VLAN 100 root on Dist-01 and HSRP
   active role on Dist-02.
2. Open the OSPF/BGP interaction to show prefix origin, redistribution policy,
   and BGP next-hop dependence on IGP reachability.
3. Open the BGP/MPLS interaction to show a present VPN route with a missing
   label.
4. Open the Payment-App service view for the bounded end-to-end path and its
   VRF and application-endpoint branches.
5. Open CHG-8821 to show the prefix-list, route-map, redistribution, affected
   prefix/service, evidence, recommendation, and validation plan.

The original tabular demonstration remains available with:

```bash
python src/demo.py --legacy
```

Use `python src/load_neo4j.py` only when the original 51-node operational MVP
dataset is also needed alongside the unified design graph.
