// 1. Prefixes whose OSPF lineage originates in each area.
MATCH (prefix:Prefix)-[:ORIGINATES_IN]->(area:OSPFArea)
OPTIONAL MATCH (prefix)-[:ADVERTISED_BY]->(lsa:LSA)-[:HAS_LSA_TYPE]->(type:LSAType)
RETURN area.area_id AS area_id, area.name AS area,
       prefix.cidr AS prefix, prefix.visibility AS visibility,
       collect(DISTINCT type.name) AS lsa_types
ORDER BY area_id, prefix;

// 2. Services impacted by failure of an ABR and its connected areas.
MATCH (abr:ABR)-[:CONNECTS]->(area:OSPFArea)
MATCH (prefix:Prefix)-[:ORIGINATES_IN]->(area)
MATCH (prefix)-[:SUPPORTS]->(service:BusinessService)
RETURN abr.name AS abr, abr.status AS abr_status, area.name AS area,
       collect(DISTINCT prefix.cidr) AS dependent_prefixes,
       collect(DISTINCT service.name) AS impacted_services
ORDER BY abr;

// 3. External routes imported by each ASBR.
MATCH (asbr:ASBR)-[:REDISTRIBUTES]->(route:ExternalRoute)
OPTIONAL MATCH (route)-[:CARRIED_BY_LSA]->(lsa:LSA)-[:HAS_LSA_TYPE]->(type:LSAType)
RETURN asbr.name AS asbr, route.cidr AS external_route,
       route.visibility AS visibility, lsa.name AS lsa,
       type.name AS lsa_type
ORDER BY asbr, external_route;

// 4. LSA type carrying each modeled prefix.
MATCH (prefix:Prefix)-[:ADVERTISED_BY]->(lsa:LSA)-[:HAS_LSA_TYPE]->(type:LSAType)
RETURN prefix.cidr AS prefix, prefix.name AS prefix_name,
       lsa.name AS lsa, type.number AS lsa_type_number,
       type.name AS lsa_type, lsa.status AS lsa_status
ORDER BY prefix;

// 5. Area type restriction preventing a required external route.
MATCH (area:OSPFArea)-[restriction:RESTRICTS]->(type:LSAType)
MATCH (route:ExternalRoute)-[:CARRIED_BY_LSA]->(lsa:LSA)-[:HAS_LSA_TYPE]->(type)
WHERE restriction.action = 'deny' AND route.required = true
RETURN area.name AS area, area.area_type AS area_type,
       route.cidr AS blocked_route, type.name AS restricted_lsa_type,
       restriction.reason AS reason
ORDER BY area;

// 6. Adjacency dependency associated with route loss.
MATCH (reachability:Reachability)-[:DEPENDS_ON]->(neighbor:OSPFNeighbor)
MATCH (reachability)-[:PROVIDES_REACHABILITY_TO]->(prefix:Prefix)
OPTIONAL MATCH (neighbor)-[:FORMED_OVER]->(interface:OSPFInterface)
OPTIONAL MATCH (prefix)-[:SUPPORTS]->(service:BusinessService)
RETURN reachability.name AS reachability, reachability.state AS reachability_state,
       neighbor.name AS neighbor, neighbor.state AS neighbor_state,
       interface.id AS formed_over, prefix.cidr AS lost_prefix,
       collect(DISTINCT service.name) AS impacted_services;

// 7. BGP routes with OSPF redistribution lineage.
MATCH (route:BGPRoute)-[:ORIGINATED_FROM]->(ospf:OSPFProcess)
OPTIONAL MATCH (route)-[:ORIGINATED_FROM]->(external:ExternalRoute)
OPTIONAL MATCH (route)-[:ORIGINATED_FROM]->(policy:RedistributionPolicy)
OPTIONAL MATCH (policy)-[:CONTROLLED_BY]->(routeMap:RouteMap)
RETURN route.cidr AS bgp_route, route.state AS bgp_state,
       ospf.name AS ospf_origin, external.cidr AS source_route,
       policy.name AS redistribution_policy, routeMap.name AS route_map
ORDER BY bgp_route;
