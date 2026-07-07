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
