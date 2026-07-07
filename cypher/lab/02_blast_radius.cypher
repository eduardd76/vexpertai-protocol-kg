// Beat 3 — the 3 AM question: if a boundary router loses an area, which
// business services lose inter-area reachability? Run after `make seed`.
MATCH (abr:ABR)-[:CONNECTS]->(area:OSPFArea)
MATCH (prefix:Prefix)-[:ORIGINATES_IN]->(area)
MATCH (prefix)-[:SUPPORTS]->(service:BusinessService)
RETURN abr.name AS abr, abr.status AS abr_status, area.name AS area,
       collect(DISTINCT prefix.cidr) AS dependent_prefixes,
       collect(DISTINCT service.name) AS impacted_services
ORDER BY abr;
