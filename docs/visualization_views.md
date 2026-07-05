# Visualization Views

The UI deliberately renders bounded views rather than the entire graph:

1. Protocol local views show nodes owned by one protocol module.
2. Interaction views show only explicit cross-protocol edges.
3. Service views trace infrastructure and policy to a business service.
4. Failure views follow dependency paths from one failed entity.
5. Change views show modified policy, affected routes, services, evidence, and
   recommendations.

FastAPI returns stable node and edge JSON. Cytoscape.js lays out each bounded
view and exposes selected-node properties, summary text, and recommendations.
The limits in `graph_queries.py` prevent accidental graph hairballs.
