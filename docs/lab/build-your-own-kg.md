# Build Your Own Knowledge Graph — a one-hour hands-on lab

Build a knowledge graph of a network you run — in about an hour. No graph-database or coding experience assumed.

One may ask why a network engineer should sit down and build a knowledge graph at all. Most engineers already have a mental picture: a graph database sounds like machine learning, embeddings, some data-science thing that lives far from the CLI. In reality it is much closer to home than that.

> You already run the world's biggest graph database — it's called OSPF. Every router is a node, every adjacency an edge, SPF is a traversal. A knowledge graph is that same machine, except *you* choose what counts as a node — so you can finally add the one node OSPF never had: the business service that dies when the route does.

That is the whole idea of this lab. You already think in nodes and edges every day. Here you just get to choose the nodes. This is a shorter, hands-on companion to the longer walk-through in [`docs/substack_ospf_kg_for_beginners.md`](../substack_ospf_kg_for_beginners.md) — that post explains the *why* in depth; this one is the *do*. You paste, you run, you watch the graph draw itself. Everything runs from the Neo4j Browser and a few `make` targets.

A handful of short beats. Each beat you *do* something first, then you understand what you did. In about an hour you go from an empty database to a graph of a network you actually run.

---

## Beat 1 — your first five nodes

**Do this first.** Bring up the database and draw a graph by hand.

```bash
make up
```

This starts Neo4j in Docker and waits until it is healthy. You need Docker for this — nothing else yet. No Python, no virtual environment, no `pip install`. Just the database.

Now open `http://localhost:7474`, log in with `neo4j` / `password123`. The web page has a query bar at the top — this is where every block below gets pasted and run with the play arrow.

Paste the whole content of [`cypher/lab/01_first_five_nodes.cypher`](../../cypher/lab/01_first_five_nodes.cypher) into that bar and press play:

```cypher
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

Then run one more line:

```cypher
MATCH (n) RETURN n
```

**What you should see.** Five nodes draw themselves on the canvas — three areas and two routers — wired together by `CONNECTS` links. And they are *draggable*. Grab one with the mouse and the rest follow on their rubber bands. That is your first graph. Two boundary routers, three areas, and the `abr-01` uplink into Area 0 already marked `state:'down'` — the failure is in there from the first second.

### The five words you need

Now that the graph is on screen, here is the whole vocabulary. Point at what you just created:

- **Node** — a thing. `abr-01` is a node. `Area 0` is a node. On the canvas it is a circle you can drag.
- **Edge** — a named, directed link between two nodes. `CONNECTS` is an edge. Read `(abr)-[:CONNECTS]->(a0)` literally as "abr connects to a0".
- **Label** — the type of a node, after a colon. `:OSPFArea` is a label. `:Router` is a label. It is how you say *what kind* of thing a node is.
- **Property** — a key/value on a node or an edge. `state:'down'` is a property on the edge. `router_id:'10.255.3.1'` is a property on the node.
- **Cypher** — the language you just used. `CREATE` and `MATCH` are Cypher. Think SQL, but instead of joining tables you draw the shape you are looking for.

That is it. Five words, and you already used all five. The rest of this lab is these five ideas repeated.

---

## Beat 2 — walk the graph with your hands

**Do this first.** Drag the nodes apart until the shape is readable. Then click a single node — `abr-01` — and look at the panel that opens. You see its properties: `role: ABR`, `router_id`, and so on. Click the edge between `abr-01` and `Area 0` and you see its property too: `state: down`. Click, drag, inspect. Spend two minutes here. You are reading the graph the same way you read a topology diagram, only this one you can query.

**Now understand why this beats a table.** A network engineer will ask immediately — why not a SQL table, or my CMDB, or a spreadsheet? Fair question, and it deserves a straight answer.

You can store the *things* in any database. The difference is the *relationships*. In a spreadsheet, `abr-01` is a row and `Area 0` is a row and the fact that one connects to the other lives nowhere — or it lives in a third sheet nobody updates. In SQL, "what connects to what, and then what depends on that" is a different multi-table JOIN for every new question. In a graph the relationship is a stored object you walk directly. The edge `(abr)-[:CONNECTS {state:'down'}]->(a0)` is not computed at query time — it is *there*, on disk, with its own property, ready to be traversed. A CMDB tells you what exists. A graph tells you what depends on what. That second question is the whole game during an incident, and the longer companion post makes this argument in full.

Even though it looks like a small distinction, it is the whole reason to build the graph. Keep this in mind and the rest of the lab clicks into place.

---

## Beat 3 — the whoa: from a routing event to a business consequence

Your five hand-made nodes were the warm-up. Now the real graph, the one that carries the thing OSPF never had — the business service.

**Do this first.** Clear your sandbox, then load the seed graph.

```cypher
MATCH (n) DETACH DELETE n
```

Then, back in the terminal:

```bash
make seed
```

Why clear the sandbox by hand first? Because `make seed` only clears its *own* dataset — the design graph — before it loads. Your five hand-made nodes were tagged with no dataset at all, so the seed loader would leave them behind and you would end up with two overlapping graphs on the canvas. So you wipe the sandbox yourself with `DETACH DELETE`, then let the seed load clean. `make seed` creates the virtual environment, installs the dependencies and loads the full design graph — this is the step that finally needs Python.

Now paste [`cypher/lab/02_blast_radius.cypher`](../../cypher/lab/02_blast_radius.cypher) and run it:

```cypher
MATCH (abr:ABR)-[:CONNECTS {state:'down'}]->(:OSPFArea {area_id:'0.0.0.0'})
MATCH (abr)-[:CONNECTS]->(area:OSPFArea)
WHERE area.area_id <> '0.0.0.0'
MATCH (prefix:Prefix)-[:ORIGINATES_IN]->(area)
MATCH (prefix)-[:SUPPORTS]->(service:BusinessService)
RETURN abr.name AS abr, area.name AS area,
       collect(DISTINCT prefix.cidr) AS dependent_prefixes,
       collect(DISTINCT service.name) AS impacted_services
ORDER BY abr;
```

**What you should see, stated plainly.** One row comes back: `abr-01`, **Application Area 10**, dependent prefixes `10.30.10.0/24` **and** `10.30.77.0/24`, and impacted services **Order API** *and* **Fraud Detection API**.

Stop and look at what just happened. `abr-01`'s backbone link is down, so Application Area 10 is cut off from the backbone — area 0 — and every service whose prefix originates there loses inter-area reachability, not just one of them. A routing event — one ABR losing its backbone link — produced a *business consequence* in a handful of lines of Cypher. Not a route, not an LSA state, not an interface counter. Two named services, both riding on the same severed area. This is the thing no `show` command tells you. `show ip ospf neighbor` tells you an adjacency dropped. It will never tell you the Order API and the Fraud Detection API are now at risk, because the router has no idea either service exists. The graph does, because you gave it the one node OSPF never had.

That connection — from a downed link to a named service — is the whole point. Everything else in this lab is you learning to build it for your own network.

---

## Beat 4 — ask three questions, then break it and watch

**Do this first.** Run the three statements in [`cypher/lab/03_three_questions.cypher`](../../cypher/lab/03_three_questions.cypher), one at a time. Q1 lists which prefixes originate in each area and on which LSA type. Q2 finds the required external route blocked by a stub-area restriction. Q3 walks the LSA lineage — which LSA carries each prefix. Three questions a router cannot answer in one command, each answered by drawing a shape.

Now the fun part. Open [`cypher/lab/04_break_it.cypher`](../../cypher/lab/04_break_it.cypher). It has two statements. The first *repairs* `abr-01`'s backbone link:

```cypher
MATCH (abr:ABR {name:'abr-01'})-[c:CONNECTS]->(a0:OSPFArea {area_id:'0.0.0.0'})
SET c.state = 'up', abr.status = 'up'
RETURN abr.name AS abr, abr.status AS status, c.state AS backbone_link;
```

Run it. Then re-run `02_blast_radius.cypher`. The whole impact result is **gone** — an empty result, no rows at all. The link is up, inter-area reachability is restored, so there is nothing left to match. Then run the second statement in `04_break_it.cypher`, which sets the link back to `down`. Re-run `02_blast_radius.cypher` again and the row returns — `abr-01`, Application Area 10, both prefixes, both services, Order API and Fraud Detection API together. Break it, query, fix it, query. You are watching the entire impacted set appear and disappear in real time as you flip one edge property, not just a single row toggling — this is second-order thinking made into something you can poke with a mouse.

**Now understand the one rule that makes all of this work.**

> Cypher is ASCII-art of the shape you want — `MATCH` draws it, `RETURN` reports it.

That is the whole language, honestly. When you write `(abr:ABR)-[:CONNECTS]->(area:OSPFArea)` you are drawing a little picture of the pattern you are hunting for — a router, an edge, an area. `MATCH` says "find every place in the graph where this picture fits". `RETURN` says "and tell me these fields from what you found". Once you see Cypher as drawing rather than querying, you stop translating it in your head. You just sketch the shape.

---

## Beat 5 — your network

Until now you ran shapes someone else built. Time to put your own network in.

**Do this first.** Open [`cypher/lab/your_network_template.cypher`](../../cypher/lab/your_network_template.cypher). It is the same shape you already saw — an area, an ABR whose backbone link is down (the same failure), a prefix, a service — but with placeholders:

```cypher
MATCH (backbone:OSPFArea {area_id:'0.0.0.0'})
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
CREATE (abr)-[:CONNECTS {state:'down'}]->(backbone)
CREATE (abr)-[:CONNECTS {state:'up'}]->(area)
CREATE (prefix)-[:ORIGINATES_IN]->(area)
CREATE (prefix)-[:SUPPORTS]->(service);
```

Change *only* the `<REPLACE...>` values. Use a real area from a network you run, a real ABR hostname and router-id, a real prefix that area originates, and the real service that rides that prefix. Do not touch the shape — the labels, the edges and the relationship names stay exactly as they are. Run it once (these are `CREATE` statements, so re-pasting duplicates the nodes). Then re-run `02_blast_radius.cypher`. Now *your* service shows up in the impacted list, right next to the Order API. Your network, in the same graph, answering the same 3 AM question.

**Now understand what you have been doing all along.** Those shapes you kept snapping together — an ABR connecting to an area, a prefix originating in an area, a service supported by a prefix — that is the **ontology**. The ontology is the RFC written as a schema: the agreed set of labels and relationships that are allowed, so that every graph built from it fits together. You never had to learn it as a separate thing. You learned it by building with it. That is on purpose.

And here is the one rule that tells you when to stop modeling:

> Model the nouns of your design review, not the numbers of your monitoring dashboard.

An area is a noun. An ABR is a noun. A business service is a noun. Those go in the graph. The interface counters, the CPU load, the per-flow telemetry — those are numbers, they belong in your monitoring system, and the graph only *references* them. If a thing shows up when you argue about a design, it is probably a node. If it shows up on a Grafana panel, it is probably not. Keep that line and your graph stays a design graph instead of turning into a second, worse copy of your telemetry.

When you want more shapes to build with, open [`cypher/lab/starter_shapes.cypher`](../../cypher/lab/starter_shapes.cypher). It is the parts bin — the canonical patterns your whole graph is made of, listed in one place: prefix-to-LSA lineage, stub-area restrictions, external routes carried by an LSA. Your entire network is these few shapes, repeated.

---

## Beat 6 — graduate to the wizard

Hand-Cypher is the right way to *learn* the shapes. It is not the right way to model a whole network — nobody wants to type a hundred `CREATE` statements. So once the shapes are in your fingers, you graduate to the builder.

**Do this first.** Start the application:

```bash
uvicorn src.api:app --reload
```

Open `http://localhost:8000`, go to the **Build custom KG** tab (the `/kg-builder` wizard). Pick your real protocol mix from the catalog, preview the graph it would generate, and save the profile. No hand-Cypher. The wizard writes the shapes for you, snapping together the same ontology you just learned by hand — which is exactly why the hand-work came first. Now you can *read* what the wizard produces, because you built the same thing yourself five minutes ago.

From here the growth ladder is straightforward, one rung at a time:

- **Start with OSPF** — the graph you just built, areas and ABRs and services.
- **Add BGP redistribution** — model the ASBR pulling external reachability in, and now "which service depends on a redistributed route" becomes a query.
- **Add an MPLS overlay** — the overlay and underlay links become their own nodes, so you can walk from a service down to the physical path that carries it.
- **Cross-protocol interaction view** — the payoff. Where OSPF hands to BGP, where the overlay rides the underlay, where one protocol's failure becomes another's. The interaction is a shape too, and once it is a shape you can query it.

Each rung is the same move you already made in Beat 5: add the nouns, keep the shapes, ask the question the router cannot.

---

## Troubleshooting — three classic errors

Three mistakes catch almost everyone the first time. Here is each one and its fix.

- **Missing `;` between statements.** If you paste a block and Neo4j complains about a syntax error near the second `CREATE`, you probably dropped the semicolon that ends the previous statement. Each full statement is terminated by `;` — the loader and the browser split on it. The fix: put the `;` back between statements.

- **Label case.** `:ospfarea` is *not* the same as `:OSPFArea`. Labels are case-sensitive, so a lowercase label creates a brand-new, empty node type and your `MATCH` returns nothing. The fix: match the exact case — `:OSPFArea`, `:Router`, `:BusinessService`.

- **Mistyped relationship.** `-[:CONNECT]->` is not `-[:CONNECTS]->`. A relationship type with a missing letter is a different relationship, so your traversal finds no edges even though the graph looks right on the canvas. The fix: check the relationship name character for character against the shape you meant.

All three fail the same way — the query runs but returns nothing, or errors on a statement boundary. When a query comes back empty and you expected rows, suspect one of these three first.

---

## A safety note

One last thing, so you can experiment without fear. Everything you create in this lab is tagged `dataset:'vexpertai-builder'`. That tag is not decoration — it is blast-radius isolation for the graph itself. `make reset` reloads the demo design graph without touching a single node tagged `vexpertai-builder`, because each loader only clears its own dataset. So you can wreck the demo, reset it, and your own network is still sitting there untouched.

In this way the lab practices what it preaches. The whole point of the graph is to make blast radius visible and bounded — and the lab environment gives you exactly that on your own experiments. Build freely. `make reset` is your undo, and it can't reach your work.

---

## In conclusion

You started with an empty database and, in about an hour, built a graph that answers the one question OSPF never could — which business service dies when a route does. The moves were always the same: bring up the database, draw five nodes by hand, learn the five words by pointing at them, load the seed graph, break it and watch the impact change, then put your own network in using the same shapes. No machine learning, no magic — just nodes, edges, and a language that draws the shape you want.

The important idea is not OSPF and it is not Neo4j. It is that you already run a graph database in your head every time you reason about a failure, and now you have a place to write that reasoning down where it can be queried instead of remembered. From here the ladder goes up — BGP redistribution, an MPLS overlay, the cross-protocol interaction view — but every rung is the same move you already made. Add the nouns of your design review, keep the shapes, and ask the question the router cannot.
