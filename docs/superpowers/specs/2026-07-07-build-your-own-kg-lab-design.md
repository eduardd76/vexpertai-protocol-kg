# Design: "Build Your Own Network KG in an Hour" — a guided hands-on lab

- **Date:** 2026-07-07
- **Status:** Approved (design) — pending implementation plan
- **Owner:** Edy
- **Type:** Teaching artifact (guided lab) built on the existing vexpertai-protocol-kg repo

---

## 1. Summary

Deliver a **guided, hands-on lab** that takes a senior network engineer — expert in
networking, complete novice in knowledge graphs, graph databases, ontologies, and
Cypher — from an empty database to having **built their own knowledge graph of a
network they actually run**, in about one hour, and wanting to keep growing it.

The lab is a "clone-this-repo-and-go" experience driven from the **Neo4j Browser**,
graduating into the existing **KG Builder wizard**. It reuses the repo's Docker Neo4j,
the 3-area OSPF seed graph, the beginner OSPF blog post
(`docs/substack_ospf_kg_for_beginners.md`), and the `/kg-builder/*` wizard. The new
work is mostly **content plus light scaffolding** (a `Makefile`, tested Cypher blocks,
a fill-in template, and a verification test).

This spec was shaped by three independent teaching experts (a learning scientist, a
developer-education expert, and a network↔KG domain-bridge teacher) who converged on
the same approach.

## 2. Goal & success criteria

**Goal:** the learner ends the hour with a graph that is *partly theirs* (their area,
their ASN, their service) and has run a query — blast radius — that answers a question
their existing tools (CLI `show` commands, diagrams, spreadsheets) structurally cannot.

**Success criteria (ascending proof):**
1. Learner reaches a rendered graph in Neo4j Browser by ~minute 8, with Docker only (no Python yet).
2. Learner runs the blast-radius query and sees a *business service* named as impacted by a *routing* event (~minute 20) — the "whoa".
3. Learner mutates the example into a real slice of their own network and re-runs the query against it (~minute 55).
4. Every copy-paste Cypher block in the lab executes cleanly against the seeded DB (enforced by an automated test).
5. Durable: the learner has a saved-query pack tied to their incident/change-review loop, giving them a reason to return.

## 3. Audience & pedagogical foundation

The learner knows networking cold and dislikes being treated as a novice. The lab
therefore teaches KG concepts **entirely through networking expertise the learner
already owns**, and never explains networking to them. The seven principles below are
load-bearing and every content decision must honor them:

1. **Lead with the unifying frame.** "You already run the world's biggest graph
   database — it's called OSPF. Every router is a node, every adjacency an edge, SPF is
   a traversal. A knowledge graph is that same machine, except *you* choose what counts
   as a node — so you can add the one node OSPF never had: the business service that
   dies when the route does."
2. **DO before UNDERSTAND, always.** Each beat is a hands-on action first; the concept
   is named afterward, pointing at what is already on screen. Never front-load theory.
   Ontology theory is *earned* at beat 5, not introduced early.
3. **Neo4j Browser is the classroom.** It renders any query as a draggable graph for
   free, making the learner the author. The custom Cytoscape frontend and KG Builder
   wizard are the Act-2 reveal, not the teaching surface.
4. **First win needs zero Python.** Beat 1 is Docker + hand-pasted Cypher. `pip install`
   and `seed_loader.py` are deferred to beat 3, after the learner is hooked.
5. **Keep the schema/ontology invisible until beat 5.** Through beats 1–4 the schema is
   a fixed, unstated "parts bin" of node shapes. The word "ontology" and schema-authoring
   appear only after the learner has felt the parts bin fall short on their own network.
6. **Mutate, don't author.** The leap to "my network" is done by editing values in a
   working template (find-and-replace), never by facing a blank page or hand-writing YAML.
7. **Weld it to the incident/change loop for retention.** The graph earns its keep at
   3 AM; the saved-query pack and habits target the workflow the engineer already runs.

**Anti-condescension rule:** explain graph mechanics only, never the domain. Every
example is a real network from minute one — no toy "Alice-knows-Bob" datasets.

## 4. Non-goals (scope boundaries)

Consistent with the repo's `CLAUDE.md` milestone scope:

- **No live device/config ingestion, no telemetry, no real-time state.** Blast-radius is
  *structural* — computed from modeled dependencies, not live network state.
- **No hand-authoring of ontology YAML on the critical path.** The per-protocol YAML
  modules are reference material and the wizard's backing schema, not a lab step.
- **No new web UI.** The lab uses Neo4j Browser and the *existing* KG Builder wizard. No
  changes to `frontend/` are required for the lab itself.
- **No changes to the seed data or ontologies** beyond what is already committed. The lab
  consumes them as-is. (The earlier OSPF seed status correction is already committed.)
- **Not a cohort course, video series, or hosted interactive lab.** Those are possible
  later; v1 is the clone-and-go guided doc.

## 5. Deliverable — components

All new files live in the existing repo. Reused assets are listed for context.

### 5.1 `Makefile` (repo root) — friction killer
Wraps the repo's multi-step setup so the learner never learns repo internals.

| Target | Action |
|---|---|
| `make up` | `docker compose up -d` and block until the Neo4j healthcheck passes |
| `make seed` | create venv if missing, `pip install -r requirements.txt`, run `python src/seed_loader.py` |
| `make browser` | open `http://localhost:7474` in the default browser |
| `make demo` | run `python src/demo.py` (the 8 bounded views) |
| `make reset` | re-run `seed_loader.py` to restore the design dataset |
| `make down` | `docker compose down` (data volume preserved) |

Notes: `NEO4J_AUTH` is already pre-set to `neo4j/password123` in `docker-compose.yml`
(no first-login reset wall) and a healthcheck already exists — `make up` waits on it.
Use `Makefile` (ubiquitous, no install) rather than `just`.

### 5.2 `docs/lab/build-your-own-kg.md` — the guided hour
The spine of the lab. Structured as seven beats (Section 6), each **DO → UNDERSTAND**.
Written in Edy's voice. References (does not duplicate) the existing OSPF blog post for
deeper explanation. Includes:
- The unifying frame up front.
- A "five words you need" sidebar placed **after** beat 1 (node/edge/label/property/Cypher).
- The one rule: "Cypher is ASCII-art of the shape you want" — introduced at beat 4.
- A troubleshooting box with the 3 classic Cypher errors (missing semicolon, wrong label
  case, mistyped `-[:REL]->`) and their fixes.
- A dataset-isolation safety note: everything the learner does is tagged
  `vexpertai-builder`; reseeding the demo never touches their work.

### 5.3 `cypher/lab/*.cypher` — tested, copy-paste blocks
Complete blocks (never fill-in-the-blank), each verified against the seeded DB:

- `01_first_five_nodes.cypher` — three OSPF areas + two boundary routers + `CONNECTS`
  edges (one `state:'down'`), then `MATCH (n) RETURN n`. The hand-built first graph.
- `02_blast_radius.cypher` — the "3 AM" query. Known-good shape against the current seed:
  ```cypher
  MATCH (abr:ABR)-[:CONNECTS]->(area:OSPFArea)
  MATCH (prefix:Prefix)-[:ORIGINATES_IN]->(area)
  MATCH (prefix)-[:SUPPORTS]->(service:BusinessService)
  RETURN abr.name AS abr, abr.status AS abr_status, area.name AS area,
         collect(DISTINCT prefix.cidr) AS dependent_prefixes,
         collect(DISTINCT service.name) AS impacted_services
  ORDER BY abr;
  ```
  Returns `abr-01` (down), Area 10, `10.30.10.0/24`, **Order API**.
- `03_three_questions.cypher` — prefixes-per-area + LSA lineage + stub-area trade-off
  (the three verified queries from `cypher/queries/chapter_03_ospf_queries.cypher`).
- `04_break_it.cypher` — `SET` the backbone `CONNECTS` edge to `state:'down'`, re-run
  blast-radius, observe the impacted set change. Cause → effect, live.
- `your_network_template.cypher` — the "YOUR NETWORK" block: a 3-area/2-ABR/1-service
  skeleton where only *values* are changed. Replacement points are clearly marked (e.g.
  `// <REPLACE: your area id>`), structure is fixed.
- `starter_shapes.cypher` — the 6–8 canonical stencils as comments + example:
  `Service -DEPENDS_ON-> Prefix`, `Prefix -ADVERTISED_BY-> LSA -HAS_LSA_TYPE-> LSAType`,
  `Prefix -ORIGINATES_IN-> Area`, `Router -CONNECTS-> Area`, redistribution boundary,
  overlay/underlay, `Prefix -SUPPORTS-> Service`.

All lab queries must match the **committed seed edges** (`SUPPORTS`, `DEPENDS_ON`,
`ORIGINATES_IN`, `ADVERTISED_BY`, `HAS_LSA_TYPE`, `CONNECTS`). No invented edges.

### 5.4 `tests/test_lab_cypher.py` — the "never rots" guarantee
Runs every `cypher/lab/*.cypher` block against a seeded database and asserts it executes
without error, and that `02_blast_radius.cypher` returns the expected Order API row.
Follows the repo's existing offline-friendly test pattern where possible; the blocks that
need a live DB are marked and skipped when Neo4j is unavailable (documented), so the
default `pytest -q` stays green offline. A `make verify-lab` target runs them against a
live seeded DB.

### 5.5 Saved-query pack for Neo4j Browser — retention
`docs/lab/saved-queries.md` — a short doc shipping the three "keep these open" queries as
copy-paste blocks (Browser favorites import is version-dependent, so a doc is the portable
form), framed for the incident/change-review loop:
1. "What breaks if X fails" (blast radius, parameterized by device).
2. "What depends on this prefix."
3. "Blast radius of this change" (for pre-maintenance review).

### 5.6 Graduation path — the existing KG Builder wizard
The final beat routes the learner to the existing `/kg-builder/*` wizard (frontend Build
tab) to add their real protocol mix without hand-Cypher, and presents the per-protocol
ontology modules as a "protocols you've added" ladder (OSPF → BGP redistribution → MPLS
overlay → cross-protocol interaction view).

### Reused as-is
`docker-compose.yml`, `src/seed_loader.py`, `src/demo.py`,
`docs/substack_ospf_kg_for_beginners.md`, `src/kg_builder.py` + `/kg-builder/*`,
the `dataset:` isolation invariant.

## 6. The guided hour — beat by beat

| Beat | ~Time | DO | UNDERSTAND (just-in-time) |
|---|---|---|---|
| 0 | 0–2 | Read the unifying frame | "A graph is a diagram you can query" |
| 1 | 2–8 | `make up`; paste 5 nodes; `RETURN n` — graph draws itself | node / edge / label / property, pointing at the picture |
| 2 | 8–15 | Drag nodes; inspect properties | why a graph beats SQL/CMDB/spreadsheet (relationships are stored objects you walk) |
| 3 | 15–20 | `make seed`; run `02_blast_radius.cypher` → **Order API impacted** | dependency lineage; the routing→business bridge no `show` command has |
| 4 | 20–50 | Run `03_three_questions`; run `04_break_it`, watch impact change | "Cypher is ASCII-art of the shape you want" |
| 5 | 50–58 | Edit `your_network_template.cypher` → your area/ASN/service; re-run blast radius | the ontology idea + the stop-modeling rule (below) — schema becomes visible now |
| 6 | 58+ | Open the KG Builder wizard; add a real protocol; preview; save | ontology-as-reusable-schema; the growth ladder |

**Stop-modeling rule (introduced at beat 5):** *"Model the nouns of your design review,
not the numbers of your monitoring dashboard."* Backup phrasing: "If it changes on its
own, it stays in the source system as Evidence; if it changes because you redesigned
something, it belongs in the graph."

## 7. Testing strategy

- **Content correctness:** `tests/test_lab_cypher.py` executes every lab Cypher block
  against a seeded DB; the tutorial cannot silently rot.
- **Graduation flow:** use the **Playwright MCP** to drive the KG Builder wizard in the
  frontend end to end (add a protocol → preview → save → reload profile) so the beat-6
  hand-off is verified against the real UI.
- **Offline suite unaffected:** `pytest -q` stays green with no live Neo4j; DB-dependent
  lab tests are marked/skipped when the DB is absent.

## 8. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Lab Cypher drifts from seed edges and breaks copy-paste | `test_lab_cypher.py` + `make verify-lab` run every block against the seed |
| Learner over-models their own network | The stop-modeling rule + a bounded template (one area, one service) |
| Learner stalls on Python/venv before any payoff | Beat 1 is Docker-only; Python deferred to beat 3 |
| Corp laptop blocks the unpkg CDN the custom frontend uses | Entire lab completes in Neo4j Browser (bundled/offline); frontend is optional finale |
| "Will this touch my other data?" anxiety | Surface the `vexpertai-builder` dataset isolation early and explicitly |

## 9. Acceptance criteria (definition of done)

1. `make up && make seed` brings a learner from clean clone to seeded graph with no
   manual steps beyond those two commands.
2. All six `cypher/lab/*.cypher` blocks execute cleanly against the seed;
   `02_blast_radius.cypher` returns the Order API impact row.
3. `docs/lab/build-your-own-kg.md` walks all seven beats, DO-before-UNDERSTAND, schema
   hidden until beat 5, in Edy's voice.
4. `tests/test_lab_cypher.py` passes; `pytest -q` stays green offline.
5. The graduation beat successfully drives the existing KG Builder wizard (Playwright-verified).
6. A learner following the doc can, unaided, mutate the template into a slice of their
   own network and get a blast-radius answer against it.

## 10. Build sequence (for the implementation plan)

- **P1** — `Makefile` + verify `make up`/`make seed`/`make browser` on a clean clone.
- **P2** — `cypher/lab/*.cypher` blocks + `tests/test_lab_cypher.py` (lock the queries against the seed first).
- **P3** — `docs/lab/build-your-own-kg.md` (the guided hour), in Edy's voice.
- **P4** — saved-query pack + graduation section; Playwright check of the wizard hand-off.
- **P5** — end-to-end dry run: follow the doc verbatim on a clean clone, fix friction.
