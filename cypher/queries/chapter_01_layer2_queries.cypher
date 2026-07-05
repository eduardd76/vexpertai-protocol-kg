// 1. VLANs whose STP root and FHRP active role are on different switches.
MATCH (vlan:VLAN)-[:MAPPED_TO]->(stp:STPInstance)-[:ELECTS]->(root:STPRootBridge)
      -[:ROLE_ON]->(rootSwitch:Switch)
MATCH (vlan)-[:USES_FHRP]->(group:HSRPGroup)-[:HAS_ACTIVE_GATEWAY]
      ->(active:FHRPActiveGateway)-[:ROLE_ON]->(activeSwitch:Switch)
WHERE rootSwitch <> activeSwitch
RETURN vlan.vlan_id AS vlan, vlan.name AS vlan_name, stp.name AS stp_instance,
       rootSwitch.name AS stp_root, activeSwitch.name AS fhrp_active,
       'Suboptimal inter-distribution transit' AS effect
ORDER BY vlan;

// 2. Ports blocked by STP and the reason for the non-forwarding state.
MATCH (stp:STPInstance)-[:BLOCKS]->(port:STPBlockedPort)
OPTIONAL MATCH (switch:Switch)-[:HAS_INTERFACE]->(port)
RETURN stp.name AS stp_instance, switch.name AS switch,
       port.name AS blocked_port, port.reason AS reason,
       port.status AS state
ORDER BY stp_instance, blocked_port;

// 3. Access ports protected by BPDU guard.
MATCH (guard:BPDUGuard)-[:PROTECTS]->(port:AccessPort)
OPTIONAL MATCH (bpdu:BPDU)-[:RECEIVED_ON]->(port)
OPTIONAL MATCH (guard)-[:SHUTS_DOWN]->(port)
RETURN port.id AS port, port.status AS status, guard.name AS protection,
       bpdu.name AS observed_bpdu, port.shutdown_reason AS shutdown_reason
ORDER BY port;

// 4. Trunks carrying VLANs with no active endpoints.
MATCH (vlan:VLAN)-[:CARRIED_BY]->(trunk:Trunk)
WHERE vlan.active_endpoints = 0
RETURN trunk.name AS trunk, collect(vlan.vlan_id) AS unused_vlans,
       collect(vlan.name) AS unused_vlan_names,
       trunk.allowed_vlans AS allowed_vlans
ORDER BY trunk;

// 5. Layer 2 risks with business-service impact.
MATCH (risk:Layer2Risk)-[:IMPACTS]->(service:BusinessService)
OPTIONAL MATCH (source)-[:EXPOSES_RISK|MAY_ENABLE]->(risk)
RETURN risk.name AS risk, risk.severity AS severity,
       collect(DISTINCT source.name) AS sources,
       collect(DISTINCT service.name) AS affected_services
ORDER BY severity, risk;

// 6. Compare access designs by fit, failure domain, and tradeoff.
MATCH (design:DesignOption)-[:HAS_TRADEOFF]->(tradeoff:Tradeoff)
WHERE design:LoopedL2Design OR design:LoopFreeL2Design OR design:RoutedAccessDesign
RETURN design.name AS design, design.suitability_score AS suitability_score,
       design.best_for AS best_for, design.failure_domain AS failure_domain,
       design.stp_dependency AS stp_dependency,
       tradeoff.benefit AS benefit, tradeoff.cost AS cost
ORDER BY suitability_score DESC;
