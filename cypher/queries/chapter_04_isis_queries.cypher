// 1. Business services whose overlay path depends on an IS-IS adjacency.
MATCH (service:BusinessService)-[:DEPENDS_ON]->(overlay)
WHERE overlay:MPLSOverlay OR overlay:SegmentRoutingOverlay
MATCH (overlay)-[:DEPENDS_ON]->(underlay:ISISUnderlay)
      -[:DEPENDS_ON]->(reachability:Reachability)
      -[:DEPENDS_ON]->(adjacency:ISISAdjacency)
RETURN adjacency.name AS adjacency, adjacency.state AS adjacency_state,
       reachability.state AS reachability_state,
       collect(DISTINCT overlay.name) AS dependent_overlays,
       collect(DISTINCT service.name) AS dependent_services
ORDER BY adjacency;

// 2. Prefixes visible only at Level 2 because no Level 1 leak exists.
MATCH (route:Level2Route)-[:REPRESENTS_PREFIX]->(prefix:Prefix)
WHERE NOT (route)-[:LEAKED_TO]->(:Level1)
RETURN prefix.cidr AS prefix, prefix.name AS prefix_name,
       prefix.visibility AS visibility, route.name AS level2_route,
       prefix.required_in_level1 AS required_in_level1
ORDER BY prefix;

// 3. Route leaking policy controlling each cross-level prefix.
MATCH (route)-[:REPRESENTS_PREFIX]->(prefix:Prefix)
WHERE route:Level1Route OR route:Level2Route
OPTIONAL MATCH (route)-[:LEAKED_BY]->(policy:RouteLeakingPolicy)
OPTIONAL MATCH (policy)-[:CONTROLS_PREFIX]->(prefix)
RETURN prefix.cidr AS prefix,
       coalesce(policy.name, 'No route leaking policy') AS leaking_policy,
       policy.direction AS direction, policy.action AS action,
       CASE
         WHEN (route)-[:LEAKED_TO]->() THEN 'leaked'
         ELSE 'not leaked'
       END AS leak_state
ORDER BY prefix;

// 4. Routers excluded from transit by the overload bit.
MATCH (router:ISISRouter)-[:HAS_OVERLOAD_BIT]->(bit:OverloadBit)
      -[:SUPPRESSES]->(role:TransitRole)
WHERE bit.set = true
RETURN router.name AS router, bit.reason AS overload_reason,
       role.name AS transit_role, role.status AS transit_status
ORDER BY router;

// 5. Segment Routing SIDs and their IS-IS advertisement dependencies.
MATCH (sid)
WHERE sid:PrefixSID OR sid:NodeSID OR sid:AdjacencySID
OPTIONAL MATCH (sid)-[:ADVERTISED_BY]->(tlv:ISISTLV)
OPTIONAL MATCH (sid)-[:REQUIRES_CAPABILITY]->(capability:Capability)
RETURN sid.name AS sid, labels(sid) AS sid_labels, sid.sid AS sid_value,
       sid.status AS status, tlv.name AS advertised_by,
       capability.name AS required_capability,
       CASE WHEN tlv IS NULL THEN 'missing advertisement' ELSE 'advertised' END
         AS advertisement_state
ORDER BY sid;

// 6. Overlay services that break when the IS-IS underlay fails.
MATCH (service:BusinessService)-[:DEPENDS_ON]->(overlay)
WHERE overlay:MPLSOverlay OR overlay:SegmentRoutingOverlay
MATCH (overlay)-[:DEPENDS_ON]->(underlay:ISISUnderlay)
      -[:DEPENDS_ON]->(reachability:Reachability)
WHERE underlay.status = 'down' OR reachability.state = 'lost'
RETURN underlay.name AS failed_underlay, underlay.status AS underlay_status,
       reachability.state AS reachability_state,
       overlay.name AS impacted_overlay, service.name AS impacted_service,
       service.criticality AS criticality
ORDER BY impacted_service;
