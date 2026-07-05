// EIGRP hub, spokes, process identity, topology table, and adjacency.
MERGE (hub:Device:EIGRPRouter:HubRouter {id: 'ch5-eigrp-hub-01'})
SET hub.name = 'eigrp-hub-01', hub.status = 'up',
    hub.dataset = 'vexpertai-design-ontology'
MERGE (spoke1:Device:EIGRPRouter:StubRouter {id: 'ch5-eigrp-spoke-01'})
SET spoke1.name = 'eigrp-spoke-01', spoke1.status = 'up',
    spoke1.stub_routes = ['connected', 'summary'],
    spoke1.dataset = 'vexpertai-design-ontology'
MERGE (spoke2:Device:EIGRPRouter:StubRouter {id: 'ch5-eigrp-spoke-02'})
SET spoke2.name = 'eigrp-spoke-02', spoke2.status = 'up',
    spoke2.stub_routes = ['connected', 'summary'],
    spoke2.dataset = 'vexpertai-design-ontology'
MERGE (process:EIGRPProcess {id: 'ch5-eigrp-process-100'})
SET process.name = 'WAN EIGRP 100', process.autonomous_system = 100,
    process.dataset = 'vexpertai-design-ontology'
MERGE (asn:EIGRPASN {id: 'ch5-eigrp-asn-100'})
SET asn.name = 'EIGRP AS 100', asn.asn = 100,
    asn.dataset = 'vexpertai-design-ontology'
MERGE (named:EIGRPNamedMode {id: 'ch5-eigrp-named-wan'})
SET named.name = 'WAN-EIGRP Named Mode', named.address_family = 'IPv4 unicast',
    named.dataset = 'vexpertai-design-ontology'
MERGE (table:EIGRPTopologyTable {id: 'ch5-eigrp-topology-100'})
SET table.name = 'EIGRP 100 IPv4 Topology Table',
    table.dataset = 'vexpertai-design-ontology'
MERGE (hub)-[:RUNS]->(process)
MERGE (process)-[:RUNS_ON]->(hub)
MERGE (process)-[:HAS_ASN]->(asn)
MERGE (process)-[:USES_NAMED_MODE]->(named)
MERGE (process)-[:HAS_TOPOLOGY_TABLE]->(table);

MERGE (interface:Interface:EIGRPInterface {id: 'ch5-eigrp-hub-01:Tunnel100'})
SET interface.name = 'Tunnel100', interface.state = 'up',
    interface.delay = 1000, interface.bandwidth_kbps = 100000,
    interface.dataset = 'vexpertai-design-ontology'
MERGE (neighbor:EIGRPNeighbor {id: 'ch5-neighbor-hub-spoke1'})
SET neighbor.name = 'hub-01 to spoke-01', neighbor.state = 'up',
    neighbor.peer_address = '10.5.0.11',
    neighbor.dataset = 'vexpertai-design-ontology'
MERGE (passive:PassiveInterface {id: 'ch5-passive-loopback0'})
SET passive.name = 'Loopback0 Passive Interface',
    passive.dataset = 'vexpertai-design-ontology'
WITH interface, neighbor, passive
MATCH (hub:Device {id: 'ch5-eigrp-hub-01'}),
      (process:EIGRPProcess {id: 'ch5-eigrp-process-100'})
MERGE (hub)-[:HAS_INTERFACE]->(interface)
MERGE (neighbor)-[:FORMED_OVER]->(interface)
MERGE (process)-[:HAS_EIGRP_NEIGHBOR]->(neighbor)
MERGE (process)-[:HAS_PASSIVE_INTERFACE]->(passive);

// Scenario 1: an important prefix has no feasible successor.
MERGE (prefix:Prefix {id: 'ch5-prefix-no-fs'})
SET prefix.name = 'Branch Payment Prefix', prefix.cidr = '10.50.10.0/24',
    prefix.convergence_state = 'active_query',
    prefix.dataset = 'vexpertai-design-ontology'
MERGE (successor:Route:SuccessorRoute {id: 'ch5-successor-payment'})
SET successor.name = 'Successor via Tunnel100', successor.feasible_distance = 30720,
    successor.state = 'failed', successor.dataset = 'vexpertai-design-ontology'
MERGE (metric:EIGRPMetric {id: 'ch5-metric-payment'})
SET metric.name = 'Payment Prefix Composite Metric', metric.value = 30720,
    metric.dataset = 'vexpertai-design-ontology'
MERGE (delay:Delay {id: 'ch5-delay-payment'})
SET delay.name = 'Tunnel100 Delay', delay.value = 1000,
    delay.previous_value = 100, delay.dataset = 'vexpertai-design-ontology'
MERGE (bandwidth:Bandwidth {id: 'ch5-bandwidth-payment'})
SET bandwidth.name = 'Tunnel100 Minimum Bandwidth', bandwidth.value = 100000,
    bandwidth.dataset = 'vexpertai-design-ontology'
MERGE (reliability:Reliability {id: 'ch5-reliability-payment'})
SET reliability.name = 'Tunnel100 Reliability', reliability.value = 255,
    reliability.dataset = 'vexpertai-design-ontology'
MERGE (load:Load {id: 'ch5-load-payment'})
SET load.name = 'Tunnel100 Load', load.value = 10,
    load.dataset = 'vexpertai-design-ontology'
MERGE (mtu:MTU {id: 'ch5-mtu-payment'})
SET mtu.name = 'Tunnel100 MTU', mtu.value = 1400,
    mtu.dataset = 'vexpertai-design-ontology'
WITH prefix, successor, metric, delay, bandwidth, reliability, load, mtu
MATCH (process:EIGRPProcess {id: 'ch5-eigrp-process-100'}),
      (table:EIGRPTopologyTable {id: 'ch5-eigrp-topology-100'})
MERGE (prefix)-[:LEARNED_BY]->(process)
MERGE (table)-[:HAS_ROUTE]->(successor)
MERGE (successor)-[:REPRESENTS_PREFIX]->(prefix)
MERGE (successor)-[:SELECTED_BY]->(metric)
MERGE (metric)-[:HAS_METRIC_COMPONENT]->(delay)
MERGE (metric)-[:HAS_METRIC_COMPONENT]->(bandwidth)
MERGE (metric)-[:HAS_METRIC_COMPONENT]->(reliability)
MERGE (metric)-[:HAS_METRIC_COMPONENT]->(load)
MERGE (metric)-[:HAS_METRIC_COMPONENT]->(mtu);

MERGE (protectedPrefix:Prefix {id: 'ch5-prefix-with-fs'})
SET protectedPrefix.name = 'Branch Inventory Prefix', protectedPrefix.cidr = '10.50.20.0/24',
    protectedPrefix.convergence_state = 'protected',
    protectedPrefix.dataset = 'vexpertai-design-ontology'
MERGE (protectedSuccessor:Route:SuccessorRoute {id: 'ch5-successor-inventory'})
SET protectedSuccessor.name = 'Inventory Successor', protectedSuccessor.feasible_distance = 40960,
    protectedSuccessor.state = 'installed',
    protectedSuccessor.dataset = 'vexpertai-design-ontology'
MERGE (feasible:Route:FeasibleSuccessorRoute {id: 'ch5-feasible-inventory'})
SET feasible.name = 'Inventory Feasible Successor', feasible.reported_distance = 30000,
    feasible.total_distance = 51200, feasible.state = 'standby',
    feasible.dataset = 'vexpertai-design-ontology'
MERGE (condition:FeasibilityCondition {id: 'ch5-fc-inventory'})
SET condition.name = 'RD 30000 less than FD 40960', condition.satisfied = true,
    condition.dataset = 'vexpertai-design-ontology'
WITH protectedPrefix, protectedSuccessor, feasible, condition
MATCH (process:EIGRPProcess {id: 'ch5-eigrp-process-100'}),
      (table:EIGRPTopologyTable {id: 'ch5-eigrp-topology-100'})
MERGE (protectedPrefix)-[:LEARNED_BY]->(process)
MERGE (table)-[:HAS_ROUTE]->(protectedSuccessor)
MERGE (table)-[:HAS_ROUTE]->(feasible)
MERGE (protectedSuccessor)-[:REPRESENTS_PREFIX]->(protectedPrefix)
MERGE (feasible)-[:REPRESENTS_PREFIX]->(protectedPrefix)
MERGE (feasible)-[:SATISFIES_FEASIBILITY]->(condition)
MERGE (feasible)-[:PROTECTS]->(protectedPrefix);

MERGE (service:BusinessService {id: 'ch5-service-branch-payment'})
SET service.name = 'Branch Payment Access', service.criticality = 'critical',
    service.dataset = 'vexpertai-design-ontology'
MERGE (incident:Incident {id: 'ch5-incident-slow-convergence'})
SET incident.name = 'Branch Payment Slow EIGRP Convergence',
    incident.timestamp = '2026-07-05T12:02:00Z', incident.status = 'investigating',
    incident.dataset = 'vexpertai-design-ontology'
MERGE (change:Change {id: 'ch5-change-delay'})
SET change.name = 'Increase Tunnel100 delay', change.timestamp = '2026-07-05T11:58:00Z',
    change.summary = 'Delay changed from 100 to 1000 before successor failure.',
    change.dataset = 'vexpertai-design-ontology'
WITH service, incident, change
MATCH (prefix:Prefix {id: 'ch5-prefix-no-fs'}), (delay:Delay {id: 'ch5-delay-payment'})
MERGE (prefix)-[:SUPPORTS]->(service)
MERGE (service)-[:DEPENDS_ON]->(prefix)
MERGE (incident)-[:IMPACTS]->(service)
MERGE (change)-[:MODIFIES]->(delay);

// Scenario 2: stub spokes reduce the hub-and-spoke query domain.
MERGE (topology:HubAndSpokeTopology {id: 'ch5-hub-spoke-wan'})
SET topology.name = 'EIGRP DMVPN Hub-and-Spoke WAN',
    topology.dataset = 'vexpertai-design-ontology'
MERGE (domain:QueryDomain {id: 'ch5-query-domain-wan'})
SET domain.name = 'WAN EIGRP Query Domain', domain.router_count = 3,
    domain.effective_query_targets = 1,
    domain.dataset = 'vexpertai-design-ontology'
MERGE (dependency:DMVPNDependency {id: 'ch5-dmvpn-eigrp-dependency'})
SET dependency.name = 'DMVPN NHRP and EIGRP Reachability Dependency',
    dependency.dataset = 'vexpertai-design-ontology'
MERGE (reach:HubSpokeReachability {id: 'ch5-hub-spoke-reachability'})
SET reach.name = 'Spoke-to-Spoke Reachability', reach.state = 'available',
    reach.dataset = 'vexpertai-design-ontology'
MERGE (overlay:DMVPNOverlay {id: 'ch5-dmvpn-overlay'})
SET overlay.name = 'Enterprise DMVPN Phase 3 Overlay',
    overlay.status = 'up', overlay.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch5-service-spoke-connectivity'})
SET service.name = 'Branch-to-Branch Connectivity', service.criticality = 'high',
    service.dataset = 'vexpertai-design-ontology'
WITH topology, domain, dependency, reach, overlay, service
MATCH (hub:HubRouter {id: 'ch5-eigrp-hub-01'}),
      (spoke1:StubRouter {id: 'ch5-eigrp-spoke-01'}),
      (spoke2:StubRouter {id: 'ch5-eigrp-spoke-02'}),
      (process:EIGRPProcess {id: 'ch5-eigrp-process-100'})
MERGE (hub)-[:PART_OF_QUERY_DOMAIN]->(domain)
MERGE (spoke1)-[:PART_OF_QUERY_DOMAIN]->(domain)
MERGE (spoke2)-[:PART_OF_QUERY_DOMAIN]->(domain)
MERGE (spoke1)-[:REDUCES]->(domain)
MERGE (spoke2)-[:REDUCES]->(domain)
MERGE (topology)-[:HAS_STUB_ROUTER]->(spoke1)
MERGE (topology)-[:HAS_STUB_ROUTER]->(spoke2)
MERGE (topology)-[:HAS_DMVPN_DEPENDENCY]->(dependency)
MERGE (reach)-[:DEPENDS_ON]->(hub)
MERGE (overlay)-[:MAY_DEPEND_ON]->(process)
MERGE (overlay)-[:MAY_DEPEND_ON]->(reach)
MERGE (service)-[:DEPENDS_ON]->(reach)
MERGE (service)-[:DEPENDS_ON]->(overlay);

// Scenario 3: a summary discard path hides a required more-specific.
MERGE (summary:Route:SummaryRoute {id: 'ch5-summary-10.50.0.0-16'})
SET summary.name = 'EIGRP Summary 10.50.0.0/16', summary.cidr = '10.50.0.0/16',
    summary.discard_route = true, summary.state = 'installed',
    summary.dataset = 'vexpertai-design-ontology'
MERGE (specific:Prefix:SpecificPrefix {id: 'ch5-specific-10.50.77.0-24'})
SET specific.name = 'Required Fraud Prefix', specific.cidr = '10.50.77.0/24',
    specific.required = true, specific.visibility = 'missing',
    specific.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch5-service-fraud'})
SET service.name = 'Fraud Scoring Service', service.criticality = 'critical',
    service.dataset = 'vexpertai-design-ontology'
WITH summary, specific, service
MATCH (table:EIGRPTopologyTable {id: 'ch5-eigrp-topology-100'})
MERGE (table)-[:HAS_ROUTE]->(summary)
MERGE (summary)-[:REPRESENTS_PREFIX]->(specific)
MERGE (summary)-[:HIDES]->(specific)
MERGE (specific)-[:SUPPORTS]->(service)
MERGE (service)-[:DEPENDS_ON]->(specific);

// Scenario 4: variance installs a feasible unequal-cost path.
MERGE (variance:Variance {id: 'ch5-variance-2'})
SET variance.name = 'Variance 2', variance.multiplier = 2,
    variance.dataset = 'vexpertai-design-ontology'
MERGE (loadBalancing:UnequalCostLoadBalancing {id: 'ch5-unequal-cost'})
SET loadBalancing.name = 'EIGRP Unequal-Cost Forwarding',
    loadBalancing.status = 'enabled', loadBalancing.paths = 2,
    loadBalancing.dataset = 'vexpertai-design-ontology'
WITH variance, loadBalancing
MATCH (process:EIGRPProcess {id: 'ch5-eigrp-process-100'})
MERGE (process)-[:USES_VARIANCE]->(variance)
MERGE (variance)-[:ENABLES]->(loadBalancing);

// Scenario 5: EIGRP/BGP redistribution exposes route feedback.
MERGE (policy:RedistributionPolicy {id: 'ch5-policy-eigrp-bgp'})
SET policy.name = 'Bidirectional EIGRP-BGP Redistribution',
    policy.direction = 'bidirectional', policy.tagging = 'missing',
    policy.dataset = 'vexpertai-design-ontology'
MERGE (routeMap:RouteMap {id: 'ch5-rm-eigrp-bgp'})
SET routeMap.name = 'RM-EIGRP-BGP', routeMap.action = 'permit-all',
    routeMap.dataset = 'vexpertai-design-ontology'
MERGE (bgp:BGPProcess {id: 'ch5-bgp-65005'})
SET bgp.name = 'WAN BGP 65005', bgp.asn = 65005,
    bgp.dataset = 'vexpertai-design-ontology'
MERGE (risk:Risk {id: 'ch5-risk-route-feedback'})
SET risk.name = 'EIGRP-BGP route feedback loop', risk.severity = 'critical',
    risk.likelihood = 'high', risk.state = 'open',
    risk.dataset = 'vexpertai-design-ontology'
WITH policy, routeMap, bgp, risk
MATCH (process:EIGRPProcess {id: 'ch5-eigrp-process-100'}),
      (service:BusinessService {id: 'ch5-service-branch-payment'})
MERGE (process)-[:REDISTRIBUTES_TO]->(bgp)
MERGE (policy)-[:CONTROLLED_BY]->(routeMap)
MERGE (policy)-[:EXPOSES_FEEDBACK_RISK]->(risk)
MERGE (risk)-[:IMPACTS]->(service);
