// IS-IS routers, process, levels, area identity, and metric/topology modes.
MERGE (core:Device:ISISRouter:Level1Level2Router {id: 'ch4-isis-core-01'})
SET core.name = 'isis-core-01', core.status = 'up',
    core.dataset = 'vexpertai-design-ontology'
MERGE (edge:Device:ISISRouter {id: 'ch4-isis-edge-01'})
SET edge.name = 'isis-edge-01', edge.status = 'up',
    edge.dataset = 'vexpertai-design-ontology'
MERGE (access:Device:ISISRouter {id: 'ch4-isis-access-01'})
SET access.name = 'isis-access-01', access.status = 'up',
    access.dataset = 'vexpertai-design-ontology'
MERGE (process:ISISProcess {id: 'ch4-isis-process-core'})
SET process.name = 'Core IS-IS Process', process.system_id = '0000.0000.0001',
    process.dataset = 'vexpertai-design-ontology'
MERGE (level1:ISISLevel:Level1 {id: 'ch4-level-1'})
SET level1.name = 'Level 1', level1.level = 'L1',
    level1.dataset = 'vexpertai-design-ontology'
MERGE (level2:ISISLevel:Level2 {id: 'ch4-level-2'})
SET level2.name = 'Level 2', level2.level = 'L2',
    level2.dataset = 'vexpertai-design-ontology'
MERGE (area:ISISArea {id: 'ch4-area-49.0001'})
SET area.name = 'Metro Area 49.0001', area.area_address = '49.0001',
    area.dataset = 'vexpertai-design-ontology'
MERGE (net:NET {id: 'ch4-net-core-01'})
SET net.name = 'Core NET', net.value = '49.0001.0000.0000.0001.00',
    net.dataset = 'vexpertai-design-ontology'
MERGE (system:SystemID {id: 'ch4-system-core-01'})
SET system.name = 'Core System ID', system.value = '0000.0000.0001',
    system.dataset = 'vexpertai-design-ontology'
MERGE (core)-[:RUNS]->(process)
MERGE (process)-[:RUNS_ON]->(core)
MERGE (process)-[:HAS_LEVEL]->(level1)
MERGE (process)-[:HAS_LEVEL]->(level2)
MERGE (process)-[:HAS_NET]->(net)
MERGE (core)-[:HAS_NET]->(net)
MERGE (net)-[:HAS_SYSTEM_ID]->(system)
MERGE (core)-[:HAS_SYSTEM_ID]->(system)
MERGE (area)-[:CONTAINS]->(core)
MERGE (area)-[:CONTAINS]->(edge)
MERGE (area)-[:CONTAINS]->(access);

MERGE (wide:MetricStyle:WideMetric {id: 'ch4-wide-metric'})
SET wide.name = 'Wide Metrics', wide.style = 'wide',
    wide.dataset = 'vexpertai-design-ontology'
MERGE (narrow:MetricStyle:NarrowMetric {id: 'ch4-narrow-metric'})
SET narrow.name = 'Narrow Metrics', narrow.style = 'narrow',
    narrow.dataset = 'vexpertai-design-ontology'
MERGE (ipv6:IPv6Topology {id: 'ch4-ipv6-topology'})
SET ipv6.name = 'IPv6 Unicast Topology',
    ipv6.dataset = 'vexpertai-design-ontology'
MERGE (multi:MultiTopologyISIS {id: 'ch4-multi-topology'})
SET multi.name = 'IS-IS Multi-Topology Mode',
    multi.dataset = 'vexpertai-design-ontology'
MERGE (single:SingleTopologyISIS {id: 'ch4-single-topology'})
SET single.name = 'IS-IS Single-Topology Compatibility',
    single.dataset = 'vexpertai-design-ontology'
WITH wide, narrow, ipv6, multi, single
MATCH (process:ISISProcess {id: 'ch4-isis-process-core'})
MERGE (process)-[:USES_METRIC_STYLE]->(wide)
MERGE (process)-[:HAS_TOPOLOGY]->(ipv6)
MERGE (multi)-[:HAS_TOPOLOGY]->(ipv6)
MERGE (single)-[:HAS_TOPOLOGY]->(ipv6);

// LSP and TLV lineage.
MERGE (lsp:LSP:ISISLSP {id: 'ch4-lsp-core-01'})
SET lsp.name = 'core-01 LSP', lsp.sequence = 1042, lsp.lifetime = 1180,
    lsp.dataset = 'vexpertai-design-ontology'
MERGE (reachTlv:TLV:ISISTLV {id: 'ch4-tlv-ip-reachability'})
SET reachTlv.name = 'Extended IP Reachability TLV', reachTlv.type = 135,
    reachTlv.dataset = 'vexpertai-design-ontology'
MERGE (srTlv:TLV:ISISTLV {id: 'ch4-tlv-sr-capability'})
SET srTlv.name = 'Segment Routing Capability TLV', srTlv.type = 242,
    srTlv.dataset = 'vexpertai-design-ontology'
MERGE (prefix:Prefix {id: 'ch4-prefix-core-loopback'})
SET prefix.name = 'Core Loopback', prefix.cidr = '10.255.4.1/32',
    prefix.dataset = 'vexpertai-design-ontology'
MERGE (capability:Capability {id: 'ch4-capability-segment-routing'})
SET capability.name = 'IS-IS Segment Routing Capability',
    capability.dataset = 'vexpertai-design-ontology'
WITH lsp, reachTlv, srTlv, prefix, capability
MATCH (core:ISISRouter {id: 'ch4-isis-core-01'})
MERGE (lsp)-[:GENERATED_BY]->(core)
MERGE (lsp)-[:HAS_TLV]->(reachTlv)
MERGE (lsp)-[:HAS_TLV]->(srTlv)
MERGE (reachTlv)-[:ADVERTISES]->(prefix)
MERGE (srTlv)-[:ADVERTISES]->(capability);

// Scenario 1: Level 2 external prefix has no permitted leak into Level 1.
MERGE (externalPrefix:Prefix {id: 'ch4-prefix-external-service'})
SET externalPrefix.name = 'External Shared Service', externalPrefix.cidr = '198.51.100.0/24',
    externalPrefix.required_in_level1 = true, externalPrefix.visibility = 'level2_only',
    externalPrefix.dataset = 'vexpertai-design-ontology'
MERGE (l2Route:Route:Level2Route {id: 'ch4-l2-route-external-service'})
SET l2Route.name = 'Level 2 Route 198.51.100.0/24',
    l2Route.state = 'level2_only', l2Route.dataset = 'vexpertai-design-ontology'
MERGE (policy:RouteLeakingPolicy {id: 'ch4-policy-l2-to-l1'})
SET policy.name = 'L2-to-L1 Shared Services Leak',
    policy.direction = 'L2-to-L1', policy.action = 'deny_missing_match',
    policy.dataset = 'vexpertai-design-ontology'
MERGE (reversePolicy:RouteLeakingPolicy {id: 'ch4-policy-l1-to-l2'})
SET reversePolicy.name = 'L1-to-L2 Local Prefix Leak',
    reversePolicy.direction = 'L1-to-L2', reversePolicy.action = 'permit',
    reversePolicy.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch4-service-branch-shared'})
SET service.name = 'Branch Shared Services', service.criticality = 'high',
    service.status = 'impacted', service.dataset = 'vexpertai-design-ontology'
MERGE (l1Route:Route:Level1Route {id: 'ch4-l1-route-local'})
SET l1Route.name = 'Level 1 Local Route', l1Route.state = 'leaked_to_l2',
    l1Route.dataset = 'vexpertai-design-ontology'
MERGE (localPrefix:Prefix {id: 'ch4-prefix-level1-local'})
SET localPrefix.name = 'Level 1 Local Prefix', localPrefix.cidr = '10.4.10.0/24',
    localPrefix.dataset = 'vexpertai-design-ontology'
WITH externalPrefix, l2Route, policy, reversePolicy, service, l1Route, localPrefix
MATCH (level1:Level1 {id: 'ch4-level-1'}), (level2:Level2 {id: 'ch4-level-2'})
MERGE (l2Route)-[:REPRESENTS_PREFIX]->(externalPrefix)
MERGE (l2Route)-[:LEAKED_BY]->(policy)
MERGE (policy)-[:CONTROLS_PREFIX]->(externalPrefix)
MERGE (externalPrefix)-[:SUPPORTS]->(service)
MERGE (service)-[:DEPENDS_ON]->(externalPrefix)
MERGE (l1Route)-[:REPRESENTS_PREFIX]->(localPrefix)
MERGE (l1Route)-[:LEAKED_BY]->(reversePolicy)
MERGE (reversePolicy)-[:CONTROLS_PREFIX]->(localPrefix)
MERGE (l1Route)-[:LEAKED_TO]->(level2);

// Scenario 2: overload bit suppresses transit use of core-01.
MERGE (bit:OverloadBit {id: 'ch4-overload-core-01'})
SET bit.name = 'core-01 Overload Bit', bit.set = true,
    bit.reason = 'maintenance drain', bit.dataset = 'vexpertai-design-ontology'
MERGE (transit:TransitRole {id: 'ch4-transit-core-01'})
SET transit.name = 'core-01 Level 2 Transit Role', transit.status = 'suppressed',
    transit.dataset = 'vexpertai-design-ontology'
WITH bit, transit
MATCH (core:ISISRouter {id: 'ch4-isis-core-01'})
MERGE (core)-[:HAS_OVERLOAD_BIT]->(bit)
MERGE (bit)-[:SUPPRESSES]->(transit);

// Scenario 3: adjacency loss breaks IS-IS underlay and dependent overlays.
MERGE (interface:Interface:ISISInterface {id: 'ch4-isis-core-01:Ethernet1/1'})
SET interface.name = 'Ethernet1/1', interface.state = 'down',
    interface.dataset = 'vexpertai-design-ontology'
MERGE (adjacency:ISISAdjacency {id: 'ch4-adj-core-edge'})
SET adjacency.name = 'core-01 to edge-01', adjacency.state = 'down',
    adjacency.peer_system_id = '0000.0000.0002',
    adjacency.dataset = 'vexpertai-design-ontology'
MERGE (reach:Reachability {id: 'ch4-reach-underlay'})
SET reach.name = 'IS-IS Underlay Reachability', reach.state = 'lost',
    reach.dataset = 'vexpertai-design-ontology'
MERGE (underlay:ISISUnderlay {id: 'ch4-isis-underlay'})
SET underlay.name = 'Provider IS-IS Underlay', underlay.status = 'down',
    underlay.dataset = 'vexpertai-design-ontology'
MERGE (mpls:MPLSOverlay {id: 'ch4-mpls-overlay'})
SET mpls.name = 'Enterprise MPLS L3VPN Overlay', mpls.status = 'impacted',
    mpls.dataset = 'vexpertai-design-ontology'
MERGE (srOverlay:SegmentRoutingOverlay {id: 'ch4-sr-overlay'})
SET srOverlay.name = 'Low-Latency SR Policy Overlay', srOverlay.status = 'impacted',
    srOverlay.dataset = 'vexpertai-design-ontology'
MERGE (mplsService:BusinessService {id: 'ch4-service-mpls-vpn'})
SET mplsService.name = 'Enterprise VPN Service', mplsService.criticality = 'critical',
    mplsService.dataset = 'vexpertai-design-ontology'
MERGE (srService:BusinessService {id: 'ch4-service-sr-low-latency'})
SET srService.name = 'Low-Latency Trading Path', srService.criticality = 'critical',
    srService.dataset = 'vexpertai-design-ontology'
WITH interface, adjacency, reach, underlay, mpls, srOverlay, mplsService, srService
MATCH (process:ISISProcess {id: 'ch4-isis-process-core'}),
      (core:Device {id: 'ch4-isis-core-01'})
MERGE (core)-[:HAS_INTERFACE]->(interface)
MERGE (adjacency)-[:FORMED_OVER]->(interface)
MERGE (process)-[:HAS_ISIS_ADJACENCY]->(adjacency)
MERGE (reach)-[:DEPENDS_ON]->(adjacency)
MERGE (underlay)-[:DEPENDS_ON]->(reach)
MERGE (mpls)-[:DEPENDS_ON]->(underlay)
MERGE (srOverlay)-[:DEPENDS_ON]->(underlay)
MERGE (mplsService)-[:DEPENDS_ON]->(mpls)
MERGE (srService)-[:DEPENDS_ON]->(srOverlay);

MERGE (risk:ISISAdjacencyRisk {id: 'ch4-risk-adjacency-loss'})
SET risk.name = 'IS-IS adjacency loss removes overlay underlay path',
    risk.severity = 'critical', risk.likelihood = 'medium',
    risk.dataset = 'vexpertai-design-ontology'
WITH risk
MATCH (adjacency:ISISAdjacency {id: 'ch4-adj-core-edge'}),
      (mplsService:BusinessService {id: 'ch4-service-mpls-vpn'}),
      (srService:BusinessService {id: 'ch4-service-sr-low-latency'})
MERGE (adjacency)-[:EXPOSES_ISIS_RISK]->(risk)
MERGE (risk)-[:IMPACTS]->(mplsService)
MERGE (risk)-[:IMPACTS]->(srService);

// Scenario 4: expected Prefix-SID is missing while other SIDs are advertised.
MERGE (extension:SegmentRoutingExtension {id: 'ch4-sr-extension'})
SET extension.name = 'IS-IS Segment Routing Extensions',
    extension.status = 'partial', extension.dataset = 'vexpertai-design-ontology'
MERGE (sr:SegmentRouting {id: 'ch4-segment-routing'})
SET sr.name = 'Core SR-MPLS', sr.status = 'degraded',
    sr.dataset = 'vexpertai-design-ontology'
MERGE (prefixSid:PrefixSID {id: 'ch4-prefix-sid-missing'})
SET prefixSid.name = 'Missing Prefix-SID for 10.255.4.2/32', prefixSid.sid = 16002,
    prefixSid.status = 'missing_advertisement',
    prefixSid.dataset = 'vexpertai-design-ontology'
MERGE (nodeSid:PrefixSID:NodeSID {id: 'ch4-node-sid-core-01'})
SET nodeSid.name = 'core-01 Node-SID', nodeSid.sid = 16001,
    nodeSid.status = 'advertised', nodeSid.dataset = 'vexpertai-design-ontology'
MERGE (adjSid:AdjacencySID {id: 'ch4-adjacency-sid-core-edge'})
SET adjSid.name = 'core-to-edge Adjacency-SID', adjSid.sid = 24001,
    adjSid.status = 'advertised', adjSid.dataset = 'vexpertai-design-ontology'
WITH extension, sr, prefixSid, nodeSid, adjSid
MATCH (process:ISISProcess {id: 'ch4-isis-process-core'}),
      (capability:Capability {id: 'ch4-capability-segment-routing'}),
      (srTlv:ISISTLV {id: 'ch4-tlv-sr-capability'}),
      (reachTlv:ISISTLV {id: 'ch4-tlv-ip-reachability'})
MERGE (process)-[:HAS_SR_EXTENSION]->(extension)
MERGE (sr)-[:DEPENDS_ON]->(extension)
MERGE (prefixSid)-[:REQUIRES_CAPABILITY]->(capability)
MERGE (nodeSid)-[:REQUIRES_CAPABILITY]->(capability)
MERGE (adjSid)-[:REQUIRES_CAPABILITY]->(capability)
MERGE (nodeSid)-[:ADVERTISED_BY]->(srTlv)
MERGE (adjSid)-[:ADVERTISED_BY]->(reachTlv);

// Scenario 5: DIS instability changes pseudonode and adjacency state.
MERGE (segment:ISISBroadcastSegment {id: 'ch4-broadcast-segment-100'})
SET segment.name = 'Metro Ethernet Segment 100', segment.dis_changes = 5,
    segment.observation_window_minutes = 15,
    segment.dataset = 'vexpertai-design-ontology'
MERGE (dis:DIS {id: 'ch4-dis-segment-100'})
SET dis.name = 'Segment 100 DIS Role', dis.state = 'unstable',
    dis.dataset = 'vexpertai-design-ontology'
MERGE (pseudonode:Pseudonode {id: 'ch4-pseudonode-segment-100'})
SET pseudonode.name = 'Segment 100 Pseudonode', pseudonode.state = 'regenerating',
    pseudonode.dataset = 'vexpertai-design-ontology'
MERGE (lsp:LSP:ISISLSP {id: 'ch4-lsp-pseudonode-100'})
SET lsp.name = 'Segment 100 Pseudonode LSP', lsp.sequence = 77, lsp.lifetime = 900,
    lsp.dataset = 'vexpertai-design-ontology'
MERGE (interface:Interface:ISISInterface {id: 'ch4-isis-edge-01:Ethernet1/10'})
SET interface.name = 'Ethernet1/10', interface.state = 'flapping',
    interface.dataset = 'vexpertai-design-ontology'
MERGE (risk:ISISAdjacencyRisk {id: 'ch4-risk-dis-instability'})
SET risk.name = 'DIS instability churns pseudonode LSPs',
    risk.severity = 'high', risk.likelihood = 'high',
    risk.dataset = 'vexpertai-design-ontology'
WITH segment, dis, pseudonode, lsp, interface, risk
MATCH (edge:ISISRouter {id: 'ch4-isis-edge-01'})
MERGE (segment)-[:ELECTS]->(dis)
MERGE (dis)-[:ISIS_ROLE_ON]->(edge)
MERGE (dis)-[:CREATES_PSEUDONODE]->(pseudonode)
MERGE (lsp)-[:GENERATED_BY]->(pseudonode)
MERGE (interface)-[:ISIS_ATTACHED_TO]->(segment)
MERGE (segment)-[:EXPOSES_ISIS_RISK]->(risk)
MERGE (dis)-[:EXPOSES_ISIS_RISK]->(risk);
