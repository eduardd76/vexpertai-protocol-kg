// 1. Learned EIGRP prefixes without a feasible successor.
MATCH (prefix:Prefix)-[:LEARNED_BY]->(process:EIGRPProcess)
WHERE NOT (:FeasibleSuccessorRoute)-[:PROTECTS]->(prefix)
OPTIONAL MATCH (successor:SuccessorRoute)-[:REPRESENTS_PREFIX]->(prefix)
RETURN prefix.cidr AS prefix, prefix.name AS prefix_name,
       process.name AS learned_by, successor.name AS successor,
       successor.state AS successor_state,
       prefix.convergence_state AS convergence_state
ORDER BY prefix;

// 2. Routers in each EIGRP query domain and stub scope reduction.
MATCH (router)-[:PART_OF_QUERY_DOMAIN]->(domain:QueryDomain)
WHERE router:EIGRPRouter OR router:HubRouter OR router:StubRouter
OPTIONAL MATCH (router)-[:REDUCES]->(domain)
RETURN domain.name AS query_domain, router.name AS router,
       CASE WHEN router:StubRouter THEN true ELSE false END AS is_stub,
       CASE WHEN (router)-[:REDUCES]->(domain) THEN 'reduces queries'
            ELSE 'query origin or transit' END AS query_behavior,
       domain.router_count AS total_routers,
       domain.effective_query_targets AS effective_query_targets
ORDER BY query_domain, is_stub, router;

// 3. Summary routes that may blackhole required more-specific prefixes.
MATCH (summary:SummaryRoute)-[:HIDES]->(prefix:SpecificPrefix)
WHERE summary.discard_route = true
RETURN summary.cidr AS summary, summary.state AS summary_state,
       prefix.cidr AS hidden_prefix, prefix.visibility AS prefix_visibility,
       prefix.required AS required,
       CASE
         WHEN prefix.required = true AND prefix.visibility = 'missing'
           THEN 'blackhole risk'
         ELSE 'covered'
       END AS assessment
ORDER BY summary, hidden_prefix;

// 4. Services whose hub-and-spoke reachability depends on a hub router.
MATCH (service:BusinessService)-[:DEPENDS_ON]->(reach:HubSpokeReachability)
      -[:DEPENDS_ON]->(hub:HubRouter)
OPTIONAL MATCH (service)-[:DEPENDS_ON]->(overlay:DMVPNOverlay)
RETURN hub.name AS hub_router, reach.name AS reachability,
       reach.state AS reachability_state, overlay.name AS dmvpn_overlay,
       collect(DISTINCT service.name) AS dependent_services
ORDER BY hub_router;

// 5. Redistribution policy exposing feedback or loop risk.
MATCH (policy:RedistributionPolicy)-[:EXPOSES_FEEDBACK_RISK]->(risk:Risk)
OPTIONAL MATCH (policy)-[:CONTROLLED_BY]->(routeMap:RouteMap)
OPTIONAL MATCH (risk)-[:MITIGATED_BY]->(control:Control)
RETURN policy.name AS redistribution_policy, policy.direction AS direction,
       policy.tagging AS tagging, routeMap.name AS route_map,
       risk.name AS risk, risk.severity AS severity,
       collect(control.name) AS mitigation_controls,
       CASE WHEN count(control) = 0 THEN 'unmitigated' ELSE 'mitigated' END
         AS mitigation_state
ORDER BY severity, risk;

// 6. EIGRP metric component changed before a related incident.
MATCH (change:Change)-[:MODIFIES]->(component)
MATCH (metric:EIGRPMetric)-[:HAS_METRIC_COMPONENT]->(component)
MATCH (successor:SuccessorRoute)-[:SELECTED_BY]->(metric)
MATCH (successor)-[:REPRESENTS_PREFIX]->(prefix:Prefix)
      -[:SUPPORTS]->(service:BusinessService)
MATCH (incident:Incident)-[:IMPACTS]->(service)
WHERE change.timestamp < incident.timestamp
RETURN change.id AS change, change.timestamp AS change_time,
       labels(component) AS component_type, component.name AS metric_component,
       component.previous_value AS previous_value,
       component.value AS current_value, prefix.cidr AS affected_prefix,
       incident.id AS incident, incident.timestamp AS incident_time
ORDER BY change_time DESC;
