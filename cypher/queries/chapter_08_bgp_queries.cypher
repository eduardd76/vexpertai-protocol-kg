// 1. Which business services depend on a BGP prefix?
MATCH (service:BusinessService)-[:DEPENDS_ON]->(reachability:ServiceReachability)
      -[:DEPENDS_ON]->(route:BGPRoute)-[:REPRESENTS_NLRI]->(prefix:Prefix)
RETURN prefix.cidr AS prefix,
       collect(DISTINCT service.name) AS business_services,
       route.name AS bgp_route,
       route.state AS route_state
ORDER BY prefix;

// 2. Which policy controls this BGP advertisement?
MATCH (policy:RoutePolicy)-[:FILTERS|MODIFIES_ROUTE]->(route:BGPRoute)
OPTIONAL MATCH (route)-[advertisement:ADVERTISED_TO]->(neighbor:BGPNeighbor)
OPTIONAL MATCH (route)-[:REPRESENTS_NLRI]->(prefix:Prefix)
RETURN coalesce(prefix.cidr, route.cidr) AS prefix,
       policy.name AS route_policy,
       policy.action AS policy_action,
       neighbor.name AS neighbor,
       advertisement.state AS advertisement_state
ORDER BY prefix;

// 3. Which prefixes would be lost if a route reflector fails?
MATCH (reflector:RouteReflector)-[:REFLECTS]->(route:BGPRoute)
      -[:REPRESENTS_NLRI]->(prefix:Prefix)
OPTIONAL MATCH (route)-[:REFLECTED_TO]->(client:RouteReflectorClient)
RETURN reflector.name AS route_reflector,
       reflector.status AS reflector_status,
       prefix.cidr AS prefix_at_risk,
       collect(DISTINCT client.name) AS affected_clients
ORDER BY prefix_at_risk;

// 4. Which BGP routes have an unreachable next hop?
MATCH (route:BGPRoute)-[:HAS_NEXT_HOP]->(next_hop:BGPNextHop)
      -[:DEPENDS_ON]->(igp:IGPReachability)
WHERE next_hop.status = 'unreachable' OR igp.state = 'down'
RETURN route.cidr AS prefix,
       route.state AS route_state,
       next_hop.address AS next_hop,
       igp.state AS igp_state,
       igp.reason AS failure_reason
ORDER BY prefix;

// 5. Which IGP dependency controls BGP next-hop reachability?
MATCH (next_hop:BGPNextHop)-[:DEPENDS_ON]->(igp:IGPReachability)
OPTIONAL MATCH (route:BGPRoute)-[:HAS_NEXT_HOP]->(next_hop)
RETURN next_hop.address AS bgp_next_hop,
       collect(DISTINCT route.cidr) AS dependent_prefixes,
       igp.name AS igp_dependency,
       igp.state AS state,
       igp.reason AS reason
ORDER BY bgp_next_hop;

// 6. Which route was selected and why?
MATCH (route:BGPRoute)-[:SELECTED_BY]->(decision:BGPBestPathDecision)
OPTIONAL MATCH (selected_path:SelectedBGPPath)-[:USES_ROUTE]->(route)
OPTIONAL MATCH (selected_path)-[:USES_EXIT]->(exit:InternetEdge)
RETURN route.cidr AS selected_prefix,
       route.name AS selected_route,
       decision.reason AS selection_reason,
       selected_path.name AS selected_path,
       exit.name AS exit_device;

// 7. Which change likely caused the BGP path change?
MATCH (change:Change)-[:MODIFIES]->(control)
WHERE control:RoutePolicy OR control:IGPMetricToExit OR control:PolicyPreference
OPTIONAL MATCH (control:RoutePolicy)-[:FILTERS|MODIFIES_ROUTE]->(policy_route:BGPRoute)
OPTIONAL MATCH (control:IGPMetricToExit)<-[:DEPENDS_ON]-(:HotPotatoRouting)
      -[:USES_EXIT]->(exit:InternetEdge)<-[:USES_EXIT]-(:SelectedBGPPath)
      -[:USES_ROUTE]->(exit_route:BGPRoute)
WITH change, control, coalesce(policy_route, exit_route) AS route
OPTIONAL MATCH (route)-[:REPRESENTS_NLRI]->(prefix:Prefix)
RETURN change.name AS likely_change,
       change.timestamp AS changed_at,
       labels(control) AS changed_control_type,
       control.name AS changed_control,
       coalesce(prefix.cidr, route.cidr) AS affected_prefix,
       change.summary AS evidence
ORDER BY changed_at DESC;
