// 1. Which business services are impacted by a VXLAN tunnel failure?
MATCH (incident:Incident)-[:CONTAINS]->(alert:Alert)-[:OBSERVED_ON]->(overlay:VXLANOverlay)
MATCH (incident)-[:IMPACTS]->(service:BusinessService)
WHERE alert.name = 'VXLAN tunnel down'
RETURN incident.id AS incident, overlay.name AS overlay,
       service.name AS impacted_service, service.criticality AS criticality;

// 2. Which underlay dependency likely caused the overlay failure?
MATCH (alert:Alert {id: 'ALT-VXLAN-001'})-[:OBSERVED_ON]->(overlay:VXLANOverlay)
MATCH (alert)-[:OBSERVED_ON]->(device:Device)-[:HOSTS]->(vtep:VTEP)
MATCH (overlay)-[:DEPENDS_ON]->(:EVPNControlPlane)-[:DEPENDS_ON]->(vtep)
MATCH (vtep)-[:DEPENDS_ON]->(underlay:UnderlayRouting)-[:DEPENDS_ON]->(link:PhysicalLink)
MATCH (link)-[:HAS_ENDPOINT]->(interface:Interface)
WHERE interface.status = 'degraded'
RETURN overlay.name AS overlay, device.name AS device, vtep.name AS vtep,
       underlay.name AS underlay,
       link.name AS likely_failed_link, interface.id AS degraded_interface,
       interface.crc_errors AS crc_errors;

// 3. Which VNI, VRF, and business service depend on a given VTEP?
MATCH (vtep:VTEP {id: 'vtep-leaf-01'})<-[:DEPENDS_ON]-(:EVPNControlPlane)
      <-[:DEPENDS_ON]-(overlay:VXLANOverlay)-[:CARRIES]->(vni:VNI)-[:MAPS_TO]->(vrf:VRF)
MATCH (service:BusinessService)-[:DEPENDS_ON]->(overlay)
MATCH (service)-[:DEPENDS_ON]->(vni)
MATCH (service)-[:DEPENDS_ON]->(vrf)
RETURN vtep.name AS vtep, vni.number AS vni, vrf.name AS vrf,
       service.name AS business_service;

// 4. Which prefixes are redistributed from OSPF into BGP?
MATCH (ospf:OSPFProcess)-[:REDISTRIBUTES_TO]->(bgp:BGPProcess)
MATCH (rule:RedistributionRule)-[:SOURCE]->(ospf)
MATCH (rule)-[:TARGET]->(bgp)
MATCH (rule)-[:APPLIES_TO]->(prefix:Prefix)
RETURN ospf.name AS source, bgp.name AS target, rule.name AS rule,
       prefix.cidr AS prefix, prefix.current_state AS current_state;

// 5. Which route-map and prefix-list control 10.20.30.0/24?
MATCH (rule:RedistributionRule)-[:APPLIES_TO]->(prefix:Prefix {cidr: '10.20.30.0/24'})
MATCH (rule)-[:CONTROLLED_BY]->(routeMap:RouteMap)-[:REFERENCES]->(prefixList:PrefixList)
MATCH (routeMap)-[:SETS]->(community:Community)
RETURN prefix.cidr AS prefix, rule.name AS redistribution_rule,
       routeMap.name AS route_map, prefixList.name AS prefix_list,
       prefixList.current_action AS current_action, community.value AS community;

// 6. Which recent change likely caused 10.20.30.0/24 to disappear?
MATCH (change:Change)-[:MODIFIES]->(prefixList:PrefixList)-[:CONTROLS]->(prefix:Prefix)
WHERE prefix.cidr = '10.20.30.0/24'
RETURN change.id AS change, change.timestamp AS timestamp,
       change.summary AS reason, prefixList.name AS modified_object;

// 7. What evidence supports the RCA?
MATCH (incident:Incident)-[:SUPPORTED_BY]->(evidence:Evidence)
RETURN incident.id AS incident, incident.name AS incident_name,
       evidence.name AS evidence, evidence.summary AS summary,
       evidence.source AS source
ORDER BY incident.id;

// 8. What recommendation should be followed before remediation?
MATCH (validation:ValidationRun)-[:TESTS]->(recommendation:Recommendation)
      -[:BASED_ON]->(evidence:Evidence)
RETURN recommendation.name AS recommendation, recommendation.action AS action,
       recommendation.risk AS risk, validation.name AS validation,
       validation.status AS validation_status, evidence.name AS based_on
ORDER BY recommendation;
