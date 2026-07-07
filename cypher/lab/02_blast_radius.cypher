// Beat 3 — the 3 AM question: when a boundary router's backbone link is down,
// the non-backbone areas it serves lose inter-area reachability — so which
// business services are impacted? Run after `make seed`.
MATCH (abr:ABR)-[:CONNECTS {state:'down'}]->(:OSPFArea {area_id:'0.0.0.0'})
MATCH (abr)-[:CONNECTS]->(area:OSPFArea)
WHERE area.area_id <> '0.0.0.0'
MATCH (prefix:Prefix)-[:ORIGINATES_IN]->(area)
MATCH (prefix)-[:SUPPORTS]->(service:BusinessService)
RETURN abr.name AS abr, area.name AS area,
       collect(DISTINCT prefix.cidr) AS dependent_prefixes,
       collect(DISTINCT service.name) AS impacted_services
ORDER BY abr;
