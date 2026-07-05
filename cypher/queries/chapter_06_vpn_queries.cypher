// 1. VPN services depending on each underlay transport.
MATCH (vpn:VPNService)-[:DEPENDS_ON]->(underlay:UnderlayTransport)
RETURN underlay.name AS underlay_transport, underlay.status AS underlay_status,
       collect(DISTINCT vpn.name) AS dependent_vpn_services,
       collect(DISTINCT vpn.status) AS vpn_states
ORDER BY underlay_transport;

// 2. Applications impacted by a failed or degraded tunnel.
MATCH (application:Application)-[:DEPENDS_ON]->(vpn:VPNService)
MATCH (vpn)-[:HAS_TUNNEL]->(tunnel:IPsecTunnel)-[:HAS_HEALTH]->(health:TunnelHealth)
WHERE health.status <> 'up'
OPTIONAL MATCH (service:BusinessService)-[:DEPENDS_ON]->(application)
RETURN tunnel.name AS tunnel, tunnel.crypto_state AS crypto_state,
       health.status AS tunnel_health, vpn.name AS vpn_service,
       collect(DISTINCT application.name) AS impacted_applications,
       collect(DISTINCT service.name) AS impacted_business_services;

// 3. VRFs importing each route target.
MATCH (target:RouteTarget)
OPTIONAL MATCH (vrf:VRF)-[:IMPORTS]->(target)
OPTIONAL MATCH (route:VPNRoute)-[:IMPORTED_BY]->(target)
RETURN target.value AS route_target,
       collect(DISTINCT vrf.name) AS importing_vrfs,
       collect(DISTINCT route.cidr) AS eligible_routes,
       CASE WHEN count(vrf) = 0 THEN 'no matching import' ELSE 'import configured' END
         AS import_state
ORDER BY route_target;

// 4. Tunnels with crypto established but routed reachability down.
MATCH (tunnel:IPsecTunnel)-[:HAS_STATE]->(ike:IKEState)
MATCH (tunnel)-[:HAS_STATE]->(routing:RoutingState)
OPTIONAL MATCH (tunnel)-[:HAS_HEALTH]->(health:TunnelHealth)
WHERE ike.state = 'up' AND routing.state = 'down'
RETURN tunnel.name AS tunnel, tunnel.crypto_state AS crypto_state,
       ike.state AS ike_state, routing.state AS routing_state,
       routing.reason AS routing_reason, health.status AS health;

// 5. VPN designs exposing asymmetric routing risk.
MATCH (vpn)-[:EXPOSES_VPN_RISK]->(risk:AsymmetricRoutingRisk)
WHERE vpn:VPNService OR vpn:MPLSL3VPN OR vpn:DMVPN
RETURN vpn.name AS vpn_design, labels(vpn) AS vpn_types,
       risk.name AS risk, risk.severity AS severity,
       risk.likelihood AS likelihood
ORDER BY severity, vpn_design;

// 6. Evidence distinguishing tunnel establishment from routing root cause.
MATCH (tunnel:IPsecTunnel)-[:HAS_STATE]->(state)
WHERE state:IKEState OR state:RoutingState
MATCH (evidence:Evidence)-[:SUPPORTS_STATE]->(state)
RETURN tunnel.name AS tunnel, labels(state) AS state_type,
       state.state AS state, evidence.name AS evidence,
       evidence.summary AS summary, evidence.source AS source,
       CASE
         WHEN state:IKEState AND state.state = 'up'
           THEN 'crypto established; not the primary failure'
         WHEN state:RoutingState AND state.state = 'down'
           THEN 'routing failure supported'
         ELSE 'additional validation required'
       END AS rca_interpretation
ORDER BY state_type;
