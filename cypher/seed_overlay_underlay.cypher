// Physical fabric and location.
MERGE (site:Site {id: 'site-dc1'})
SET site.name = 'Primary Data Center', site.dataset = 'vexpertai-mvp';

MERGE (leaf1:Device {id: 'leaf-01'})
SET leaf1.name = 'leaf-01', leaf1.role = 'leaf', leaf1.platform = 'NX-OS',
    leaf1.dataset = 'vexpertai-mvp'
MERGE (leaf2:Device {id: 'leaf-02'})
SET leaf2.name = 'leaf-02', leaf2.role = 'leaf', leaf2.platform = 'NX-OS',
    leaf2.dataset = 'vexpertai-mvp'
MERGE (spine1:Device {id: 'spine-01'})
SET spine1.name = 'spine-01', spine1.role = 'spine-route-reflector',
    spine1.platform = 'NX-OS', spine1.dataset = 'vexpertai-mvp'
MERGE (spine2:Device {id: 'spine-02'})
SET spine2.name = 'spine-02', spine2.role = 'spine-route-reflector',
    spine2.platform = 'NX-OS', spine2.dataset = 'vexpertai-mvp'
WITH leaf1, leaf2, spine1, spine2
MATCH (site:Site {id: 'site-dc1'})
MERGE (leaf1)-[:LOCATED_IN]->(site)
MERGE (leaf2)-[:LOCATED_IN]->(site)
MERGE (spine1)-[:LOCATED_IN]->(site)
MERGE (spine2)-[:LOCATED_IN]->(site);

MERGE (leafif:Interface {id: 'leaf-01:Ethernet1/49'})
SET leafif.name = 'Ethernet1/49', leafif.status = 'degraded',
    leafif.crc_errors = 1842, leafif.last_flap = '2026-07-05T09:41:12Z',
    leafif.dataset = 'vexpertai-mvp'
MERGE (spineif:Interface {id: 'spine-01:Ethernet1/1'})
SET spineif.name = 'Ethernet1/1', spineif.status = 'up',
    spineif.crc_errors = 0, spineif.dataset = 'vexpertai-mvp'
WITH leafif, spineif
MATCH (leaf:Device {id: 'leaf-01'}), (spine:Device {id: 'spine-01'})
MERGE (leaf)-[:HAS_INTERFACE]->(leafif)
MERGE (spine)-[:HAS_INTERFACE]->(spineif)
MERGE (leafif)-[:CONNECTED_TO]->(spineif);

MERGE (link:Link:PhysicalLink {id: 'link-leaf01-spine01'})
SET link.name = 'leaf-01:Ethernet1/49--spine-01:Ethernet1/1',
    link.status = 'degraded', link.medium = '100G-LR',
    link.dataset = 'vexpertai-mvp'
WITH link
MATCH (leafif:Interface {id: 'leaf-01:Ethernet1/49'}),
      (spineif:Interface {id: 'spine-01:Ethernet1/1'})
MERGE (link)-[:HAS_ENDPOINT]->(leafif)
MERGE (link)-[:HAS_ENDPOINT]->(spineif);

// Underlay routing and EVPN route-reflector processes.
MERGE (underlay:UnderlayRouting {id: 'underlay-fabric'})
SET underlay.name = 'Fabric IPv4 Underlay', underlay.protocol = 'OSPF',
    underlay.process_id = '10', underlay.status = 'degraded',
    underlay.dataset = 'vexpertai-mvp'
WITH underlay
MATCH (link:PhysicalLink {id: 'link-leaf01-spine01'})
MERGE (underlay)-[:DEPENDS_ON]->(link);

MERGE (leafbgp1:BGPProcess {id: 'leaf-01:bgp:65000'})
SET leafbgp1.name = 'leaf-01 BGP EVPN', leafbgp1.asn = 65000,
    leafbgp1.address_family = 'l2vpn-evpn', leafbgp1.dataset = 'vexpertai-mvp'
MERGE (leafbgp2:BGPProcess {id: 'leaf-02:bgp:65000'})
SET leafbgp2.name = 'leaf-02 BGP EVPN', leafbgp2.asn = 65000,
    leafbgp2.address_family = 'l2vpn-evpn', leafbgp2.dataset = 'vexpertai-mvp'
MERGE (spinebgp1:BGPProcess {id: 'spine-01:bgp:65000'})
SET spinebgp1.name = 'spine-01 BGP EVPN RR', spinebgp1.asn = 65000,
    spinebgp1.route_reflector = true, spinebgp1.dataset = 'vexpertai-mvp'
MERGE (spinebgp2:BGPProcess {id: 'spine-02:bgp:65000'})
SET spinebgp2.name = 'spine-02 BGP EVPN RR', spinebgp2.asn = 65000,
    spinebgp2.route_reflector = true, spinebgp2.dataset = 'vexpertai-mvp'
WITH leafbgp1, leafbgp2, spinebgp1, spinebgp2
MATCH (leaf1:Device {id: 'leaf-01'}), (leaf2:Device {id: 'leaf-02'}),
      (spine1:Device {id: 'spine-01'}), (spine2:Device {id: 'spine-02'})
MERGE (leaf1)-[:RUNS]->(leafbgp1)
MERGE (leaf2)-[:RUNS]->(leafbgp2)
MERGE (spine1)-[:RUNS]->(spinebgp1)
MERGE (spine2)-[:RUNS]->(spinebgp2);

MERGE (n1:BGPNeighbor {id: 'spine-01->leaf-01'})
SET n1.name = 'leaf-01 EVPN peer', n1.peer_address = '10.255.0.11',
    n1.session_state = 'flapping', n1.route_reflector_client = true,
    n1.dataset = 'vexpertai-mvp'
MERGE (n2:BGPNeighbor {id: 'spine-01->leaf-02'})
SET n2.name = 'leaf-02 EVPN peer', n2.peer_address = '10.255.0.12',
    n2.session_state = 'established', n2.route_reflector_client = true,
    n2.dataset = 'vexpertai-mvp'
MERGE (n3:BGPNeighbor {id: 'spine-02->leaf-01'})
SET n3.name = 'leaf-01 EVPN peer via spine-02',
    n3.peer_address = '10.255.0.11', n3.session_state = 'established',
    n3.route_reflector_client = true, n3.dataset = 'vexpertai-mvp'
WITH n1, n2, n3
MATCH (spinebgp1:BGPProcess {id: 'spine-01:bgp:65000'}),
      (spinebgp2:BGPProcess {id: 'spine-02:bgp:65000'})
MERGE (spinebgp1)-[:HAS_NEIGHBOR]->(n1)
MERGE (spinebgp1)-[:HAS_NEIGHBOR]->(n2)
MERGE (spinebgp2)-[:HAS_NEIGHBOR]->(n3);

// Overlay objects and their explicit dependencies.
MERGE (vtep1:VTEP {id: 'vtep-leaf-01'})
SET vtep1.name = 'leaf-01 VTEP', vtep1.loopback = '10.255.0.11',
    vtep1.status = 'degraded', vtep1.dataset = 'vexpertai-mvp'
MERGE (vtep2:VTEP {id: 'vtep-leaf-02'})
SET vtep2.name = 'leaf-02 VTEP', vtep2.loopback = '10.255.0.12',
    vtep2.status = 'up', vtep2.dataset = 'vexpertai-mvp'
WITH vtep1, vtep2
MATCH (leaf1:Device {id: 'leaf-01'}), (leaf2:Device {id: 'leaf-02'}),
      (underlay:UnderlayRouting {id: 'underlay-fabric'})
MERGE (leaf1)-[:HOSTS]->(vtep1)
MERGE (leaf2)-[:HOSTS]->(vtep2)
MERGE (vtep1)-[:DEPENDS_ON]->(underlay)
MERGE (vtep2)-[:DEPENDS_ON]->(underlay);

MERGE (evpn:EVPNControlPlane {id: 'evpn-fabric'})
SET evpn.name = 'Production EVPN Control Plane', evpn.status = 'degraded',
    evpn.dataset = 'vexpertai-mvp'
MERGE (overlay:VXLANOverlay {id: 'vxlan-prod'})
SET overlay.name = 'vxlan-prod', overlay.status = 'degraded',
    overlay.dataset = 'vexpertai-mvp'
MERGE (vni:VNI {id: 'vni-10010'})
SET vni.name = 'VNI 10010', vni.number = 10010, vni.type = 'L3',
    vni.dataset = 'vexpertai-mvp'
MERGE (vrf:VRF {id: 'vrf-prod'})
SET vrf.name = 'PROD', vrf.route_distinguisher = '65000:10010',
    vrf.dataset = 'vexpertai-mvp'
MERGE (vlan:VLAN {id: 'vlan-10'})
SET vlan.name = 'PROD-APP', vlan.number = 10, vlan.dataset = 'vexpertai-mvp'
WITH evpn, overlay, vni, vrf, vlan
MATCH (vtep1:VTEP {id: 'vtep-leaf-01'}), (vtep2:VTEP {id: 'vtep-leaf-02'}),
      (spinebgp1:BGPProcess {id: 'spine-01:bgp:65000'}),
      (spinebgp2:BGPProcess {id: 'spine-02:bgp:65000'})
MERGE (overlay)-[:DEPENDS_ON]->(evpn)
MERGE (evpn)-[:DEPENDS_ON]->(vtep1)
MERGE (evpn)-[:DEPENDS_ON]->(vtep2)
MERGE (evpn)-[:SUPPORTED_BY]->(spinebgp1)
MERGE (evpn)-[:SUPPORTED_BY]->(spinebgp2)
MERGE (overlay)-[:CARRIES]->(vni)
MERGE (vni)-[:MAPS_TO]->(vrf)
MERGE (vlan)-[:MAPPED_TO]->(vni);

MERGE (app:Application {id: 'payment-app'})
SET app.name = 'Payment Application', app.owner = 'Payments Engineering',
    app.dataset = 'vexpertai-mvp'
MERGE (service:BusinessService {id: 'payment-service'})
SET service.name = 'Payment-App', service.criticality = 'critical',
    service.status = 'impacted', service.dataset = 'vexpertai-mvp'
MERGE (prefix:Prefix {id: 'prefix-payment-overlay'})
SET prefix.name = 'Payment-App overlay subnet', prefix.cidr = '10.10.10.0/24',
    prefix.dataset = 'vexpertai-mvp'
WITH app, service, prefix
MATCH (overlay:VXLANOverlay {id: 'vxlan-prod'}), (vni:VNI {id: 'vni-10010'}),
      (vrf:VRF {id: 'vrf-prod'})
MERGE (service)-[:DELIVERED_BY]->(app)
MERGE (service)-[:DEPENDS_ON]->(overlay)
MERGE (service)-[:DEPENDS_ON]->(vni)
MERGE (service)-[:DEPENDS_ON]->(vrf)
MERGE (service)-[:DEPENDS_ON]->(prefix)
MERGE (prefix)-[:SUPPORTS]->(service);

// Operational symptom, evidence, impact, and safe next action.
MERGE (alert:Alert {id: 'ALT-VXLAN-001'})
SET alert.name = 'VXLAN tunnel down', alert.severity = 'critical',
    alert.status = 'open', alert.timestamp = '2026-07-05T09:42:00Z',
    alert.dataset = 'vexpertai-mvp'
MERGE (symptom:Symptom {id: 'SYM-VXLAN-TUNNEL-DOWN'})
SET symptom.name = 'VXLAN tunnel down on leaf-01',
    symptom.dataset = 'vexpertai-mvp'
WITH alert, symptom
MATCH (overlay:VXLANOverlay {id: 'vxlan-prod'}), (leaf:Device {id: 'leaf-01'})
MERGE (alert)-[:OBSERVED_ON]->(overlay)
MERGE (alert)-[:OBSERVED_ON]->(leaf)
MERGE (alert)-[:INDICATES]->(symptom);

MERGE (incident:Incident {id: 'INC-OVERLAY-001'})
SET incident.name = 'Payment-App overlay connectivity loss',
    incident.status = 'investigating', incident.severity = 'critical',
    incident.dataset = 'vexpertai-mvp'
MERGE (evidence:Evidence {id: 'EVD-UNDERLAY-CRC-001'})
SET evidence.name = 'CRC errors and OSPF adjacency flap',
    evidence.summary = '1842 CRC errors and an adjacency flap occurred on leaf-01 Ethernet1/49 immediately before the VXLAN alert.',
    evidence.source = 'telemetry://leaf-01/Ethernet1/49',
    evidence.scenario = 'overlay-underlay', evidence.dataset = 'vexpertai-mvp'
WITH incident, evidence
MATCH (alert:Alert {id: 'ALT-VXLAN-001'}),
      (service:BusinessService {id: 'payment-service'}),
      (interface:Interface {id: 'leaf-01:Ethernet1/49'})
MERGE (incident)-[:CONTAINS]->(alert)
MERGE (incident)-[:IMPACTS]->(service)
MERGE (incident)-[:SUPPORTED_BY]->(evidence)
MERGE (evidence)-[:SUPPORTS]->(alert)
MERGE (evidence)-[:OBSERVED_ON]->(interface);

MERGE (recommendation:Recommendation {id: 'REC-VALIDATE-UNDERLAY'})
SET recommendation.name = 'Validate underlay before VXLAN changes',
    recommendation.action = 'Check optics, counters, cabling, and OSPF/BGP adjacency stability on leaf-01 Ethernet1/49 before changing VXLAN configuration.',
    recommendation.risk = 'low', recommendation.dataset = 'vexpertai-mvp'
MERGE (validation:ValidationRun {id: 'VAL-UNDERLAY-001'})
SET validation.name = 'Underlay health validation',
    validation.status = 'pending',
    validation.tests = 'Interface errors, optics, adjacency stability, VTEP reachability',
    validation.dataset = 'vexpertai-mvp'
WITH recommendation, validation
MATCH (evidence:Evidence {id: 'EVD-UNDERLAY-CRC-001'})
MERGE (recommendation)-[:BASED_ON]->(evidence)
MERGE (validation)-[:TESTS]->(recommendation);
