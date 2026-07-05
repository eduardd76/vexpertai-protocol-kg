// 1. From Payment-App business service to all protocol dependencies.
MATCH path=(access:Interface {id: 'global-branch-sw1:Gi1/0/10'})
      -[:SUPPORTS_LAYER*1..12]->(service:BusinessService {id: 'global-business-payment'})
RETURN service.name AS business_service,
       [node IN nodes(path) WHERE node:Protocol | node.name] AS protocol_dependencies,
       [node IN nodes(path) | node.name] AS end_to_end_dependency_chain;

// 2. From a simulated failed interface to impacted business services.
MATCH path=(interface:Interface {simulated_status: 'failed'})
      -[:SUPPORTS_LAYER*1..12]->(service:BusinessService)
RETURN interface.id AS failed_interface,
       interface.name AS interface_name,
       service.name AS impacted_business_service,
       service.criticality AS criticality,
       [node IN nodes(path) | node.name] AS blast_radius_path;

// 3. From route-policy change to impacted prefixes and applications.
MATCH (change:Change)-[:MODIFIES]->(prefix_list:PrefixList)
      -[:CONTROLS_PREFIX]->(prefix:Prefix)
MATCH (route_map:RouteMap)-[:REFERENCES]->(prefix_list)
MATCH (prefix)-[:SUPPORTS_LAYER]->(application:Application)
      -[:SUPPORTS_LAYER]->(service:BusinessService)
RETURN change.id AS change,
       change.timestamp AS changed_at,
       prefix_list.name AS responsible_prefix_list,
       route_map.name AS responsible_route_map,
       prefix.cidr AS impacted_prefix,
       collect(DISTINCT application.name) AS impacted_applications,
       collect(DISTINCT service.name) AS impacted_business_services;

// 4. From underlay failure to overlay services.
MATCH (overlay:OverlayService)-[:DEPENDS_ON]->(underlay)
WHERE (underlay:TransportUnderlay OR underlay:UnderlayRouting
       OR underlay:ISISUnderlay OR underlay:IGPReachability)
  AND coalesce(underlay.state, underlay.status, 'unknown') <> 'up'
RETURN underlay.name AS failed_underlay,
       coalesce(underlay.state, underlay.status) AS underlay_state,
       collect(DISTINCT overlay.name) AS impacted_overlay_services;

// 5. From design requirement to valid design options.
MATCH (option:DesignOption)-[:SATISFIES]->(requirement:Requirement)
WHERE NOT (option)-[:VIOLATES]->(:Constraint)
OPTIONAL MATCH (decision:DesignDecision)-[:SELECTS]->(option)
RETURN requirement.name AS requirement,
       requirement.priority AS priority,
       collect(DISTINCT option.name) AS valid_design_options,
       collect(DISTINCT decision.name) AS selecting_decisions
ORDER BY priority, requirement;

// 6. From change to complete blast radius.
MATCH (change:Change {id: 'global-change-pl-payment'})
OPTIONAL MATCH (change)-[:AFFECTS]->(prefix:Prefix)
OPTIONAL MATCH (change)-[:AFFECTS]->(application:Application)
OPTIONAL MATCH (change)-[:AFFECTS]->(service:BusinessService)
OPTIONAL MATCH (change)-[:INTRODUCES_RISK]->(risk:Risk)
OPTIONAL MATCH (service)-[:OWNED_BY]->(owner:ServiceOwner)
RETURN change.name AS change,
       collect(DISTINCT prefix.cidr) AS affected_prefixes,
       collect(DISTINCT application.name) AS affected_applications,
       collect(DISTINCT service.name) AS affected_services,
       collect(DISTINCT risk.name) AS introduced_risks,
       collect(DISTINCT owner.name) AS accountable_owners;

// 7. From risk to mitigation and validation plan.
MATCH (risk:Risk)-[:MITIGATED_BY]->(recommendation:Recommendation)
MATCH (validation:ValidationRun)-[:TESTS]->(recommendation)
OPTIONAL MATCH (recommendation)-[:BASED_ON]->(evidence:Evidence)
OPTIONAL MATCH (risk)-[:OWNED_BY]->(owner:ServiceOwner)
RETURN risk.name AS risk,
       risk.severity AS severity,
       recommendation.name AS mitigation,
       recommendation.action AS safe_action,
       validation.name AS validation_plan,
       validation.status AS validation_status,
       evidence.name AS supporting_evidence,
       owner.name AS accountable_owner;
