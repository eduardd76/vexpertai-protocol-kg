// 1. Which services depend on each MPLS LSP?
MATCH (service:MPLSService)-[:DEPENDS_ON]->(lsp:MPLSLSP)
OPTIONAL MATCH (business:BusinessService)-[:DEPENDS_ON]->(service)
RETURN lsp.name AS lsp,
       lsp.state AS lsp_state,
       collect(DISTINCT service.name) AS dependent_mpls_services,
       collect(DISTINCT business.name) AS dependent_business_services
ORDER BY lsp;

// 2. Which VPN routes are imported into each VRF?
MATCH (vrf:VRF)-[:IMPORTS]->(target:RouteTarget)
MATCH (target)-[:IMPORTS_VPN_ROUTE]->(route:VPNRoute)
RETURN vrf.name AS vrf,
       target.value AS import_route_target,
       collect(DISTINCT route.prefix) AS imported_vpn_routes
ORDER BY vrf;

// 3. Which route-target mismatch breaks customer reachability?
MATCH (route:VPNRoute)-[:EXPORTED_WITH]->(target:RouteTarget)
MATCH (route)-[:TARGETS_VRF]->(vrf:VRF)
WHERE NOT (vrf)-[:IMPORTS]->(target)
RETURN route.prefix AS missing_customer_prefix,
       route.name AS vpn_route,
       target.value AS exported_route_target,
       vrf.name AS intended_vrf,
       [(vrf)-[:IMPORTS]->(configured:RouteTarget) | configured.value] AS configured_import_targets,
       route.state AS route_state;

// 4. Which prefixes have IGP reachability but no MPLS label?
MATCH (fec:FEC)-[:FEC_FOR_PREFIX]->(prefix:Prefix)
MATCH (prefix)-[:HAS_IGP_REACHABILITY]->(igp:IGPReachability {state: 'up'})
WHERE NOT (fec)<-[:BINDS_FEC]-(:LabelBinding {state: 'installed'})
RETURN prefix.cidr AS prefix,
       igp.name AS igp_reachability,
       igp.state AS igp_state,
       fec.name AS unlabeled_fec,
       fec.state AS fec_state;

// 5. Which LDP sessions are required for each service?
MATCH (service:MPLSService)-[:DEPENDS_ON]->(lsp:MPLSLSP)
      -[:DEPENDS_ON]->(binding:LabelBinding)-[:CREATED_BY]->(ldp:LDP)
OPTIONAL MATCH (ldp)-[:HAS_LDP_ADJACENCY]->(adjacency:LDPAdjacency)
RETURN service.name AS mpls_service,
       lsp.name AS transport_lsp,
       binding.name AS label_binding,
       ldp.name AS label_distribution_process,
       adjacency.name AS required_ldp_session,
       adjacency.state AS session_state,
       adjacency.reason AS session_failure_reason
ORDER BY mpls_service;

// 6. Which underlay failure breaks an MPLS overlay?
MATCH (business:BusinessService)-[:DEPENDS_ON]->(service:MPLSService)
      -[:DEPENDS_ON]->(overlay:ServiceOverlay)-[:DEPENDS_ON]->(underlay:TransportUnderlay)
WHERE underlay.state <> 'up'
RETURN underlay.name AS failed_underlay,
       underlay.state AS underlay_state,
       overlay.name AS broken_overlay,
       service.name AS impacted_mpls_service,
       business.name AS impacted_business_service;

// 7. Which FRR mechanism protects each LSP?
MATCH (frr:FastReroute)-[:PROTECTS]->(lsp:MPLSLSP)
OPTIONAL MATCH (lsp)-[:ENGINEERED_BY]->(tunnel:TrafficEngineeringTunnel)
RETURN lsp.name AS protected_lsp,
       lsp.state AS lsp_state,
       frr.name AS fast_reroute_mechanism,
       frr.state AS protection_state,
       tunnel.name AS protected_te_tunnel;
