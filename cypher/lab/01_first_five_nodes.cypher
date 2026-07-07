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
