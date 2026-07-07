# Build-Your-Own-KG Lab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a guided, hands-on lab that takes a network engineer from an empty database to their own knowledge graph in ~1 hour, driven from Neo4j Browser and graduating into the existing KG Builder wizard.

**Architecture:** Content-plus-light-scaffolding on top of the existing repo. A `Makefile` hides setup; six tested `cypher/lab/*.cypher` blocks are the copy-paste spine; a guided Markdown doc walks seven DO→UNDERSTAND beats; a pytest module keeps every Cypher block honest against the seed so the tutorial can never rot. No new web UI; no changes to seed data or ontologies.

**Tech Stack:** Docker + Neo4j (existing `docker-compose.yml`), Python 3 + pytest (existing offline suite), Cypher, Make, Neo4j Browser. Design spec: `docs/superpowers/specs/2026-07-07-build-your-own-kg-lab-design.md`.

---

## File structure

**Create:**
- `Makefile` — setup wrapper (`up`, `seed`, `browser`, `demo`, `reset`, `down`).
- `cypher/lab/01_first_five_nodes.cypher` — hand-built sandbox graph (pre-seed).
- `cypher/lab/02_blast_radius.cypher` — the "3 AM" query (seed-real edges).
- `cypher/lab/03_three_questions.cypher` — three verified queries.
- `cypher/lab/04_break_it.cypher` — toggle a link, re-observe impact.
- `cypher/lab/your_network_template.cypher` — fill-in "YOUR NETWORK" block.
- `cypher/lab/starter_shapes.cypher` — canonical stencils.
- `tests/test_lab_cypher.py` — offline static lint + skipped live integration check.
- `docs/lab/build-your-own-kg.md` — the guided hour (Edy's voice).
- `docs/lab/saved-queries.md` — retention query pack.

**Reused unchanged:** `docker-compose.yml`, `src/seed_loader.py`, `src/demo.py`, `src/kg_schema.py`, `src/db.py`, `src/config.py`, `docs/substack_ospf_kg_for_beginners.md`, `src/kg_builder.py` + `/kg-builder/*`.

**Conventions from the repo (verified):** `src.kg_schema.load_cypher_file(path) -> list[str]` and `split_cypher_statements(script) -> list[str]` handle `//` comments and `;` splitting. `src.db.create_driver(settings=None) -> neo4j.Driver`. `src.config.get_settings()` reads `NEO4J_*` env with defaults `bolt://localhost:7687` / `neo4j` / `password123` / db `neo4j`. Tests import from `src.*` and must stay green offline (`pytest -q`).

---

## Task 0: Branch

- [ ] **Step 1: Create a feature branch**

We are on `main`. Branch before any commits.

Run:
```bash
git checkout -b lab/build-your-own-kg
```
Expected: `Switched to a new branch 'lab/build-your-own-kg'`

---

## Task 1: Makefile setup wrapper

**Files:**
- Create: `Makefile`

- [ ] **Step 1: Write the Makefile**

Create `Makefile` (indented lines are **tabs**, not spaces):

```makefile
.DEFAULT_GOAL := help
COMPOSE := docker compose

.PHONY: help up seed browser demo reset down

help:  ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-9s\033[0m %s\n",$$1,$$2}'

up:  ## Start Neo4j and wait until it is healthy
	$(COMPOSE) up -d
	@echo "Waiting for Neo4j to be healthy..."
	@until [ "$$(docker inspect -f '{{.State.Health.Status}}' vexpertai-neo4j 2>/dev/null)" = "healthy" ]; do \
		sleep 2; printf "."; done; \
		echo " ready -> http://localhost:7474  (neo4j / password123)"

seed:  ## Create venv, install deps, load the design graph
	@test -d .venv || python3 -m venv .venv
	./.venv/bin/pip install -q -r requirements.txt
	./.venv/bin/python src/seed_loader.py

browser:  ## Open the Neo4j Browser
	@open http://localhost:7474 2>/dev/null || \
		xdg-open http://localhost:7474 2>/dev/null || \
		echo "Open http://localhost:7474 in your browser"

demo:  ## Print the 8 bounded graph views
	./.venv/bin/python src/demo.py

reset:  ## Reload the design dataset (your vexpertai-builder work is untouched)
	./.venv/bin/python src/seed_loader.py

down:  ## Stop Neo4j (data volume preserved)
	$(COMPOSE) down
```

- [ ] **Step 2: Verify targets are discoverable**

Run: `make help`
Expected: a list showing `up`, `seed`, `browser`, `demo`, `reset`, `down` with descriptions.

- [ ] **Step 3: Verify the up recipe is well-formed (dry run, no Docker needed)**

Run: `make -n up`
Expected: prints the `docker compose up -d` line and the wait loop without executing them. No "missing separator" errors (confirms tabs are correct).

- [ ] **Step 4: Commit**

```bash
git add Makefile
git commit -m "feat(lab): add Makefile setup wrapper for the KG lab"
```

---

## Task 2: Offline static-lint test for lab Cypher

Write the test first; it fails because the lab files do not exist yet. The lint parses each block and asserts it only uses labels/relationships that exist in the seed (plus a small pre-seed sandbox set), catching typos and invented edges that would break copy-paste.

**Files:**
- Create: `tests/test_lab_cypher.py`

- [ ] **Step 1: Write the failing test**

Create `tests/test_lab_cypher.py`:

```python
import re
from pathlib import Path

import pytest

from src.kg_schema import load_cypher_file

LAB_DIR = Path(__file__).resolve().parents[1] / "cypher" / "lab"

EXPECTED_FILES = [
    "01_first_five_nodes.cypher",
    "02_blast_radius.cypher",
    "03_three_questions.cypher",
    "04_break_it.cypher",
    "your_network_template.cypher",
    "starter_shapes.cypher",
]

# Labels/relationships that exist in the design seed, plus the simplified
# labels used only in the pre-seed sandbox block (01). A lab block using
# anything outside these sets is almost certainly a typo or an invented edge
# that will return zero rows against the real graph.
ALLOWED_LABELS = {
    # sandbox (block 01, pre-seed)
    "Router",
    # seed-real
    "OSPFArea", "BackboneArea", "NormalArea", "StubArea",
    "Device", "OSPFRouter", "ABR", "ASBR",
    "Prefix", "BusinessService", "Route", "ExternalRoute",
    "LSA", "RouterLSA", "NetworkLSA", "SummaryLSA", "ExternalLSA",
    "NSSALSA", "OpaqueLSA", "LSAType",
}
ALLOWED_RELS = {
    "CONNECTS", "ORIGINATES_IN", "ADVERTISED_BY", "HAS_LSA_TYPE",
    "SUPPORTS", "DEPENDS_ON", "RESTRICTS", "CARRIED_BY_LSA",
}

_BRACKET_RE = re.compile(r"\[[^\]]*\]")
_LABEL_RE = re.compile(r":([A-Z][A-Za-z0-9_]*)")
_REL_RE = re.compile(r"\[[A-Za-z0-9_]*:([A-Za-z0-9_]+)")


def _strip_comments(text: str) -> str:
    return "\n".join(
        line for line in text.splitlines() if not line.strip().startswith("//")
    )


def _labels(text: str) -> set[str]:
    # remove [ ... ] relationship segments so rel types aren't read as labels
    return set(_LABEL_RE.findall(_BRACKET_RE.sub(" ", text)))


def _rels(text: str) -> set[str]:
    return set(_REL_RE.findall(text))


@pytest.mark.parametrize("filename", EXPECTED_FILES)
def test_lab_file_exists_and_parses(filename):
    path = LAB_DIR / filename
    assert path.exists(), f"missing lab file: {path}"
    statements = load_cypher_file(path)
    assert statements, f"no Cypher statements parsed from {filename}"


@pytest.mark.parametrize("filename", EXPECTED_FILES)
def test_lab_file_uses_only_known_labels_and_rels(filename):
    body = _strip_comments((LAB_DIR / filename).read_text(encoding="utf-8"))
    bad_labels = _labels(body) - ALLOWED_LABELS
    bad_rels = _rels(body) - ALLOWED_RELS
    assert not bad_labels, f"{filename}: unknown labels {bad_labels}"
    assert not bad_rels, f"{filename}: unknown relationships {bad_rels}"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `pytest tests/test_lab_cypher.py -q`
Expected: FAIL — `AssertionError: missing lab file: .../cypher/lab/01_first_five_nodes.cypher` (files don't exist yet).

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/test_lab_cypher.py
git commit -m "test(lab): add static lint for lab Cypher blocks (red)"
```

---

## Task 3: Create the six lab Cypher blocks

**Files:**
- Create: `cypher/lab/01_first_five_nodes.cypher`
- Create: `cypher/lab/02_blast_radius.cypher`
- Create: `cypher/lab/03_three_questions.cypher`
- Create: `cypher/lab/04_break_it.cypher`
- Create: `cypher/lab/your_network_template.cypher`
- Create: `cypher/lab/starter_shapes.cypher`

- [ ] **Step 1: Write `01_first_five_nodes.cypher`**

```cypher
// Beat 1 — your first graph, by hand. Paste this whole block into the Neo4j
// Browser query bar and press the play arrow. Then run:  MATCH (n) RETURN n
CREATE (a0:OSPFArea {name:'Area 0', area_id:'0.0.0.0', status:'up'})
CREATE (a10:OSPFArea {name:'Area 10', area_id:'0.0.0.10', area_type:'normal'})
CREATE (a20:OSPFArea {name:'Area 20', area_id:'0.0.0.20', area_type:'stub'})
CREATE (abr:Router {name:'abr-01', role:'ABR', router_id:'10.255.3.1'})
CREATE (asbr:Router {name:'asbr-01', role:'ASBR', router_id:'10.255.3.2'})
CREATE (abr)-[:CONNECTS {state:'down'}]->(a0)
CREATE (abr)-[:CONNECTS {state:'up'}]->(a10)
CREATE (asbr)-[:CONNECTS {state:'up'}]->(a0)
CREATE (asbr)-[:CONNECTS {state:'up'}]->(a20);
```

- [ ] **Step 2: Write `02_blast_radius.cypher`**

This matches the committed seed edges (`ABR`-`CONNECTS`->`OSPFArea`, `Prefix`-`ORIGINATES_IN`->area, `Prefix`-`SUPPORTS`->`BusinessService`). Returns `abr-01` (down), Area 10, `10.30.10.0/24`, Order API.

```cypher
// Beat 3 — the 3 AM question: if a boundary router loses an area, which
// business services lose inter-area reachability? Run after `make seed`.
MATCH (abr:ABR)-[:CONNECTS]->(area:OSPFArea)
MATCH (prefix:Prefix)-[:ORIGINATES_IN]->(area)
MATCH (prefix)-[:SUPPORTS]->(service:BusinessService)
RETURN abr.name AS abr, abr.status AS abr_status, area.name AS area,
       collect(DISTINCT prefix.cidr) AS dependent_prefixes,
       collect(DISTINCT service.name) AS impacted_services
ORDER BY abr;
```

- [ ] **Step 3: Write `03_three_questions.cypher`**

Three separate statements (each is its own paste-and-run):

```cypher
// Beat 4 — Q1: which prefixes originate in each area, and on which LSA type?
MATCH (prefix:Prefix)-[:ORIGINATES_IN]->(area:OSPFArea)
OPTIONAL MATCH (prefix)-[:ADVERTISED_BY]->(lsa:LSA)-[:HAS_LSA_TYPE]->(type:LSAType)
RETURN area.name AS area, prefix.cidr AS prefix,
       prefix.visibility AS visibility, collect(DISTINCT type.name) AS lsa_types
ORDER BY area, prefix;

// Beat 4 — Q2: which required external route is blocked by an area restriction?
MATCH (area:OSPFArea)-[restriction:RESTRICTS]->(type:LSAType)
MATCH (route:ExternalRoute)-[:CARRIED_BY_LSA]->(:LSA)-[:HAS_LSA_TYPE]->(type)
WHERE restriction.action = 'deny' AND route.required = true
RETURN area.name AS area, area.area_type AS area_type,
       route.cidr AS blocked_route, type.name AS restricted_lsa_type,
       restriction.reason AS reason
ORDER BY area;

// Beat 4 — Q3: LSA lineage — which LSA carries each modeled prefix?
MATCH (prefix:Prefix)-[:ADVERTISED_BY]->(lsa:LSA)-[:HAS_LSA_TYPE]->(type:LSAType)
RETURN prefix.cidr AS prefix, lsa.name AS lsa,
       type.number AS lsa_type_number, lsa.status AS lsa_status
ORDER BY prefix;
```

- [ ] **Step 4: Write `04_break_it.cypher`**

Two statements: repair the backbone link (health returns), then break it (impact returns). Re-run `02_blast_radius.cypher` after each to watch the change.

```cypher
// Beat 4 — repair abr-01's backbone link, then re-run 02_blast_radius.cypher.
MATCH (abr:ABR {name:'abr-01'})-[c:CONNECTS]->(a0:OSPFArea {area_id:'0.0.0.0'})
SET c.state = 'up', abr.status = 'up'
RETURN abr.name AS abr, abr.status AS status, c.state AS backbone_link;

// Beat 4 — break it again, then re-run 02_blast_radius.cypher. Order API returns.
MATCH (abr:ABR {name:'abr-01'})-[c:CONNECTS]->(a0:OSPFArea {area_id:'0.0.0.0'})
SET c.state = 'down', abr.status = 'down'
RETURN abr.name AS abr, abr.status AS status, c.state AS backbone_link;
```

- [ ] **Step 5: Write `your_network_template.cypher`**

Fill-in block; the learner changes only `<REPLACE…>` values. Tagged `vexpertai-builder` so `make reset` never wipes it. Uses seed-real labels/edges so `02_blast_radius.cypher` finds it.

```cypher
// Beat 5 — YOUR NETWORK. Change only the <REPLACE...> values; keep the shape.
// Paste, run, then re-run 02_blast_radius.cypher to see YOUR service impacted.
CREATE (area:OSPFArea:NormalArea {
    area_id:'<REPLACE: your area id, e.g. 0.0.0.42>',
    name:'<REPLACE: area name, e.g. Campus Area 42>',
    area_type:'normal', dataset:'vexpertai-builder'})
CREATE (abr:Device:OSPFRouter:ABR {
    name:'<REPLACE: your ABR hostname>',
    router_id:'<REPLACE: its router-id>',
    status:'down', dataset:'vexpertai-builder'})
CREATE (prefix:Prefix {
    cidr:'<REPLACE: a prefix that area originates, e.g. 10.20.30.0/24>',
    dataset:'vexpertai-builder'})
CREATE (service:BusinessService {
    name:'<REPLACE: a service that rides that prefix>',
    criticality:'critical', dataset:'vexpertai-builder'})
CREATE (abr)-[:CONNECTS {state:'up'}]->(area)
CREATE (prefix)-[:ORIGINATES_IN]->(area)
CREATE (prefix)-[:SUPPORTS]->(service);
```

- [ ] **Step 6: Write `starter_shapes.cypher`**

Reference stencils (comments plus one runnable example). No invented edges.

```cypher
// Beat 5 — the canonical shapes your network is made of. Reuse these patterns;
// your whole graph is these repeated. (Reference — the example at the bottom runs.)
//
//   (BusinessService)-[:DEPENDS_ON]->(Prefix)
//   (Prefix)-[:SUPPORTS]->(BusinessService)
//   (Prefix)-[:ORIGINATES_IN]->(OSPFArea)
//   (Prefix)-[:ADVERTISED_BY]->(LSA)-[:HAS_LSA_TYPE]->(LSAType)
//   (Device:OSPFRouter:ABR)-[:CONNECTS]->(OSPFArea)
//   (StubArea)-[:RESTRICTS]->(LSAType)
//   (ExternalRoute)-[:CARRIED_BY_LSA]->(LSA)
//
// Runnable example of the service->prefix->area shape (tagged so reset keeps it):
CREATE (svc:BusinessService {name:'Example Service', dataset:'vexpertai-builder'})
CREATE (p:Prefix {cidr:'198.51.100.0/24', dataset:'vexpertai-builder'})
CREATE (a:OSPFArea:NormalArea {area_id:'0.0.0.99', name:'Example Area', dataset:'vexpertai-builder'})
CREATE (p)-[:SUPPORTS]->(svc)
CREATE (p)-[:ORIGINATES_IN]->(a);
```

- [ ] **Step 7: Run the static lint to verify it passes**

Run: `pytest tests/test_lab_cypher.py -q`
Expected: PASS (all `test_lab_file_exists_and_parses` and `test_lab_file_uses_only_known_labels_and_rels` cases green).

- [ ] **Step 8: Confirm the offline suite is still green**

Run: `pytest -q`
Expected: PASS, no failures (existing suite plus the new offline lint).

- [ ] **Step 9: Commit**

```bash
git add cypher/lab/
git commit -m "feat(lab): add six tested Cypher blocks for the KG lab"
```

---

## Task 4: Live integration check (skips without a seeded DB)

Adds a DB-dependent test that runs the blast-radius block against a seeded graph and asserts Order API is impacted. It **skips** cleanly when Neo4j is down or the seed isn't loaded, so `pytest -q` stays green offline.

**Files:**
- Modify: `tests/test_lab_cypher.py` (append)

- [ ] **Step 1: Append the live test**

Add to the end of `tests/test_lab_cypher.py`:

```python
def _seeded_driver():
    """Return a driver to a seeded DB, or skip if unavailable/unseeded."""
    try:
        from src.db import create_driver

        driver = create_driver()
        with driver.session() as session:
            count = session.run(
                "MATCH (a:OSPFArea {dataset:'vexpertai-design-ontology'}) "
                "RETURN count(a) AS c"
            ).single()["c"]
    except Exception as exc:  # noqa: BLE001 - any connection failure -> skip
        pytest.skip(f"Neo4j not available: {exc}")
    if count == 0:
        driver.close()
        pytest.skip("design dataset not loaded - run `make seed` first")
    return driver


def test_blast_radius_returns_order_api():
    driver = _seeded_driver()
    try:
        statement = load_cypher_file(LAB_DIR / "02_blast_radius.cypher")[-1]
        with driver.session() as session:
            rows = [record.data() for record in session.run(statement)]
    finally:
        driver.close()
    impacted = {svc for row in rows for svc in row.get("impacted_services", [])}
    assert "Order API" in impacted, f"expected Order API in {impacted}"
```

- [ ] **Step 2: Verify it skips offline (no Neo4j running)**

Run: `pytest tests/test_lab_cypher.py -rs -q`
Expected: the lint tests PASS and `test_blast_radius_returns_order_api` shows as SKIPPED with reason "Neo4j not available: ..." (or "run `make seed` first"). Overall exit code 0.

- [ ] **Step 3: (If Docker available) verify it passes against a seeded DB**

Run:
```bash
make up && make seed && pytest tests/test_lab_cypher.py::test_blast_radius_returns_order_api -q
```
Expected: PASS. (If Docker is unavailable in this environment, note that and rely on Step 2 + the later dry run in Task 8.)

- [ ] **Step 4: Commit**

```bash
git add tests/test_lab_cypher.py
git commit -m "test(lab): add skipped live blast-radius integration check"
```

---

## Task 5: The guided lab document

Prose deliverable — write in Edy's voice. **Before writing, invoke the `edy` skill** so the voice matches the existing OSPF post. No unit test; verification is a structural checklist (Step 2).

**Files:**
- Create: `docs/lab/build-your-own-kg.md`

- [ ] **Step 1: Write the guided doc**

Invoke the `edy` skill, then write `docs/lab/build-your-own-kg.md` with exactly these sections. All fixed text below is verbatim; the connecting prose is Edy's to write. Do NOT reorder — DO precedes UNDERSTAND in every beat, and the schema/ontology concept must not appear before Beat 5.

Required content, in order:

1. **Title + one-line promise:** "Build a knowledge graph of a network you run — in about an hour. No graph-database or coding experience assumed."
2. **The frame (verbatim, near the top):**
   > "You already run the world's biggest graph database — it's called OSPF. Every router is a node, every adjacency an edge, SPF is a traversal. A knowledge graph is that same machine, except *you* choose what counts as a node — so you can finally add the one node OSPF never had: the business service that dies when the route does."
3. **Setup (Beat 1 DO):** "Run `make up`, open `http://localhost:7474`, log in `neo4j` / `password123`." Then: paste `cypher/lab/01_first_five_nodes.cypher`, then run `MATCH (n) RETURN n`. State the expected result: the five nodes draw themselves and are draggable. Note this needs Docker only — no Python yet.
4. **"The five words you need" sidebar (Beat 1 UNDERSTAND, AFTER the graph is on screen):** node, edge, label, property, Cypher — each defined pointing at what they just created (e.g. "`abr-01` is a node; `CONNECTS` is an edge; `:OSPFArea` is a label; `state:'down'` is a property; Cypher is the language you just used").
5. **Beat 2:** drag nodes / click to inspect properties (DO), then UNDERSTAND: why a graph beats a SQL table / CMDB / spreadsheet (relationships are stored objects you walk). Reference the fuller explanation in `docs/substack_ospf_kg_for_beginners.md`.
6. **Beat 3 — the whoa:** "Clear your sandbox with `MATCH (n) DETACH DELETE n`, then run `make seed`." (Explain: seed only clears the design dataset, so wipe the sandbox first.) Then paste `cypher/lab/02_blast_radius.cypher`. State the expected result verbatim: `abr-01`, status `down`, Area 10, `10.30.10.0/24`, **Order API**. UNDERSTAND: a routing event just produced a business consequence in five lines — the thing no `show` command tells you.
7. **Beat 4:** run the three statements in `cypher/lab/03_three_questions.cypher`; then run the two statements in `cypher/lab/04_break_it.cypher`, re-running `02_blast_radius.cypher` after each to watch the impacted set change. UNDERSTAND (the one rule, verbatim): "Cypher is ASCII-art of the shape you want — `MATCH` draws it, `RETURN` reports it."
8. **Beat 5 — your network (schema becomes visible here, not before):** open `cypher/lab/your_network_template.cypher`, change only the `<REPLACE…>` values to a real area/ABR/prefix/service, run it, then re-run `02_blast_radius.cypher` to see their own service impacted. Introduce the ontology idea lightly ("the shapes you've been snapping together are the ontology — the RFC written as a schema") and the stop-modeling rule (verbatim): "Model the nouns of your design review, not the numbers of your monitoring dashboard." Point to `cypher/lab/starter_shapes.cypher` as the parts bin.
9. **Beat 6 — graduate:** point to the KG Builder wizard (start the app with `uvicorn src.api:app --reload`, open the Build tab / `/kg-builder`), pick their real protocol mix, preview, save — no hand-Cypher needed. Present the growth ladder: OSPF → add BGP redistribution → add an MPLS overlay → cross-protocol interaction view.
10. **Troubleshooting box (the 3 classic errors):** missing trailing `;` between statements; label case (`:ospfarea` vs `:OSPFArea`); mistyped relationship (`-[:CONNECT]->` vs `-[:CONNECTS]->`). Each with the fix.
11. **Safety note (verbatim intent):** "Everything you create is tagged `dataset:'vexpertai-builder'`. `make reset` reloads the demo without touching your work — the lab itself has blast-radius isolation."

- [ ] **Step 2: Verify structure (self-check, no tool)**

Confirm all of the following are true, fixing inline if not:
- The frame paragraph appears before any Cypher.
- Every beat has DO before UNDERSTAND.
- The words "ontology" and "schema" do not appear before Beat 5.
- Each beat references its concrete `cypher/lab/*.cypher` file by name.
- Beat 3 tells the reader to `DETACH DELETE` the sandbox before `make seed`.
- The three fixed quotes (frame, "ASCII-art", stop-modeling rule) appear verbatim.

- [ ] **Step 3: Commit**

```bash
git add docs/lab/build-your-own-kg.md
git commit -m "docs(lab): add the guided one-hour KG lab"
```

---

## Task 6: Saved-query retention pack

**Files:**
- Create: `docs/lab/saved-queries.md`

- [ ] **Step 1: Write the saved-query pack**

Create `docs/lab/saved-queries.md` — a short doc with three copy-paste blocks framed for the incident/change loop. Use seed-real edges. Content:

```markdown
# Keep-these-open queries

Three queries worth saving as Neo4j Browser favorites. Run them during a real
incident or before a change window — they answer questions your CLI can't.

## 1. What breaks if a router fails?
(Change `abr-01` to the device you're touching.)

    MATCH (r {name:'abr-01'})-[:CONNECTS]->(area:OSPFArea)
    MATCH (prefix:Prefix)-[:ORIGINATES_IN]->(area)
    MATCH (prefix)-[:SUPPORTS]->(service:BusinessService)
    RETURN service.name AS at_risk_service, service.criticality AS criticality,
           collect(DISTINCT prefix.cidr) AS prefixes
    ORDER BY criticality;

## 2. What depends on this prefix?

    MATCH (prefix:Prefix {cidr:'10.30.10.0/24'})-[:SUPPORTS]->(service:BusinessService)
    RETURN service.name AS service, service.criticality AS criticality;

## 3. Blast radius of a change (rank areas by dependent services)

    MATCH (area:OSPFArea)<-[:ORIGINATES_IN]-(prefix:Prefix)-[:SUPPORTS]->(service:BusinessService)
    RETURN area.name AS area, count(DISTINCT service) AS services_at_risk
    ORDER BY services_at_risk DESC;
```

- [ ] **Step 2: Verify the queries lint clean**

These are documentation, not in `cypher/lab/`, so add a quick manual check: every label and relationship used above is in `ALLOWED_LABELS`/`ALLOWED_RELS` from `tests/test_lab_cypher.py`. Confirm: `OSPFArea`, `Prefix`, `BusinessService`, `CONNECTS`, `ORIGINATES_IN`, `SUPPORTS` — all present. (No code change; a consistency check.)

- [ ] **Step 3: Commit**

```bash
git add docs/lab/saved-queries.md
git commit -m "docs(lab): add saved-query retention pack"
```

---

## Task 7: Verify the wizard graduation with Playwright MCP

Verification gate (requires the app running). Confirms Beat 6's hand-off to the existing KG Builder wizard actually works. Produces no committed artifact — it either passes or surfaces a bug to fix.

**Files:** none created.

- [ ] **Step 1: Bring up the stack**

Run (in the background / separate shells):
```bash
make up && make seed
./.venv/bin/uvicorn src.api:app --reload
```
Expected: API on `http://localhost:8000` serving the frontend; Neo4j seeded.

- [ ] **Step 2: Drive the wizard with Playwright MCP**

Using the Playwright MCP browser tools, perform and assert:
1. Navigate to `http://localhost:8000` and open the Build tab (KG Builder).
2. Select the `OSPF` technology, then `BGP`.
3. Trigger Preview; assert the preview graph returns nodes/edges (the `/kg-builder/preview` response is non-empty) and that the BGP-without-IGP recommendation is absent (OSPF is selected).
4. Enter a profile name (e.g. `lab-graduation-check`) and Save.
5. Assert the profile now appears in the saved profiles list (`GET /kg-builder/profiles`).

- [ ] **Step 3: Record the outcome**

If all assertions pass, note "graduation flow verified" in the PR description later. If anything fails, stop and fix the underlying issue (it is a real bug the lab depends on) before proceeding.

- [ ] **Step 4: Tear down**

Run: `make down`

---

## Task 8: End-to-end dry run

Verification gate. Follow the lab verbatim on a clean state to catch friction the tests can't.

**Files:** none created.

- [ ] **Step 1: Fresh environment**

Run:
```bash
make down && docker volume rm $(docker volume ls -q | grep neo4j) 2>/dev/null || true
make up
```
Expected: a clean, empty, healthy Neo4j.

- [ ] **Step 2: Walk beats 1–5 exactly as written**

Follow `docs/lab/build-your-own-kg.md` step by step, pasting each `cypher/lab/*.cypher` block into the Neo4j Browser:
- After Beat 1: `MATCH (n) RETURN n` shows 5 nodes.
- After Beat 3 (`DETACH DELETE` + `make seed` + `02_blast_radius.cypher`): Order API row appears.
- After Beat 5 (`your_network_template.cypher` with real values + re-run blast radius): the learner's own service appears.

- [ ] **Step 3: Fix any friction inline**

If any command, path, or query doesn't work exactly as the doc says, fix the doc or the Cypher, re-run `pytest tests/test_lab_cypher.py -q`, and commit the fix:
```bash
git add -A && git commit -m "fix(lab): correct friction found in dry run"
```

- [ ] **Step 4: Final suite check**

Run: `pytest -q`
Expected: PASS (offline suite green; live blast-radius test passes if DB is up, else skips).

---

## Acceptance criteria (from the spec)

- `make up && make seed` goes from clean clone to seeded graph with no manual steps beyond those two commands. (Tasks 1, 8)
- All six `cypher/lab/*.cypher` blocks execute cleanly; `02_blast_radius.cypher` returns the Order API row. (Tasks 3, 4)
- `docs/lab/build-your-own-kg.md` walks seven beats, DO-before-UNDERSTAND, schema hidden until Beat 5, in Edy's voice. (Task 5)
- `tests/test_lab_cypher.py` passes; `pytest -q` stays green offline. (Tasks 2, 3, 4)
- The graduation beat drives the existing KG Builder wizard (Playwright-verified). (Task 7)
- A learner can, unaided, mutate the template into their own network and get a blast-radius answer. (Tasks 3, 8)
```
