// Beat 5 — YOUR NETWORK. Change only the <REPLACE...> values; keep the shape.
// Run once: these statements CREATE new nodes, so re-pasting duplicates them.
// Your ABR gets a DOWN link to the backbone (area 0) — the failure the
// blast-radius query looks for — plus an UP link to your new area.
// Paste, run, then re-run 02_blast_radius.cypher to see YOUR service impacted.
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
