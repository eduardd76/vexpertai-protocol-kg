// Shared physical, location, application, SLA, and ownership objects.
MERGE (region:Region {id: 'view-region-east'})
SET region.name = 'East Region', region.dataset = 'vexpertai-design-ontology'
MERGE (branch:Site {id: 'view-site-branch-01'})
SET branch.name = 'Branch-01', branch.dataset = 'vexpertai-design-ontology'
MERGE (dc:Site {id: 'view-site-dc-01'})
SET dc.name = 'DC-01', dc.dataset = 'vexpertai-design-ontology'
MERGE (distributionRole:Role {id: 'view-role-distribution'})
SET distributionRole.name = 'Campus Distribution', distributionRole.dataset = 'vexpertai-design-ontology'
MERGE (edgeRole:Role {id: 'view-role-dc-edge'})
SET edgeRole.name = 'Data Center Edge', edgeRole.dataset = 'vexpertai-design-ontology'
MERGE (dist1:Device {id: 'view-device-dist-01'})
SET dist1.name = 'Dist-01', dist1.module = 'fhrp',
    dist1.dataset = 'vexpertai-design-ontology'
MERGE (dist2:Device {id: 'view-device-dist-02'})
SET dist2.name = 'Dist-02', dist2.module = 'fhrp',
    dist2.dataset = 'vexpertai-design-ontology'
MERGE (edge:Device {id: 'view-device-dc-edge-01'})
SET edge.name = 'DC-EDGE-01', edge.module = 'bgp',
    edge.dataset = 'vexpertai-design-ontology'
MERGE (pe:Device:ProviderEdge {id: 'view-device-pe-01'})
SET pe.name = 'PE-01', pe.module = 'mpls',
    pe.dataset = 'vexpertai-design-ontology'
MERGE (access:Interface:AccessPort {id: 'view-interface-branch-access'})
SET access.name = 'GigabitEthernet1/0/10', access.status = 'up',
    access.module = 'fhrp', access.dataset = 'vexpertai-design-ontology'
MERGE (uplink:Interface {id: 'view-interface-ethernet1-49'})
SET uplink.name = 'Ethernet1/49', uplink.status = 'failed',
    uplink.module = 'ospf', uplink.dataset = 'vexpertai-design-ontology'
MERGE (peer:Interface {id: 'view-interface-dc-edge-ethernet1-49'})
SET peer.name = 'DC-EDGE-01 Ethernet1/49', peer.status = 'up',
    peer.module = 'ospf', peer.dataset = 'vexpertai-design-ontology'
MERGE (link:Link:PhysicalLink {id: 'view-link-branch-dc'})
SET link.name = 'Branch-to-DC Underlay Link', link.status = 'failed',
    link.dataset = 'vexpertai-design-ontology'
MERGE (vlan:VLAN {id: 'view-vlan-100'})
SET vlan.name = 'User VLAN 100', vlan.vlan_id = 100,
    vlan.module = 'fhrp', vlan.dataset = 'vexpertai-design-ontology'
MERGE (vrf:VRF {id: 'view-vrf-prod'})
SET vrf.name = 'PROD', vrf.module = 'mpls',
    vrf.dataset = 'vexpertai-design-ontology'
MERGE (endpoint:ApplicationEndpoint {id: 'view-endpoint-payment'})
SET endpoint.name = 'Payment-App 10.20.30.10', endpoint.address = '10.20.30.10',
    endpoint.port = 443, endpoint.dataset = 'vexpertai-design-ontology'
MERGE (application:Application {id: 'view-application-payment'})
SET application.name = 'Payment-App', application.status = 'unreachable',
    application.module = 'application', application.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'view-service-payment'})
SET service.name = 'Payment-App', service.criticality = 'critical',
    service.status = 'impacted', service.dataset = 'vexpertai-design-ontology'
MERGE (sla:SLA:SLARequirement:LatencyRequirement {id: 'view-sla-payment'})
SET sla.name = 'Payment-App Low Latency SLA', sla.metric = 'latency',
    sla.threshold = '<=200ms', sla.priority = 'critical',
    sla.acceptance_criteria = 'Branch HTTPS probes meet latency and availability targets.',
    sla.dataset = 'vexpertai-design-ontology'
MERGE (owner:Owner:ServiceOwner {id: 'view-owner-payments'})
SET owner.name = 'Payments Platform Team', owner.team = 'Payments SRE',
    owner.dataset = 'vexpertai-design-ontology'
MERGE (branch)-[:BELONGS_TO]->(region)
MERGE (dc)-[:BELONGS_TO]->(region)
MERGE (dist1)-[:LOCATED_IN]->(branch)
MERGE (dist2)-[:LOCATED_IN]->(branch)
MERGE (edge)-[:LOCATED_IN]->(dc)
MERGE (pe)-[:LOCATED_IN]->(dc)
MERGE (dist1)-[:HAS_ROLE]->(distributionRole)
MERGE (dist2)-[:HAS_ROLE]->(distributionRole)
MERGE (edge)-[:HAS_ROLE]->(edgeRole)
MERGE (dist1)-[:HAS_INTERFACE]->(access)
MERGE (dist1)-[:HAS_INTERFACE]->(uplink)
MERGE (edge)-[:HAS_INTERFACE]->(peer)
MERGE (uplink)-[:CONNECTED_TO]->(peer)
MERGE (link)-[:HAS_ENDPOINT]->(uplink)
MERGE (link)-[:HAS_ENDPOINT]->(peer)
MERGE (access)-[:BELONGS_TO]->(vlan)
MERGE (application)-[:USES]->(endpoint)
MERGE (application)-[:DEPENDS_ON]->(vrf)
MERGE (service)-[:DEPENDS_ON]->(application)
MERGE (service)-[:HAS_SLA]->(sla)
MERGE (service)-[:OWNED_BY]->(owner);
