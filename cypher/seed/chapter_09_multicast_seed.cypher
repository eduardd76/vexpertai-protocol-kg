// Shared multicast domain, membership, sparse-mode tree, and Anycast-RP state.
MERGE (domain:MulticastDomain {id: 'ch9-domain-prod'})
SET domain.name = 'Production Multicast Domain', domain.status = 'degraded',
    domain.dataset = 'vexpertai-design-ontology'
MERGE (igmp:IGMP {id: 'ch9-igmp-access'})
SET igmp.name = 'Access IGMP Membership', igmp.status = 'up',
    igmp.dataset = 'vexpertai-design-ontology'
MERGE (igmpv3:IGMPVersion {id: 'ch9-igmp-v3'})
SET igmpv3.name = 'IGMP Version 3', igmpv3.version = '3',
    igmpv3.dataset = 'vexpertai-design-ontology'
MERGE (pim:PIMProcess:PIMSparseMode {id: 'ch9-pim-sparse'})
SET pim.name = 'Production PIM Sparse Mode', pim.mode = 'sparse',
    pim.status = 'degraded', pim.dataset = 'vexpertai-design-ontology'
MERGE (rp:RendezvousPoint:AnycastRP {id: 'ch9-anycast-rp'})
SET rp.name = 'Anycast RP 10.9.255.9', rp.address = '10.9.255.9',
    rp.status = 'up', rp.dataset = 'vexpertai-design-ontology'
MERGE (msdp:MSDP {id: 'ch9-msdp-state'})
SET msdp.name = 'Anycast RP MSDP Mesh', msdp.state = 'established',
    msdp.dataset = 'vexpertai-design-ontology'
MERGE (sharedState:SharedState {id: 'ch9-rp-shared-state'})
SET sharedState.name = 'Anycast RP Source-Active State', sharedState.state = 'synchronized',
    sharedState.dataset = 'vexpertai-design-ontology'
MERGE (domain)-[:RUNS_PIM]->(pim)
MERGE (domain)-[:USES_RP]->(rp)
MERGE (pim)-[:DEPENDS_ON]->(rp)
MERGE (igmp)-[:HAS_VERSION]->(igmpv3)
MERGE (rp)-[:DEPENDS_ON]->(msdp)
MERGE (rp)-[:DEPENDS_ON]->(sharedState)
MERGE (rp)-[:SYNCHRONIZES_WITH]->(msdp)
MERGE (rp)-[:SYNCHRONIZES_WITH]->(sharedState);

// Scenario 1: receiver joins, but source traffic fails RPF.
MERGE (group:MulticastGroup {id: 'ch9-group-iptv-news'})
SET group.name = 'IPTV News Group', group.group_address = '239.9.10.10',
    group.dataset = 'vexpertai-design-ontology'
MERGE (source:Source:MulticastSource {id: 'ch9-source-iptv'})
SET source.name = 'IPTV Encoder', source.address = '10.9.10.20',
    source.dataset = 'vexpertai-design-ontology'
MERGE (receiver:Receiver:MulticastReceiver {id: 'ch9-receiver-lobby'})
SET receiver.name = 'Lobby IPTV Receiver', receiver.address = '10.9.20.41',
    receiver.state = 'joined', receiver.dataset = 'vexpertai-design-ontology'
MERGE (membership:ReceiverMembership {id: 'ch9-membership-lobby-news'})
SET membership.name = 'Lobby News Membership', membership.state = 'active',
    membership.dataset = 'vexpertai-design-ontology'
MERGE (tree:MulticastTree:SourceTree {id: 'ch9-tree-iptv-news'})
SET tree.name = 'IPTV News Source Tree', tree.state = 'incomplete',
    tree.dataset = 'vexpertai-design-ontology'
MERGE (mapping:RPMapping {id: 'ch9-rp-mapping-iptv'})
SET mapping.name = 'IPTV Anycast-RP Mapping', mapping.state = 'active',
    mapping.source = 'bootstrap', mapping.dataset = 'vexpertai-design-ontology'
MERGE (route:MulticastRoute {id: 'ch9-mroute-iptv-rpf-failed'})
SET route.name = '(10.9.10.20,239.9.10.10)', route.source_address = '10.9.10.20',
    route.group_address = '239.9.10.10', route.state = 'rpf_failed',
    route.dataset = 'vexpertai-design-ontology'
MERGE (check:RPFCheck {id: 'ch9-rpf-iptv'})
SET check.name = 'RPF Check toward IPTV Encoder', check.state = 'failed',
    check.reason = 'unicast route selects Ethernet1/2 instead of incoming Ethernet1/1',
    check.dataset = 'vexpertai-design-ontology'
MERGE (rpfInterface:RPFInterface {id: 'ch9-rpf-interface-ethernet1-2'})
SET rpfInterface.name = 'Ethernet1/2', rpfInterface.status = 'selected_wrong_interface',
    rpfInterface.dataset = 'vexpertai-design-ontology'
MERGE (table:UnicastRoutingTable {id: 'ch9-unicast-table-prod'})
SET table.name = 'PROD Unicast RIB', table.vrf = 'PROD',
    table.dataset = 'vexpertai-design-ontology'
MERGE (unicastRoute:UnicastRoute {id: 'ch9-unicast-route-iptv-source'})
SET unicastRoute.name = '10.9.10.0/24 via Ethernet1/2',
    unicastRoute.prefix = '10.9.10.0/24', unicastRoute.state = 'active_wrong_path',
    unicastRoute.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'ch9-evidence-rpf'})
SET evidence.name = 'RPF counter and unicast lookup',
    evidence.summary = 'IGMP membership is active, while RPF drops increment for 10.9.10.20.',
    evidence.source = 'router multicast and unicast summaries',
    evidence.issue_type = 'RPF', evidence.dataset = 'vexpertai-design-ontology'
MERGE (application:MulticastApplication:IPTVService {id: 'ch9-app-iptv-news'})
SET application.name = 'Corporate IPTV News', application.status = 'unavailable',
    application.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch9-service-iptv'})
SET service.name = 'Corporate Communications', service.criticality = 'medium',
    service.dataset = 'vexpertai-design-ontology'
WITH group, source, receiver, membership, tree, mapping, route, check, rpfInterface,
     table, unicastRoute, evidence, application, service
MATCH (igmp:IGMP {id: 'ch9-igmp-access'})
MATCH (pim:PIMProcess {id: 'ch9-pim-sparse'})
MATCH (domain:MulticastDomain {id: 'ch9-domain-prod'})
MATCH (rp:AnycastRP {id: 'ch9-anycast-rp'})
MERGE (source)-[:SENDS_TO]->(group)
MERGE (receiver)-[:JOINS]->(group)
MERGE (igmp)-[:SIGNALS]->(receiver)
MERGE (igmp)-[:SIGNALS]->(membership)
MERGE (membership)-[:TARGETS_GROUP]->(group)
MERGE (pim)-[:BUILDS]->(tree)
MERGE (domain)-[:HAS_RP_MAPPING]->(mapping)
MERGE (pim)-[:HAS_RP_MAPPING]->(mapping)
MERGE (mapping)-[:MAPS_GROUP]->(group)
MERGE (mapping)-[:MAPS_TO_RP]->(rp)
MERGE (group)-[:HAS_TREE]->(tree)
MERGE (route)-[:HAS_TREE]->(tree)
MERGE (route)-[:HAS_RPF_CHECK]->(check)
MERGE (check)-[:DEPENDS_ON]->(table)
MERGE (check)-[:USES_RPF_INTERFACE]->(rpfInterface)
MERGE (table)-[:CONTAINS_UNICAST_ROUTE]->(unicastRoute)
MERGE (check)-[:USES_UNICAST_ROUTE]->(unicastRoute)
MERGE (evidence)-[:SUPPORTS_MULTICAST_STATE]->(check)
MERGE (application)-[:DEPENDS_ON]->(group)
MERGE (service)-[:DEPENDS_ON]->(application);

// Scenario 2: sparse-mode group has no usable RP mapping.
MERGE (group:MulticastGroup {id: 'ch9-group-training'})
SET group.name = 'Training Video Group', group.group_address = '239.9.20.20',
    group.dataset = 'vexpertai-design-ontology'
MERGE (mapping:RPMapping {id: 'ch9-rp-mapping-missing'})
SET mapping.name = 'Missing Mapping for 239.9.20.20', mapping.state = 'missing',
    mapping.source = 'bootstrap', mapping.dataset = 'vexpertai-design-ontology'
MERGE (bsr:BootstrapRouter {id: 'ch9-bsr-01'})
SET bsr.name = 'BSR-01', bsr.state = 'up',
    bsr.dataset = 'vexpertai-design-ontology'
MERGE (tree:MulticastTree:SharedTree {id: 'ch9-tree-training'})
SET tree.name = 'Training Shared Tree', tree.state = 'not_built',
    tree.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'ch9-evidence-rp'})
SET evidence.name = 'RP mapping lookup',
    evidence.summary = 'No RP mapping exists for group 239.9.20.20.',
    evidence.source = 'show ip pim rp mapping summary',
    evidence.issue_type = 'RP', evidence.dataset = 'vexpertai-design-ontology'
WITH group, mapping, bsr, tree, evidence
MATCH (domain:MulticastDomain {id: 'ch9-domain-prod'})
MATCH (pim:PIMSparseMode {id: 'ch9-pim-sparse'})
MERGE (domain)-[:HAS_RP_MAPPING]->(mapping)
MERGE (pim)-[:HAS_RP_MAPPING]->(mapping)
MERGE (mapping)-[:MAPS_GROUP]->(group)
MERGE (bsr)-[:DISTRIBUTES_RP_MAPPING]->(mapping)
MERGE (pim)-[:BUILDS]->(tree)
MERGE (group)-[:HAS_TREE]->(tree)
MERGE (evidence)-[:SUPPORTS_MULTICAST_STATE]->(mapping);

// Scenario 3: SSM works for source A but source B lacks an active source-specific join.
MERGE (ssm:PIMProcess:PIMSSM {id: 'ch9-pim-ssm'})
SET ssm.name = 'Production PIM SSM', ssm.mode = 'ssm',
    ssm.status = 'partially_available', ssm.dataset = 'vexpertai-design-ontology'
MERGE (group:MulticastGroup {id: 'ch9-group-ssm-telemetry'})
SET group.name = 'Plant Telemetry SSM Group', group.group_address = '232.9.30.30',
    group.dataset = 'vexpertai-design-ontology'
MERGE (sourceA:Source:MulticastSource {id: 'ch9-source-ssm-a'})
SET sourceA.name = 'Telemetry Source A', sourceA.address = '10.9.30.11',
    sourceA.dataset = 'vexpertai-design-ontology'
MERGE (sourceB:Source:MulticastSource {id: 'ch9-source-ssm-b'})
SET sourceB.name = 'Telemetry Source B', sourceB.address = '10.9.30.12',
    sourceB.dataset = 'vexpertai-design-ontology'
MERGE (receiver:Receiver:MulticastReceiver {id: 'ch9-receiver-telemetry'})
SET receiver.name = 'Telemetry Collector', receiver.address = '10.9.31.50',
    receiver.state = 'joined', receiver.dataset = 'vexpertai-design-ontology'
MERGE (joinA:SourceSpecificJoin {id: 'ch9-ssm-join-a'})
SET joinA.name = 'Join Source A and Telemetry Group', joinA.state = 'active',
    joinA.dataset = 'vexpertai-design-ontology'
MERGE (joinB:SourceSpecificJoin {id: 'ch9-ssm-join-b'})
SET joinB.name = 'Join Source B and Telemetry Group', joinB.state = 'missing_source_membership',
    joinB.dataset = 'vexpertai-design-ontology'
MERGE (routeA:MulticastRoute {id: 'ch9-mroute-ssm-a'})
SET routeA.name = '(10.9.30.11,232.9.30.30)', routeA.source_address = '10.9.30.11',
    routeA.group_address = '232.9.30.30', routeA.state = 'forwarding',
    routeA.dataset = 'vexpertai-design-ontology'
MERGE (routeB:MulticastRoute {id: 'ch9-mroute-ssm-b'})
SET routeB.name = '(10.9.30.12,232.9.30.30)', routeB.source_address = '10.9.30.12',
    routeB.group_address = '232.9.30.30', routeB.state = 'no_traffic',
    routeB.dataset = 'vexpertai-design-ontology'
MERGE (membership:ReceiverMembership {id: 'ch9-membership-ssm'})
SET membership.name = 'Telemetry IGMPv3 Membership', membership.state = 'partial',
    membership.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'ch9-evidence-receiver'})
SET evidence.name = 'IGMPv3 source membership',
    evidence.summary = 'Receiver reports source A but omits source B for 232.9.30.30.',
    evidence.source = 'IGMPv3 membership summary',
    evidence.issue_type = 'receiver', evidence.dataset = 'vexpertai-design-ontology'
WITH ssm, group, sourceA, sourceB, receiver, joinA, joinB, membership, evidence
MATCH (domain:MulticastDomain {id: 'ch9-domain-prod'})
MATCH (igmp:IGMP {id: 'ch9-igmp-access'})
MERGE (domain)-[:RUNS_PIM]->(ssm)
MERGE (sourceA)-[:SENDS_TO]->(group)
MERGE (sourceB)-[:SENDS_TO]->(group)
MERGE (receiver)-[:JOINS]->(group)
MERGE (ssm)-[:DEPENDS_ON]->(joinA)
MERGE (ssm)-[:DEPENDS_ON]->(joinB)
MERGE (joinA)-[:SPECIFIES_SOURCE]->(sourceA)
MERGE (joinA)-[:TARGETS_GROUP]->(group)
MERGE (joinB)-[:SPECIFIES_SOURCE]->(sourceB)
MERGE (joinB)-[:TARGETS_GROUP]->(group)
MERGE (igmp)-[:SIGNALS]->(membership)
MERGE (membership)-[:TARGETS_GROUP]->(group)
MERGE (evidence)-[:SUPPORTS_MULTICAST_STATE]->(membership);

// Scenario 4: multicast boundary denies a required application group.
MERGE (boundary:MulticastBoundary {id: 'ch9-boundary-campus'})
SET boundary.name = 'Campus Multicast Boundary', boundary.action = 'deny',
    boundary.interface = 'Ethernet1/48', boundary.dataset = 'vexpertai-design-ontology'
MERGE (group:MulticastGroup {id: 'ch9-group-executive-video'})
SET group.name = 'Executive Video Group', group.group_address = '239.9.40.40',
    group.dataset = 'vexpertai-design-ontology'
MERGE (application:MulticastApplication:IPTVService {id: 'ch9-app-executive-video'})
SET application.name = 'Executive Live Video', application.status = 'blocked',
    application.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch9-service-executive-comms'})
SET service.name = 'Executive Communications', service.criticality = 'high',
    service.dataset = 'vexpertai-design-ontology'
MERGE (risk:MulticastRisk {id: 'ch9-risk-boundary'})
SET risk.name = 'Required group denied at campus boundary', risk.severity = 'critical',
    risk.likelihood = 'high', risk.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'ch9-evidence-boundary'})
SET evidence.name = 'Boundary match counter',
    evidence.summary = 'Deny counter increments for group 239.9.40.40.',
    evidence.source = 'multicast boundary policy summary',
    evidence.issue_type = 'boundary', evidence.dataset = 'vexpertai-design-ontology'
MERGE (boundary)-[:FILTERS {action: 'deny'}]->(group)
MERGE (boundary)-[:EXPOSES_MULTICAST_RISK]->(risk)
MERGE (risk)-[:IMPACTS]->(service)
MERGE (application)-[:DEPENDS_ON]->(group)
MERGE (service)-[:DEPENDS_ON]->(application)
MERGE (evidence)-[:SUPPORTS_MULTICAST_STATE]->(boundary);

// Scenario 5: PIM adjacency failure removes market-data forwarding state.
MERGE (group:MulticastGroup {id: 'ch9-group-market-data'})
SET group.name = 'Equities Market Data', group.group_address = '239.9.50.50',
    group.dataset = 'vexpertai-design-ontology'
MERGE (source:Source:MulticastSource {id: 'ch9-source-market-feed'})
SET source.name = 'Primary Market Feed', source.address = '10.9.50.10',
    source.dataset = 'vexpertai-design-ontology'
MERGE (neighbor:PIMNeighbor {id: 'ch9-pim-neighbor-core'})
SET neighbor.name = 'core-01 10.9.255.1', neighbor.address = '10.9.255.1',
    neighbor.state = 'down', neighbor.reason = 'holdtime expired',
    neighbor.dataset = 'vexpertai-design-ontology'
MERGE (route:MulticastRoute {id: 'ch9-mroute-market-data'})
SET route.name = '(10.9.50.10,239.9.50.50)', route.source_address = '10.9.50.10',
    route.group_address = '239.9.50.50', route.state = 'lost_pim_neighbor',
    route.dataset = 'vexpertai-design-ontology'
MERGE (oil:OIL {id: 'ch9-oil-market-data'})
SET oil.name = 'Market Data OIL', oil.state = 'empty',
    oil.dataset = 'vexpertai-design-ontology'
MERGE (application:MulticastApplication:MarketDataService {id: 'ch9-app-market-data'})
SET application.name = 'Real-Time Equities Feed', application.status = 'unavailable',
    application.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch9-service-trading'})
SET service.name = 'Electronic Trading', service.criticality = 'critical',
    service.dataset = 'vexpertai-design-ontology'
MERGE (risk:MulticastRisk {id: 'ch9-risk-pim-adjacency'})
SET risk.name = 'Market-data PIM adjacency failure', risk.severity = 'critical',
    risk.likelihood = 'medium', risk.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'ch9-evidence-pim'})
SET evidence.name = 'PIM neighbor expiry',
    evidence.summary = 'PIM neighbor 10.9.255.1 expired before market-data route loss.',
    evidence.source = 'PIM adjacency event summary',
    evidence.issue_type = 'PIM', evidence.dataset = 'vexpertai-design-ontology'
WITH group, source, neighbor, route, oil, application, service, risk, evidence
MATCH (pim:PIMProcess {id: 'ch9-pim-sparse'})
MERGE (source)-[:SENDS_TO]->(group)
MERGE (pim)-[:HAS_PIM_NEIGHBOR]->(neighbor)
MERGE (route)-[:DEPENDS_ON]->(neighbor)
MERGE (route)-[:HAS_OIL]->(oil)
MERGE (application)-[:DEPENDS_ON]->(group)
MERGE (service)-[:DEPENDS_ON]->(application)
MERGE (neighbor)-[:EXPOSES_MULTICAST_RISK]->(risk)
MERGE (risk)-[:IMPACTS]->(service)
MERGE (evidence)-[:SUPPORTS_MULTICAST_STATE]->(neighbor);
