// OSPF routers, processes, area hierarchy, and interface membership.
MERGE (abr:Device:OSPFRouter:ABR {id: 'ch3-abr-01'})
SET abr.name = 'abr-01', abr.status = 'down',
    abr.router_id = '10.255.3.1', abr.dataset = 'vexpertai-design-ontology'
MERGE (asbr:Device:OSPFRouter:ASBR {id: 'ch3-asbr-01'})
SET asbr.name = 'asbr-01', asbr.status = 'up',
    asbr.router_id = '10.255.3.2', asbr.dataset = 'vexpertai-design-ontology'
MERGE (dist1:Device:OSPFRouter {id: 'ch3-dist-01'})
SET dist1.name = 'ospf-dist-01', dist1.status = 'up',
    dist1.router_id = '10.255.3.11', dist1.dataset = 'vexpertai-design-ontology'
MERGE (dist2:Device:OSPFRouter {id: 'ch3-dist-02'})
SET dist2.name = 'ospf-dist-02', dist2.status = 'up',
    dist2.router_id = '10.255.3.12', dist2.dataset = 'vexpertai-design-ontology'
MERGE (abrProcess:OSPFProcess {id: 'ch3-abr-ospf-100'})
SET abrProcess.name = 'abr-01 OSPF 100', abrProcess.process_id = 100,
    abrProcess.router_id = '10.255.3.1', abrProcess.dataset = 'vexpertai-design-ontology'
MERGE (asbrProcess:OSPFProcess {id: 'ch3-asbr-ospf-100'})
SET asbrProcess.name = 'asbr-01 OSPF 100', asbrProcess.process_id = 100,
    asbrProcess.router_id = '10.255.3.2', asbrProcess.dataset = 'vexpertai-design-ontology'
MERGE (area0:OSPFArea:BackboneArea {id: 'ch3-area-0'})
SET area0.name = 'Backbone Area 0', area0.area_id = '0.0.0.0',
    area0.area_type = 'backbone', area0.status = 'isolated',
    area0.dataset = 'vexpertai-design-ontology'
MERGE (area10:OSPFArea:NormalArea {id: 'ch3-area-10'})
SET area10.name = 'Application Area 10', area10.area_id = '0.0.0.10',
    area10.area_type = 'normal', area10.status = 'up',
    area10.dataset = 'vexpertai-design-ontology'
MERGE (area20:OSPFArea:StubArea {id: 'ch3-area-20'})
SET area20.name = 'Partner Area 20', area20.area_id = '0.0.0.20',
    area20.area_type = 'stub', area20.status = 'up',
    area20.dataset = 'vexpertai-design-ontology'
MERGE (abr)-[:RUNS]->(abrProcess)
MERGE (asbr)-[:RUNS]->(asbrProcess)
MERGE (abrProcess)-[:RUNS_ON]->(abr)
MERGE (asbrProcess)-[:RUNS_ON]->(asbr)
MERGE (abrProcess)-[:CONTAINS]->(area0)
MERGE (abrProcess)-[:CONTAINS]->(area10)
MERGE (asbrProcess)-[:CONTAINS]->(area0)
MERGE (asbrProcess)-[:CONTAINS]->(area20)
MERGE (abr)-[:CONNECTS {state: 'down'}]->(area0)
MERGE (abr)-[:CONNECTS {state: 'up'}]->(area10)
MERGE (asbr)-[:CONNECTS {state: 'up'}]->(area0)
MERGE (asbr)-[:CONNECTS {state: 'up'}]->(area20);

MERGE (abrBackboneIf:Interface:OSPFInterface {id: 'ch3-abr-01:Ethernet1/1'})
SET abrBackboneIf.name = 'Ethernet1/1', abrBackboneIf.address = '10.0.0.1/30',
    abrBackboneIf.state = 'down', abrBackboneIf.dataset = 'vexpertai-design-ontology'
MERGE (abrArea10If:Interface:OSPFInterface {id: 'ch3-abr-01:Ethernet1/10'})
SET abrArea10If.name = 'Ethernet1/10', abrArea10If.address = '10.0.10.1/30',
    abrArea10If.state = 'up', abrArea10If.dataset = 'vexpertai-design-ontology'
MERGE (asbrArea20If:Interface:OSPFInterface {id: 'ch3-asbr-01:Ethernet1/20'})
SET asbrArea20If.name = 'Ethernet1/20', asbrArea20If.address = '10.0.20.1/24',
    asbrArea20If.state = 'up', asbrArea20If.dataset = 'vexpertai-design-ontology'
MERGE (p2p:OSPFNetworkType {id: 'ch3-network-type-p2p'})
SET p2p.name = 'Point-to-Point', p2p.network_type = 'point-to-point',
    p2p.dataset = 'vexpertai-design-ontology'
MERGE (broadcast:OSPFNetworkType {id: 'ch3-network-type-broadcast'})
SET broadcast.name = 'Broadcast', broadcast.network_type = 'broadcast',
    broadcast.dataset = 'vexpertai-design-ontology'
WITH abrBackboneIf, abrArea10If, asbrArea20If, p2p, broadcast
MATCH (abr:Device {id: 'ch3-abr-01'}), (asbr:Device {id: 'ch3-asbr-01'}),
      (area0:OSPFArea {id: 'ch3-area-0'}), (area10:OSPFArea {id: 'ch3-area-10'}),
      (area20:OSPFArea {id: 'ch3-area-20'})
MERGE (abr)-[:HAS_INTERFACE]->(abrBackboneIf)
MERGE (abr)-[:HAS_INTERFACE]->(abrArea10If)
MERGE (asbr)-[:HAS_INTERFACE]->(asbrArea20If)
MERGE (area0)-[:CONTAINS]->(abrBackboneIf)
MERGE (area10)-[:CONTAINS]->(abrArea10If)
MERGE (area20)-[:CONTAINS]->(asbrArea20If)
MERGE (abrBackboneIf)-[:HAS_NETWORK_TYPE]->(p2p)
MERGE (abrArea10If)-[:HAS_NETWORK_TYPE]->(p2p)
MERGE (asbrArea20If)-[:HAS_NETWORK_TYPE]->(broadcast);

// LSA types and representative LSA lineage.
MERGE (type1:LSAType {id: 'ch3-lsa-type-1'})
SET type1.name = 'Type 1 Router LSA', type1.number = 1,
    type1.dataset = 'vexpertai-design-ontology'
MERGE (type2:LSAType {id: 'ch3-lsa-type-2'})
SET type2.name = 'Type 2 Network LSA', type2.number = 2,
    type2.dataset = 'vexpertai-design-ontology'
MERGE (type3:LSAType {id: 'ch3-lsa-type-3'})
SET type3.name = 'Type 3 Summary LSA', type3.number = 3,
    type3.dataset = 'vexpertai-design-ontology'
MERGE (type5:LSAType {id: 'ch3-lsa-type-5'})
SET type5.name = 'Type 5 External LSA', type5.number = 5,
    type5.dataset = 'vexpertai-design-ontology'
MERGE (type7:LSAType {id: 'ch3-lsa-type-7'})
SET type7.name = 'Type 7 NSSA LSA', type7.number = 7,
    type7.dataset = 'vexpertai-design-ontology'
MERGE (opaqueType:LSAType {id: 'ch3-lsa-type-opaque'})
SET opaqueType.name = 'Opaque LSA', opaqueType.number = 10,
    opaqueType.dataset = 'vexpertai-design-ontology'
MERGE (routerLsa:LSA:RouterLSA {id: 'ch3-router-lsa-area10'})
SET routerLsa.name = 'Area 10 Router Topology', routerLsa.lsa_type = 1,
    routerLsa.advertising_router = '10.255.3.1',
    routerLsa.dataset = 'vexpertai-design-ontology'
MERGE (networkLsa:LSA:NetworkLSA {id: 'ch3-network-lsa-segment'})
SET networkLsa.name = 'Broadcast Segment Network LSA', networkLsa.lsa_type = 2,
    networkLsa.advertising_router = '10.255.3.11',
    networkLsa.dataset = 'vexpertai-design-ontology'
MERGE (summaryLsa:LSA:SummaryLSA {id: 'ch3-summary-lsa-area10'})
SET summaryLsa.name = 'Area 10 Inter-Area Summary', summaryLsa.lsa_type = 3,
    summaryLsa.advertising_router = '10.255.3.1', summaryLsa.status = 'withdrawn',
    summaryLsa.dataset = 'vexpertai-design-ontology'
MERGE (nssaLsa:LSA:NSSALSA {id: 'ch3-nssa-lsa-example'})
SET nssaLsa.name = 'NSSA External Example', nssaLsa.lsa_type = 7,
    nssaLsa.advertising_router = '10.255.3.2',
    nssaLsa.dataset = 'vexpertai-design-ontology'
MERGE (opaqueLsa:LSA:OpaqueLSA {id: 'ch3-opaque-lsa-te'})
SET opaqueLsa.name = 'Traffic Engineering Opaque LSA', opaqueLsa.lsa_type = 10,
    opaqueLsa.advertising_router = '10.255.3.1',
    opaqueLsa.dataset = 'vexpertai-design-ontology'
MERGE (routerLsa)-[:HAS_LSA_TYPE]->(type1)
MERGE (networkLsa)-[:HAS_LSA_TYPE]->(type2)
MERGE (summaryLsa)-[:HAS_LSA_TYPE]->(type3)
MERGE (nssaLsa)-[:HAS_LSA_TYPE]->(type7)
MERGE (opaqueLsa)-[:HAS_LSA_TYPE]->(opaqueType);

// Scenario 1: missing backbone connectivity removes inter-area reachability.
MERGE (prefix:Prefix {id: 'ch3-prefix-area10-app'})
SET prefix.name = 'Area 10 Application Prefix', prefix.cidr = '10.30.10.0/24',
    prefix.visibility = 'lost_inter_area', prefix.dataset = 'vexpertai-design-ontology'
MERGE (route:Route {id: 'ch3-route-area10-app'})
SET route.name = 'OSPF Route 10.30.10.0/24', route.state = 'withdrawn',
    route.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch3-service-order-api'})
SET service.name = 'Order API', service.criticality = 'critical',
    service.dataset = 'vexpertai-design-ontology'
MERGE (reach:Reachability {id: 'ch3-reach-area10-interarea'})
SET reach.name = 'Area 10 Inter-Area Reachability', reach.state = 'lost',
    reach.dataset = 'vexpertai-design-ontology'
WITH prefix, route, service, reach
MATCH (area10:OSPFArea {id: 'ch3-area-10'}),
      (summaryLsa:LSA {id: 'ch3-summary-lsa-area10'})
MERGE (prefix)-[:ORIGINATES_IN]->(area10)
MERGE (prefix)-[:ADVERTISED_BY]->(summaryLsa)
MERGE (route)-[:DEPENDS_ON]->(summaryLsa)
MERGE (prefix)-[:SUPPORTS]->(service)
MERGE (service)-[:DEPENDS_ON]->(prefix)
MERGE (reach)-[:PROVIDES_REACHABILITY_TO]->(prefix);

// Scenario 2: stub area denies the type 5 LSA required by a partner route.
MERGE (external:ExternalRoute {id: 'ch3-external-partner-route'})
SET external.name = 'Partner API External Route', external.cidr = '203.0.113.0/24',
    external.required = true, external.visibility = 'blocked',
    external.dataset = 'vexpertai-design-ontology'
MERGE (externalLsa:LSA:ExternalLSA {id: 'ch3-external-lsa-partner'})
SET externalLsa.name = 'Partner API Type 5 LSA', externalLsa.lsa_type = 5,
    externalLsa.advertising_router = '10.255.3.2',
    externalLsa.dataset = 'vexpertai-design-ontology'
MERGE (prefix:Prefix {id: 'ch3-prefix-partner'})
SET prefix.name = 'Partner API Prefix', prefix.cidr = '203.0.113.0/24',
    prefix.visibility = 'blocked_in_area20', prefix.dataset = 'vexpertai-design-ontology'
MERGE (defaultInjection:DefaultRouteInjection {id: 'ch3-default-area20'})
SET defaultInjection.name = 'Area 20 Stub Default',
    defaultInjection.status = 'present', defaultInjection.dataset = 'vexpertai-design-ontology'
WITH external, externalLsa, prefix, defaultInjection
MATCH (type5:LSAType {id: 'ch3-lsa-type-5'}),
      (area20:OSPFArea {id: 'ch3-area-20'}),
      (asbr:ASBR {id: 'ch3-asbr-01'})
MERGE (external)-[:CARRIED_BY_LSA]->(externalLsa)
MERGE (externalLsa)-[:HAS_LSA_TYPE]->(type5)
MERGE (prefix)-[:ADVERTISED_BY]->(externalLsa)
MERGE (area20)-[:RESTRICTS {action: 'deny', reason: 'stub areas reject type 5'}]->(type5)
MERGE (defaultInjection)-[:INJECTS_DEFAULT]->(area20)
MERGE (asbr)-[:REDISTRIBUTES]->(external);

// Scenario 3: OSPF-to-BGP redistribution is filtered by route-map.
MERGE (bgp:BGPProcess {id: 'ch3-bgp-65003'})
SET bgp.name = 'ASBR BGP 65003', bgp.asn = 65003,
    bgp.dataset = 'vexpertai-design-ontology'
MERGE (policy:RedistributionPolicy {id: 'ch3-policy-ospf-to-bgp'})
SET policy.name = 'OSPF-to-BGP Production Export',
    policy.direction = 'OSPF-to-BGP', policy.status = 'filtering',
    policy.dataset = 'vexpertai-design-ontology'
MERGE (routeMap:RouteMap {id: 'ch3-rm-ospf-to-bgp'})
SET routeMap.name = 'RM-OSPF-TO-BGP-CH3', routeMap.action = 'deny',
    routeMap.dataset = 'vexpertai-design-ontology'
MERGE (external:ExternalRoute {id: 'ch3-external-ospf-export'})
SET external.name = 'OSPF Application Export', external.cidr = '10.60.0.0/16',
    external.required = true, external.dataset = 'vexpertai-design-ontology'
MERGE (bgpRoute:Route:BGPRoute {id: 'ch3-bgp-route-10.60.0.0-16'})
SET bgpRoute.name = 'BGP 10.60.0.0/16', bgpRoute.cidr = '10.60.0.0/16',
    bgpRoute.state = 'filtered_by_route_map',
    bgpRoute.dataset = 'vexpertai-design-ontology'
WITH bgp, policy, routeMap, external, bgpRoute
MATCH (asbr:ASBR {id: 'ch3-asbr-01'}),
      (ospf:OSPFProcess {id: 'ch3-asbr-ospf-100'})
MERGE (asbr)-[:REDISTRIBUTES]->(external)
MERGE (ospf)-[:REDISTRIBUTES_TO]->(bgp)
MERGE (policy)-[:CONTROLLED_BY]->(routeMap)
MERGE (policy)-[:GOVERNS]->(external)
MERGE (policy)-[:GOVERNS]->(bgpRoute)
MERGE (bgpRoute)-[:ORIGINATED_FROM]->(ospf)
MERGE (bgpRoute)-[:ORIGINATED_FROM]->(external)
MERGE (bgpRoute)-[:ORIGINATED_FROM]->(policy);

// Scenario 4: DR/BDR instability causes adjacency churn and route loss.
MERGE (segment:BroadcastSegment {id: 'ch3-broadcast-vlan300'})
SET segment.name = 'Transit VLAN 300', segment.dr_changes = 6,
    segment.observation_window_minutes = 10,
    segment.dataset = 'vexpertai-design-ontology'
MERGE (dr:DR {id: 'ch3-dr-vlan300'})
SET dr.name = 'DR Role VLAN 300', dr.state = 'unstable',
    dr.dataset = 'vexpertai-design-ontology'
MERGE (bdr:BDR {id: 'ch3-bdr-vlan300'})
SET bdr.name = 'BDR Role VLAN 300', bdr.state = 'unstable',
    bdr.dataset = 'vexpertai-design-ontology'
MERGE (if1:Interface:OSPFInterface {id: 'ch3-dist-01:Vlan300'})
SET if1.name = 'Vlan300', if1.address = '10.3.0.11/24', if1.state = 'up',
    if1.dataset = 'vexpertai-design-ontology'
MERGE (if2:Interface:OSPFInterface {id: 'ch3-dist-02:Vlan300'})
SET if2.name = 'Vlan300', if2.address = '10.3.0.12/24', if2.state = 'flapping',
    if2.dataset = 'vexpertai-design-ontology'
MERGE (neighbor:OSPFNeighbor {id: 'ch3-neighbor-dist01-dist02'})
SET neighbor.name = 'dist-01 to dist-02', neighbor.state = 'exstart-flapping',
    neighbor.peer_router_id = '10.255.3.12', neighbor.flaps = 6,
    neighbor.dataset = 'vexpertai-design-ontology'
MERGE (risk:OSPFAdjacencyRisk {id: 'ch3-risk-dr-churn'})
SET risk.name = 'DR/BDR election churn causes route loss',
    risk.severity = 'high', risk.likelihood = 'high',
    risk.dataset = 'vexpertai-design-ontology'
WITH segment, dr, bdr, if1, if2, neighbor, risk
MATCH (dist1:OSPFRouter {id: 'ch3-dist-01'}), (dist2:OSPFRouter {id: 'ch3-dist-02'}),
      (broadcast:OSPFNetworkType {id: 'ch3-network-type-broadcast'})
MERGE (segment)-[:ELECTS]->(dr)
MERGE (segment)-[:ELECTS]->(bdr)
MERGE (dr)-[:OSPF_ROLE_ON]->(dist1)
MERGE (bdr)-[:OSPF_ROLE_ON]->(dist2)
MERGE (if1)-[:ATTACHED_TO]->(segment)
MERGE (if2)-[:ATTACHED_TO]->(segment)
MERGE (if1)-[:HAS_NETWORK_TYPE]->(broadcast)
MERGE (if2)-[:HAS_NETWORK_TYPE]->(broadcast)
MERGE (neighbor)-[:FORMED_OVER]->(if2)
MERGE (dist1)-[:HAS_OSPF_NEIGHBOR]->(neighbor)
MERGE (segment)-[:EXPOSES_ADJACENCY_RISK]->(risk)
MERGE (neighbor)-[:EXPOSES_ADJACENCY_RISK]->(risk);

MERGE (reach:Reachability {id: 'ch3-reach-broadcast-prefix'})
SET reach.name = 'Broadcast Segment Route Reachability', reach.state = 'lost',
    reach.dataset = 'vexpertai-design-ontology'
MERGE (prefix:Prefix {id: 'ch3-prefix-broadcast-dependent'})
SET prefix.name = 'Warehouse Service Prefix', prefix.cidr = '10.88.0.0/24',
    prefix.visibility = 'lost_after_adjacency_flap',
    prefix.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch3-service-warehouse'})
SET service.name = 'Warehouse Fulfillment', service.criticality = 'high',
    service.dataset = 'vexpertai-design-ontology'
WITH reach, prefix, service
MATCH (neighbor:OSPFNeighbor {id: 'ch3-neighbor-dist01-dist02'}),
      (risk:OSPFAdjacencyRisk {id: 'ch3-risk-dr-churn'})
MERGE (reach)-[:DEPENDS_ON]->(neighbor)
MERGE (reach)-[:PROVIDES_REACHABILITY_TO]->(prefix)
MERGE (prefix)-[:SUPPORTS]->(service)
MERGE (service)-[:DEPENDS_ON]->(prefix)
MERGE (risk)-[:IMPACTS]->(service);

// Scenario 5: bad summarization suppresses a required prefix.
MERGE (policy:SummarizationPolicy {id: 'ch3-summary-area10'})
SET policy.name = 'Area 10 Summary 10.30.0.0/16',
    policy.summary = '10.30.0.0/16', policy.status = 'overbroad',
    policy.dataset = 'vexpertai-design-ontology'
MERGE (prefix:Prefix {id: 'ch3-prefix-required-more-specific'})
SET prefix.name = 'Required Fraud API Prefix', prefix.cidr = '10.30.77.0/24',
    prefix.visibility = 'hidden_by_summary',
    prefix.dataset = 'vexpertai-design-ontology'
MERGE (lsa:LSA:SummaryLSA {id: 'ch3-summary-lsa-overbroad'})
SET lsa.name = 'Overbroad Area 10 Summary LSA', lsa.lsa_type = 3,
    lsa.advertising_router = '10.255.3.1', lsa.status = 'suppressed_more_specific',
    lsa.dataset = 'vexpertai-design-ontology'
MERGE (route:Route {id: 'ch3-route-fraud-api'})
SET route.name = 'OSPF Route 10.30.77.0/24', route.state = 'missing',
    route.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch3-service-fraud-api'})
SET service.name = 'Fraud Detection API', service.criticality = 'critical',
    service.dataset = 'vexpertai-design-ontology'
WITH policy, prefix, lsa, route, service
MATCH (abr:ABR {id: 'ch3-abr-01'}), (area10:OSPFArea {id: 'ch3-area-10'}),
      (type3:LSAType {id: 'ch3-lsa-type-3'})
MERGE (policy)-[:APPLIED_ON]->(abr)
MERGE (policy)-[:SUMMARIZES {result: 'hidden'}]->(prefix)
MERGE (prefix)-[:ORIGINATES_IN]->(area10)
MERGE (prefix)-[:ADVERTISED_BY]->(lsa)
MERGE (lsa)-[:HAS_LSA_TYPE]->(type3)
MERGE (route)-[:DEPENDS_ON]->(lsa)
MERGE (prefix)-[:SUPPORTS]->(service)
MERGE (service)-[:DEPENDS_ON]->(prefix);

// Convergence, metric, and local-repair semantics.
MERGE (spf:SPFComputation {id: 'ch3-spf-abr-01'})
SET spf.name = 'abr-01 SPF Computation', spf.duration_ms = 420,
    spf.schedule_delay_ms = 200, spf.dataset = 'vexpertai-design-ontology'
MERGE (convergence:OSPFConvergence {id: 'ch3-convergence-area10'})
SET convergence.name = 'Area 10 Convergence', convergence.target_ms = 1000,
    convergence.observed_ms = 1800, convergence.dataset = 'vexpertai-design-ontology'
MERGE (cost:Cost:OSPFMetric {id: 'ch3-cost-abr-area10'})
SET cost.name = 'ABR Area 10 Interface Cost', cost.value = 10,
    cost.dataset = 'vexpertai-design-ontology'
MERGE (lfa:LFA {id: 'ch3-lfa-area10'})
SET lfa.name = 'Area 10 Loop-Free Alternate', lfa.status = 'available',
    lfa.dataset = 'vexpertai-design-ontology'
MERGE (frr:FastReroute {id: 'ch3-frr-area10'})
SET frr.name = 'Area 10 OSPF Fast Reroute', frr.status = 'enabled',
    frr.dataset = 'vexpertai-design-ontology'
WITH spf, convergence, cost, lfa, frr
MATCH (process:OSPFProcess {id: 'ch3-abr-ospf-100'}),
      (interface:OSPFInterface {id: 'ch3-abr-01:Ethernet1/10'}),
      (route:Route {id: 'ch3-route-area10-app'})
MERGE (process)-[:COMPUTES]->(spf)
MERGE (convergence)-[:DEPENDS_ON]->(spf)
MERGE (interface)-[:HAS_METRIC]->(cost)
MERGE (route)-[:PROTECTS_WITH]->(lfa)
MERGE (route)-[:PROTECTS_WITH]->(frr);
