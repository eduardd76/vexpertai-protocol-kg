// BGP edge processes, autonomous systems, sessions, and update lineage.
MERGE (edge1:Device:InternetEdge {id: 'ch8-edge-01'})
SET edge1.name = 'internet-edge-01', edge1.status = 'up',
    edge1.dataset = 'vexpertai-design-ontology'
MERGE (edge2:Device:InternetEdge {id: 'ch8-edge-02'})
SET edge2.name = 'internet-edge-02', edge2.status = 'up',
    edge2.dataset = 'vexpertai-design-ontology'
MERGE (process:BGPProcess {id: 'ch8-bgp-65008-edge1'})
SET process.name = 'edge-01 BGP 65008', process.asn = 65008,
    process.router_id = '10.255.8.1', process.dataset = 'vexpertai-design-ontology'
MERGE (autonomousSystem:AutonomousSystem {id: 'ch8-as-65008'})
SET autonomousSystem.name = 'Enterprise AS 65008', autonomousSystem.asn = 65008,
    autonomousSystem.dataset = 'vexpertai-design-ontology'
MERGE (neighbor:BGPNeighbor {id: 'ch8-neighbor-transit-a'})
SET neighbor.name = 'Transit-A Peer', neighbor.peer_address = '192.0.2.1',
    neighbor.session_state = 'established', neighbor.remote_as = 64501,
    neighbor.dataset = 'vexpertai-design-ontology'
MERGE (ebgp:EBGPSession {id: 'ch8-ebgp-transit-a'})
SET ebgp.name = 'eBGP Transit-A', ebgp.state = 'established',
    ebgp.dataset = 'vexpertai-design-ontology'
MERGE (provider:TransitProvider {id: 'ch8-transit-a'})
SET provider.name = 'Transit Provider A', provider.asn = 64501,
    provider.dataset = 'vexpertai-design-ontology'
MERGE (edge1)-[:RUNS]->(process)
MERGE (process)-[:RUNS_ON]->(edge1)
MERGE (process)-[:BELONGS_TO_AS]->(autonomousSystem)
MERGE (neighbor)-[:BELONGS_TO]->(process)
MERGE (process)-[:HAS_SESSION]->(ebgp)
MERGE (ebgp)-[:SESSION_WITH]->(neighbor)
MERGE (provider)-[:PROVIDES_TRANSIT]->(edge1)
MERGE (provider)-[:PROVIDES_TRANSIT]->(autonomousSystem);

MERGE (update:BGPUpdate {id: 'ch8-update-customer-prefix'})
SET update.name = 'Customer Prefix Update', update.action = 'withdraw',
    update.dataset = 'vexpertai-design-ontology'
MERGE (nlri:NLRI {id: 'ch8-nlri-customer-prefix'})
SET nlri.name = '203.0.113.0/24 NLRI', nlri.prefix = '203.0.113.0/24',
    nlri.dataset = 'vexpertai-design-ontology'
MERGE (asPath:PathAttribute:ASPath {id: 'ch8-as-path-customer'})
SET asPath.name = 'AS Path 64520 64530', asPath.value = '64520 64530',
    asPath.dataset = 'vexpertai-design-ontology'
MERGE (localPref:PathAttribute:LocalPreference {id: 'ch8-local-pref-200'})
SET localPref.name = 'Local Preference 200', localPref.value = 200,
    localPref.dataset = 'vexpertai-design-ontology'
MERGE (med:PathAttribute:MED {id: 'ch8-med-50'})
SET med.name = 'MED 50', med.value = 50,
    med.dataset = 'vexpertai-design-ontology'
MERGE (update)-[:CARRIES_NLRI]->(nlri)
MERGE (update)-[:HAS_ATTRIBUTE]->(asPath)
MERGE (update)-[:HAS_ATTRIBUTE]->(localPref)
MERGE (update)-[:HAS_ATTRIBUTE]->(med);

// Scenario 1: route-policy change withdraws a critical prefix.
MERGE (prefix:Prefix {id: 'ch8-prefix-customer-api'})
SET prefix.name = 'Customer API Prefix', prefix.cidr = '203.0.113.0/24',
    prefix.visibility = 'withdrawn', prefix.dataset = 'vexpertai-design-ontology'
MERGE (route:Route:BGPRoute:CustomerRoute {id: 'ch8-route-customer-api'})
SET route.name = 'BGP Customer API Route', route.cidr = '203.0.113.0/24',
    route.state = 'withdrawn_by_policy', route.dataset = 'vexpertai-design-ontology'
MERGE (policy:RoutePolicy {id: 'ch8-policy-transit-import'})
SET policy.name = 'TRANSIT-A-IN', policy.action = 'deny',
    policy.previous_action = 'permit', policy.dataset = 'vexpertai-design-ontology'
MERGE (prefixList:PrefixList {id: 'ch8-prefix-list-customer'})
SET prefixList.name = 'PL-CUSTOMER-API', prefixList.action = 'deny',
    prefixList.dataset = 'vexpertai-design-ontology'
MERGE (change:Change {id: 'ch8-change-policy-4401'})
SET change.name = 'Restrict Transit-A import policy',
    change.timestamp = '2026-07-05T13:00:00Z',
    change.summary = 'Customer API prefix changed from permit to deny.',
    change.dataset = 'vexpertai-design-ontology'
MERGE (reach:ServiceReachability {id: 'ch8-reach-customer-api'})
SET reach.name = 'Customer API Internet Reachability', reach.state = 'lost',
    reach.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch8-service-customer-api'})
SET service.name = 'Customer API', service.criticality = 'critical',
    service.dataset = 'vexpertai-design-ontology'
WITH prefix, route, policy, prefixList, change, reach, service
MATCH (neighbor:BGPNeighbor {id: 'ch8-neighbor-transit-a'})
MERGE (route)-[:REPRESENTS_NLRI]->(prefix)
MERGE (route)-[:ADVERTISED_TO {state: 'withdrawn'}]->(neighbor)
MERGE (policy)-[:FILTERS]->(route)
MERGE (prefixList)-[:MATCHES]->(prefix)
MERGE (change)-[:MODIFIES]->(policy)
MERGE (reach)-[:DEPENDS_ON]->(route)
MERGE (service)-[:DEPENDS_ON]->(reach);

// Scenario 2: BGP next hop is unreachable because IGP recursion failed.
MERGE (route:Route:BGPRoute {id: 'ch8-route-next-hop-failed'})
SET route.name = 'BGP Route 198.18.0.0/16', route.cidr = '198.18.0.0/16',
    route.state = 'unusable_next_hop', route.dataset = 'vexpertai-design-ontology'
MERGE (nextHop:NextHop:BGPNextHop {id: 'ch8-next-hop-10.255.8.2'})
SET nextHop.name = 'BGP Next Hop 10.255.8.2', nextHop.address = '10.255.8.2',
    nextHop.status = 'unreachable', nextHop.dataset = 'vexpertai-design-ontology'
MERGE (igp:IGPReachability {id: 'ch8-igp-reach-edge2'})
SET igp.name = 'IGP Reachability to edge-02', igp.state = 'down',
    igp.reason = 'underlay adjacency failure',
    igp.dataset = 'vexpertai-design-ontology'
MERGE (route)-[:HAS_NEXT_HOP]->(nextHop)
MERGE (nextHop)-[:DEPENDS_ON]->(igp);

// Scenario 3: route-reflector failure removes client prefix visibility.
MERGE (rrDevice:Device {id: 'ch8-rr-01-device'})
SET rrDevice.name = 'route-reflector-01', rrDevice.status = 'down',
    rrDevice.dataset = 'vexpertai-design-ontology'
MERGE (rr:BGPProcess:RouteReflector {id: 'ch8-rr-01'})
SET rr.name = 'RR-01', rr.asn = 65008, rr.router_id = '10.255.8.100',
    rr.status = 'down', rr.dataset = 'vexpertai-design-ontology'
MERGE (cluster:RouteReflectorCluster {id: 'ch8-rr-cluster-1'})
SET cluster.name = 'RR Cluster 1', cluster.cluster_id = '10.255.8.100',
    cluster.dataset = 'vexpertai-design-ontology'
MERGE (client1:BGPNeighbor:RouteReflectorClient {id: 'ch8-rr-client-edge1'})
SET client1.name = 'edge-01 RR Client', client1.peer_address = '10.255.8.1',
    client1.session_state = 'idle', client1.dataset = 'vexpertai-design-ontology'
MERGE (client2:BGPNeighbor:RouteReflectorClient {id: 'ch8-rr-client-edge2'})
SET client2.name = 'edge-02 RR Client', client2.peer_address = '10.255.8.2',
    client2.session_state = 'idle', client2.dataset = 'vexpertai-design-ontology'
MERGE (route:Route:BGPRoute {id: 'ch8-route-reflected'})
SET route.name = 'Reflected Branch Aggregate', route.cidr = '10.80.0.0/16',
    route.state = 'withdrawn_rr_failure', route.dataset = 'vexpertai-design-ontology'
MERGE (prefix:Prefix {id: 'ch8-prefix-reflected'})
SET prefix.name = 'Branch Aggregate', prefix.cidr = '10.80.0.0/16',
    prefix.visibility = 'lost', prefix.dataset = 'vexpertai-design-ontology'
MERGE (rrDevice)-[:RUNS]->(rr)
MERGE (rr)-[:RUNS_ON]->(rrDevice)
MERGE (rr)-[:MEMBER_OF_RR_CLUSTER]->(cluster)
MERGE (rr)-[:HAS_CLIENT]->(client1)
MERGE (rr)-[:HAS_CLIENT]->(client2)
MERGE (rr)-[:REFLECTS]->(route)
MERGE (route)-[:REFLECTED_TO]->(client1)
MERGE (route)-[:REFLECTED_TO]->(client2)
MERGE (route)-[:REPRESENTS_NLRI]->(prefix);

// Scenario 4: IGP metric shift causes unexpected hot-potato exit.
MERGE (hot:HotPotatoRouting {id: 'ch8-hot-potato'})
SET hot.name = 'Nearest-Exit Internet Routing', hot.status = 'unexpected_exit',
    hot.dataset = 'vexpertai-design-ontology'
MERGE (metric:IGPMetricToExit {id: 'ch8-igp-metric-edge2'})
SET metric.name = 'IGP Metric to edge-02', metric.value = 5,
    metric.previous_value = 50, metric.dataset = 'vexpertai-design-ontology'
MERGE (cold:ColdPotatoRouting {id: 'ch8-cold-potato'})
SET cold.name = 'Preferred Transit Exit Routing',
    cold.dataset = 'vexpertai-design-ontology'
MERGE (preference:PolicyPreference {id: 'ch8-policy-prefer-edge1'})
SET preference.name = 'Prefer edge-01 Transit A', preference.local_preference = 250,
    preference.dataset = 'vexpertai-design-ontology'
MERGE (decision:BGPBestPathDecision {id: 'ch8-best-path-hot-potato'})
SET decision.name = 'Select edge-02 path', decision.reason = 'lowest IGP metric to BGP next hop',
    decision.dataset = 'vexpertai-design-ontology'
MERGE (route:Route:BGPRoute {id: 'ch8-route-selected-internet'})
SET route.name = 'Selected Internet Default', route.cidr = '0.0.0.0/0',
    route.state = 'selected', route.dataset = 'vexpertai-design-ontology'
MERGE (prefix:Prefix {id: 'ch8-prefix-default'})
SET prefix.name = 'Internet Default Prefix', prefix.cidr = '0.0.0.0/0',
    prefix.visibility = 'selected', prefix.dataset = 'vexpertai-design-ontology'
MERGE (path:SelectedBGPPath {id: 'ch8-selected-path-edge2'})
SET path.name = 'Internet Exit via edge-02', path.status = 'selected',
    path.dataset = 'vexpertai-design-ontology'
MERGE (reach:ServiceReachability {id: 'ch8-reach-internet'})
SET reach.name = 'Corporate Internet Reachability', reach.state = 'available_unexpected_exit',
    reach.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch8-service-internet'})
SET service.name = 'Corporate Internet Access', service.criticality = 'high',
    service.dataset = 'vexpertai-design-ontology'
MERGE (change:Change {id: 'ch8-change-igp-cost'})
SET change.name = 'Lower IGP cost to edge-02',
    change.timestamp = '2026-07-05T13:10:00Z',
    change.summary = 'IGP cost changed from 50 to 5 and moved internet exit.',
    change.dataset = 'vexpertai-design-ontology'
WITH hot, metric, cold, preference, decision, route, prefix, path, reach, service, change
MATCH (edge2:InternetEdge {id: 'ch8-edge-02'})
MERGE (hot)-[:DEPENDS_ON]->(metric)
MERGE (hot)-[:USES_EXIT]->(edge2)
MERGE (cold)-[:DEPENDS_ON]->(preference)
MERGE (route)-[:SELECTED_BY]->(decision)
MERGE (route)-[:REPRESENTS_NLRI]->(prefix)
MERGE (path)-[:USES_ROUTE]->(route)
MERGE (path)-[:USES_EXIT]->(edge2)
MERGE (reach)-[:DEPENDS_ON]->(path)
MERGE (reach)-[:DEPENDS_ON]->(route)
MERGE (service)-[:DEPENDS_ON]->(reach)
MERGE (change)-[:MODIFIES]->(metric);

// Scenario 5: BGP PIC protects service from primary edge failure.
MERGE (pic:BGPPIC {id: 'ch8-bgp-pic-edge'})
SET pic.name = 'BGP PIC Edge', pic.status = 'armed',
    pic.dataset = 'vexpertai-design-ontology'
MERGE (failure:NextHopFailure {id: 'ch8-failure-edge1'})
SET failure.name = 'Primary edge-01 next-hop failure',
    failure.state = 'active', failure.dataset = 'vexpertai-design-ontology'
MERGE (backup:NextHop:BGPNextHop {id: 'ch8-next-hop-backup-edge2'})
SET backup.name = 'Backup Next Hop edge-02', backup.address = '10.255.8.2',
    backup.status = 'reachable', backup.dataset = 'vexpertai-design-ontology'
MERGE (route:Route:BGPRoute {id: 'ch8-route-pic-protected'})
SET route.name = 'PIC-Protected SaaS Route', route.cidr = '192.0.2.128/25',
    route.state = 'selected_backup', route.dataset = 'vexpertai-design-ontology'
MERGE (reach:ServiceReachability {id: 'ch8-reach-saas'})
SET reach.name = 'SaaS Reachability', reach.state = 'available_via_backup',
    reach.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch8-service-saas'})
SET service.name = 'Critical SaaS Access', service.criticality = 'critical',
    service.dataset = 'vexpertai-design-ontology'
MERGE (pic)-[:PROTECTS]->(failure)
MERGE (pic)-[:PROTECTS]->(backup)
MERGE (route)-[:HAS_NEXT_HOP]->(backup)
MERGE (reach)-[:DEPENDS_ON]->(route)
MERGE (service)-[:DEPENDS_ON]->(reach);

// Scenario 6: blackhole community impacts a service prefix.
MERGE (community:Community {id: 'ch8-community-blackhole'})
SET community.name = 'BLACKHOLE 65535:666', community.value = '65535:666',
    community.dataset = 'vexpertai-design-ontology'
MERGE (large:LargeCommunity {id: 'ch8-large-community-ops'})
SET large.name = '65008:100:666', large.value = '65008:100:666',
    large.dataset = 'vexpertai-design-ontology'
MERGE (extended:ExtendedCommunity {id: 'ch8-extended-community-rt'})
SET extended.name = 'RT 65008:666', extended.value = 'rt:65008:666',
    extended.dataset = 'vexpertai-design-ontology'
MERGE (policy:RoutePolicy {id: 'ch8-policy-blackhole'})
SET policy.name = 'COMMUNITY-BLACKHOLE', policy.action = 'set discard next-hop',
    policy.dataset = 'vexpertai-design-ontology'
MERGE (route:Route:BGPRoute:BlackholeRoute {id: 'ch8-route-blackhole'})
SET route.name = 'Blackholed Checkout Prefix', route.cidr = '10.88.88.0/24',
    route.state = 'discarded', route.dataset = 'vexpertai-design-ontology'
MERGE (prefix:Prefix {id: 'ch8-prefix-blackhole'})
SET prefix.name = 'Checkout Service Prefix', prefix.cidr = '10.88.88.0/24',
    prefix.visibility = 'blackholed', prefix.dataset = 'vexpertai-design-ontology'
MERGE (risk:BGPPathRisk {id: 'ch8-risk-blackhole-service'})
SET risk.name = 'Blackhole community applied to live service prefix',
    risk.severity = 'critical', risk.likelihood = 'medium',
    risk.dataset = 'vexpertai-design-ontology'
MERGE (reach:ServiceReachability {id: 'ch8-reach-checkout'})
SET reach.name = 'Checkout BGP Reachability', reach.state = 'discarded',
    reach.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch8-service-checkout'})
SET service.name = 'Checkout Service', service.criticality = 'critical',
    service.dataset = 'vexpertai-design-ontology'
MERGE (community)-[:INFLUENCES]->(policy)
MERGE (community)-[:TRIGGERS_BLACKHOLE]->(route)
MERGE (policy)-[:TRIGGERS_BLACKHOLE]->(route)
MERGE (policy)-[:MODIFIES_ROUTE]->(route)
MERGE (route)-[:REPRESENTS_NLRI]->(prefix)
MERGE (route)-[:HAS_ATTRIBUTE]->(community)
MERGE (route)-[:HAS_ATTRIBUTE]->(large)
MERGE (route)-[:HAS_ATTRIBUTE]->(extended)
MERGE (route)-[:EXPOSES_BGP_RISK]->(risk)
MERGE (risk)-[:IMPACTS]->(service)
MERGE (reach)-[:DEPENDS_ON]->(route)
MERGE (service)-[:DEPENDS_ON]->(reach);

// Scaling and edge capabilities retained as explicit design objects.
MERGE (addPath:AddPath {id: 'ch8-add-path'})
SET addPath.name = 'BGP Add-Path', addPath.status = 'enabled',
    addPath.dataset = 'vexpertai-design-ontology'
MERGE (bestExternal:BGPBestExternal {id: 'ch8-best-external'})
SET bestExternal.name = 'BGP Best External', bestExternal.status = 'enabled',
    bestExternal.dataset = 'vexpertai-design-ontology'
MERGE (freeCore:BGPFreeCore {id: 'ch8-bgp-free-core'})
SET freeCore.name = 'BGP-Free MPLS Core', freeCore.status = 'valid',
    freeCore.dataset = 'vexpertai-design-ontology'
MERGE (edgeReach:EdgeToEdgeReachability {id: 'ch8-edge-to-edge-reach'})
SET edgeReach.name = 'Edge-to-Edge Label and IGP Reachability',
    edgeReach.status = 'up', edgeReach.dataset = 'vexpertai-design-ontology'
MERGE (confed:Confederation {id: 'ch8-confederation'})
SET confed.name = 'AS 65008 Confederation', confed.public_asn = 65008,
    confed.dataset = 'vexpertai-design-ontology'
MERGE (freeCore)-[:REQUIRES]->(edgeReach);
