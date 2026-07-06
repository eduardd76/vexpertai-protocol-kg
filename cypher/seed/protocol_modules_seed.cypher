// Layer 2, STP, and FHRP.
MERGE (stp:STPInstance {id: 'view-stp-vlan100'})
SET stp.name = 'STP VLAN 100', stp.module = 'fhrp',
    stp.dataset = 'vexpertai-design-ontology'
MERGE (root:STPRootBridge {id: 'view-stp-root-vlan100'})
SET root.name = 'VLAN 100 STP Root on Dist-01',
    root.device_id = 'view-device-dist-01', root.module = 'fhrp',
    root.dataset = 'vexpertai-design-ontology'
MERGE (fhrp:FHRPGroup:FirstHopRedundancyGroup:HSRPGroup {id: 'view-fhrp-vlan100'})
SET fhrp.name = 'VLAN 100 HSRP', fhrp.active_device_id = 'view-device-dist-02',
    fhrp.standby_device_id = 'view-device-dist-01', fhrp.module = 'fhrp',
    fhrp.dataset = 'vexpertai-design-ontology'
MERGE (gateway:DefaultGateway {id: 'view-gateway-vlan100'})
SET gateway.name = 'VLAN 100 Default Gateway', gateway.address = '10.100.0.1',
    gateway.module = 'fhrp', gateway.dataset = 'vexpertai-design-ontology'
WITH stp, root, fhrp, gateway
MATCH (vlan:VLAN {id: 'view-vlan-100'}),
      (dist1:Device {id: 'view-device-dist-01'}),
      (dist2:Device {id: 'view-device-dist-02'})
MERGE (vlan)-[:MAPPED_TO]->(stp)
MERGE (stp)-[:ELECTS]->(root)
MERGE (root)-[:ROLE_ON]->(dist1)
MERGE (fhrp)-[:PROVIDES]->(gateway)
MERGE (fhrp)-[:ACTIVE_ON]->(dist2)
MERGE (fhrp)-[:STANDBY_ON]->(dist1)
MERGE (root)-[:STP_ROOT_SHOULD_ALIGN_WITH_FHRP_ACTIVE {interaction: 'stp-fhrp'}]->(fhrp);

// OSPF underlay and Payment-App prefix origin.
MERGE (ospf:Protocol:ProtocolInstance:RoutingProtocolInstance:OSPFProcess {id: 'view-ospf-100'})
SET ospf.name = 'OSPF Process 100', ospf.process_id = 100,
    ospf.router_id = '10.255.100.1', ospf.state = 'up', ospf.module = 'ospf',
    ospf.dataset = 'vexpertai-design-ontology'
MERGE (area:OSPFArea:BackboneArea {id: 'view-ospf-area0'})
SET area.name = 'OSPF Area 0', area.area_id = '0.0.0.0',
    area.area_type = 'backbone', area.module = 'ospf',
    area.dataset = 'vexpertai-design-ontology'
MERGE (lsa:LSA:RouterLSA {id: 'view-lsa-payment-prefix'})
SET lsa.name = 'Payment Prefix Router LSA', lsa.lsa_type = 1,
    lsa.advertising_router = '10.255.100.1', lsa.module = 'ospf',
    lsa.dataset = 'vexpertai-design-ontology'
MERGE (igp:IGPReachability:InternalReachability {id: 'view-igp-payment'})
SET igp.name = 'Payment-App IGP Reachability', igp.state = 'up',
    igp.module = 'ospf', igp.dataset = 'vexpertai-design-ontology'
MERGE (prefix:Prefix {id: 'view-prefix-payment'})
SET prefix.name = 'Payment-App Prefix', prefix.cidr = '10.20.30.0/24',
    prefix.state = 'withdrawn_from_bgp', prefix.module = 'ospf',
    prefix.dataset = 'vexpertai-design-ontology'
WITH ospf, area, lsa, igp, prefix
MATCH (dist1:Device {id: 'view-device-dist-01'}),
      (uplink:Interface {id: 'view-interface-ethernet1-49'}),
      (vrf:VRF {id: 'view-vrf-prod'}),
      (fhrp:FHRPGroup {id: 'view-fhrp-vlan100'})
MERGE (ospf)-[:RUNS_ON]->(dist1)
MERGE (ospf)-[:CONTAINS]->(area)
MERGE (area)-[:CONTAINS]->(uplink)
MERGE (lsa)-[:ADVERTISES]->(prefix)
MERGE (prefix)-[:LEARNED_BY]->(ospf)
MERGE (prefix)-[:BELONGS_TO]->(vrf)
MERGE (ospf)-[:PROVIDES_REACHABILITY]->(igp)
MERGE (fhrp)-[:FHRP_ACTIVE_SHOULD_TRACK_IGP_REACHABILITY {interaction: 'fhrp-ospf'}]->(igp);

// BGP redistribution policy.
MERGE (bgp:Protocol:ProtocolInstance:RoutingProtocolInstance:BGPProcess {id: 'view-bgp-65001'})
SET bgp.name = 'BGP AS 65001', bgp.asn = 65001,
    bgp.router_id = '10.255.100.2', bgp.state = 'degraded',
    bgp.module = 'bgp', bgp.dataset = 'vexpertai-design-ontology'
MERGE (autonomousSystem:AutonomousSystem {id: 'view-as-65001'})
SET autonomousSystem.name = 'AS 65001', autonomousSystem.asn = 65001,
    autonomousSystem.module = 'bgp',
    autonomousSystem.dataset = 'vexpertai-design-ontology'
MERGE (neighbor:BGPNeighbor {id: 'view-bgp-neighbor-pe01'})
SET neighbor.name = 'PE-01 BGP Neighbor', neighbor.peer_address = '10.255.100.3',
    neighbor.session_state = 'established', neighbor.module = 'bgp',
    neighbor.dataset = 'vexpertai-design-ontology'
MERGE (routeMap:Policy:RouteMap {id: 'view-rm-ospf-to-bgp'})
SET routeMap.name = 'RM-OSPF-TO-BGP', routeMap.module = 'bgp',
    routeMap.dataset = 'vexpertai-design-ontology'
MERGE (prefixList:Policy:PrefixList {id: 'view-pl-prod'})
SET prefixList.name = 'PL-PROD', prefixList.action = 'deny',
    prefixList.previous_action = 'permit', prefixList.module = 'bgp',
    prefixList.dataset = 'vexpertai-design-ontology'
MERGE (rule:RedistributionRule {id: 'view-redist-ospf-bgp'})
SET rule.name = 'OSPF-to-BGP PROD Redistribution', rule.state = 'filtered',
    rule.module = 'bgp', rule.dataset = 'vexpertai-design-ontology'
MERGE (bgpRoute:Route:BGPRoute {id: 'view-bgp-route-payment'})
SET bgpRoute.name = 'BGP Payment-App Route', bgpRoute.cidr = '10.20.30.0/24',
    bgpRoute.state = 'withdrawn', bgpRoute.module = 'bgp',
    bgpRoute.dataset = 'vexpertai-design-ontology'
MERGE (nextHop:NextHop {id: 'view-next-hop-payment'})
SET nextHop.name = 'Payment-App BGP Next Hop', nextHop.address = '10.255.100.3',
    nextHop.module = 'bgp', nextHop.dataset = 'vexpertai-design-ontology'
WITH bgp, autonomousSystem, neighbor, routeMap, prefixList, rule, bgpRoute, nextHop
MATCH (edge:Device {id: 'view-device-dc-edge-01'}),
      (ospf:OSPFProcess {id: 'view-ospf-100'}),
      (igp:IGPReachability {id: 'view-igp-payment'}),
      (prefix:Prefix {id: 'view-prefix-payment'})
MERGE (bgp)-[:RUNS_ON]->(edge)
MERGE (bgp)-[:BELONGS_TO]->(autonomousSystem)
MERGE (bgp)-[:HAS_NEIGHBOR]->(neighbor)
MERGE (neighbor)-[:BGP_NEIGHBOR_DEPENDS_ON_IGP_REACHABILITY {interaction: 'ospf-bgp'}]->(igp)
MERGE (bgpRoute)-[:BGP_ROUTE_DEPENDS_ON_NEXT_HOP_REACHABILITY {interaction: 'ospf-bgp'}]->(igp)
MERGE (bgpRoute)-[:RESOLVES_TO]->(nextHop)
MERGE (ospf)-[:REDISTRIBUTES_TO]->(bgp)
MERGE (prefix)-[:OSPF_ROUTE_REDISTRIBUTED_INTO_BGP {interaction: 'ospf-bgp'}]->(bgpRoute)
MERGE (routeMap)-[:REFERENCES]->(prefixList)
MERGE (routeMap)-[:ROUTE_MAP_CONTROLS_REDISTRIBUTION {interaction: 'ospf-bgp'}]->(rule)
MERGE (prefixList)-[:PREFIX_LIST_CONTROLS_PREFIX_VISIBILITY {interaction: 'ospf-bgp'}]->(prefix)
MERGE (rule)-[:REDISTRIBUTION_PRODUCES_BGP_ROUTE]->(bgpRoute)
MERGE (bgpRoute)-[:BGP_ROUTE_CARRIES_PREFIX]->(prefix);

// MPLS L3VPN with correct RT but missing label path.
MERGE (vpn:OverlayService:MPLSService:MPLSL3VPN {id: 'view-mpls-vpn-payment'})
SET vpn.name = 'Payment MPLS L3VPN', vpn.service_type = 'MPLS L3VPN',
    vpn.status = 'blackhole', vpn.module = 'mpls',
    vpn.dataset = 'vexpertai-design-ontology'
MERGE (lsp:LSP:MPLSLSP:LabelSwitchedPath {id: 'view-lsp-payment'})
SET lsp.name = 'PE-01 to Remote-PE LSP', lsp.state = 'missing',
    lsp.module = 'mpls', lsp.dataset = 'vexpertai-design-ontology'
MERGE (label:MPLSLabel {id: 'view-label-payment'})
SET label.name = 'Payment VPN Label', label.state = 'missing',
    label.module = 'mpls', label.dataset = 'vexpertai-design-ontology'
MERGE (vpnRoute:Route:VPNRoute:VPNv4Route {id: 'view-vpnv4-payment'})
SET vpnRoute.name = 'Payment VPNv4 Route', vpnRoute.prefix = '10.20.30.0/24',
    vpnRoute.state = 'present', vpnRoute.module = 'mpls',
    vpnRoute.dataset = 'vexpertai-design-ontology'
MERGE (rt:RouteTarget {id: 'view-rt-prod'})
SET rt.name = 'RT 65001:100', rt.value = '65001:100',
    rt.module = 'mpls', rt.dataset = 'vexpertai-design-ontology'
MERGE (underlay:IGPUnderlay:TransportUnderlay {id: 'view-mpls-underlay'})
SET underlay.name = 'MPLS IGP Underlay', underlay.state = 'degraded',
    underlay.module = 'mpls', underlay.dataset = 'vexpertai-design-ontology'
WITH vpn, lsp, label, vpnRoute, rt, underlay
MATCH (vrf:VRF {id: 'view-vrf-prod'}),
      (bgpRoute:BGPRoute {id: 'view-bgp-route-payment'}),
      (ospf:OSPFProcess {id: 'view-ospf-100'})
MERGE (vpn)-[:USES]->(vrf)
MERGE (vrf)-[:IMPORTS]->(rt)
MERGE (vpnRoute)-[:IMPORTED_BY]->(rt)
MERGE (vpn)-[:MPLS_SERVICE_DEPENDS_ON_LSP {interaction: 'mpls-vpn'}]->(lsp)
MERGE (lsp)-[:MPLS_LSP_DEPENDS_ON_IGP_UNDERLAY {interaction: 'overlay-underlay'}]->(underlay)
MERGE (lsp)-[:MPLS_LSP_DEPENDS_ON_IGP_UNDERLAY {interaction: 'overlay-underlay'}]->(ospf)
MERGE (vpnRoute)-[:VPN_ROUTE_DEPENDS_ON_MPLS_LABEL {interaction: 'bgp-mpls'}]->(label)
MERGE (bgpRoute)-[:VPN_ROUTE_DEPENDS_ON_MPLS_LABEL {interaction: 'bgp-mpls'}]->(label);

// Firewall and QoS application path.
MERGE (firewall:Firewall {id: 'view-firewall-dc'})
SET firewall.name = 'DC-FW-01', firewall.module = 'security',
    firewall.dataset = 'vexpertai-design-ontology'
MERGE (rule:Policy:SecurityPolicy:FirewallRule {id: 'view-firewall-rule-payment'})
SET rule.name = 'Allow Branch to Payment-App', rule.action = 'allow',
    rule.module = 'security', rule.dataset = 'vexpertai-design-ontology'
MERGE (flow:TrafficFlow {id: 'view-flow-payment'})
SET flow.name = 'Branch HTTPS to Payment-App', flow.state = 'allowed',
    flow.module = 'security', flow.dataset = 'vexpertai-design-ontology'
MERGE (qos:Policy:QoSPolicy {id: 'view-qos-payment'})
SET qos.name = 'WAN Payment QoS', qos.status = 'misclassified',
    qos.module = 'qos', qos.dataset = 'vexpertai-design-ontology'
MERGE (classMap:ClassMap {id: 'view-classmap-payment'})
SET classMap.name = 'CM-PAYMENT', classMap.module = 'qos',
    classMap.dataset = 'vexpertai-design-ontology'
MERGE (bestEffort:QoSClass:BestEffortTraffic {id: 'view-qos-best-effort'})
SET bestEffort.name = 'BEST-EFFORT', bestEffort.module = 'qos',
    bestEffort.dataset = 'vexpertai-design-ontology'
MERGE (congestion:CongestionEvent {id: 'view-congestion-wan'})
SET congestion.name = 'Branch WAN Congestion', congestion.severity = 'high',
    congestion.module = 'qos', congestion.dataset = 'vexpertai-design-ontology'
WITH firewall, rule, flow, qos, classMap, bestEffort, congestion
MATCH (application:Application {id: 'view-application-payment'}),
      (endpoint:ApplicationEndpoint {id: 'view-endpoint-payment'}),
      (sla:SLA {id: 'view-sla-payment'}),
      (service:BusinessService {id: 'view-service-payment'}),
      (uplink:Interface {id: 'view-interface-ethernet1-49'})
MERGE (firewall)-[:ENFORCES]->(rule)
MERGE (rule)-[:ALLOWS]->(flow)
MERGE (rule)-[:FIREWALL_POLICY_CONTROLS_APPLICATION_PATH {interaction: 'firewall-application'}]->(flow)
MERGE (rule)-[:FIREWALL_POLICY_CONTROLS_APPLICATION_PATH {interaction: 'firewall-application'}]->(application)
MERGE (application)-[:DEPENDS_ON]->(flow)
MERGE (application)-[:DEPENDS_ON]->(endpoint)
MERGE (application)-[:CLASSIFIED_BY]->(classMap)
MERGE (classMap)-[:MAPS_TO]->(bestEffort)
MERGE (qos)-[:APPLIED_TO]->(uplink)
MERGE (qos)-[:QOS_POLICY_PROTECTS_APPLICATION_SLA {interaction: 'qos-wan'}]->(sla)
MERGE (congestion)-[:AFFECTS]->(uplink)
MERGE (service)-[:IMPACTED_BY]->(congestion);

// Compact end-to-end layer chain for service and failure projections.
MATCH (access:Interface {id: 'view-interface-branch-access'}),
      (vlan:VLAN {id: 'view-vlan-100'}),
      (fhrp:FHRPGroup {id: 'view-fhrp-vlan100'}),
      (ospf:OSPFProcess {id: 'view-ospf-100'}),
      (bgp:BGPProcess {id: 'view-bgp-65001'}),
      (vpn:MPLSL3VPN {id: 'view-mpls-vpn-payment'}),
      (firewall:FirewallRule {id: 'view-firewall-rule-payment'}),
      (qos:QoSPolicy {id: 'view-qos-payment'}),
      (application:Application {id: 'view-application-payment'}),
      (service:BusinessService {id: 'view-service-payment'}),
      (uplink:Interface {id: 'view-interface-ethernet1-49'})
MERGE (access)-[:SUPPORTS_LAYER]->(vlan)
MERGE (uplink)-[:SUPPORTS_LAYER]->(vlan)
MERGE (vlan)-[:SUPPORTS_LAYER]->(fhrp)
MERGE (fhrp)-[:SUPPORTS_LAYER]->(ospf)
MERGE (ospf)-[:SUPPORTS_LAYER]->(bgp)
MERGE (bgp)-[:SUPPORTS_LAYER]->(vpn)
MERGE (vpn)-[:SUPPORTS_LAYER]->(firewall)
MERGE (firewall)-[:SUPPORTS_LAYER]->(qos)
MERGE (qos)-[:SUPPORTS_LAYER]->(application)
MERGE (application)-[:SUPPORTS_LAYER]->(service);
