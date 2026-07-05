// Campus Layer 2 topology, hierarchy, and aggregation.
MERGE (dist1:Device:Switch {id: 'l2-dist-01'})
SET dist1.name = 'dist-01', dist1.layer_role = 'distribution',
    dist1.dataset = 'vexpertai-design-ontology'
MERGE (dist2:Device:Switch {id: 'l2-dist-02'})
SET dist2.name = 'dist-02', dist2.layer_role = 'distribution',
    dist2.dataset = 'vexpertai-design-ontology'
MERGE (access1:Device:Switch {id: 'l2-access-01'})
SET access1.name = 'access-01', access1.layer_role = 'access',
    access1.dataset = 'vexpertai-design-ontology'
MERGE (accessLayer:AccessLayer {id: 'l2-access-layer'})
SET accessLayer.name = 'Campus Access Layer',
    accessLayer.dataset = 'vexpertai-design-ontology'
MERGE (distributionLayer:DistributionLayer {id: 'l2-distribution-layer'})
SET distributionLayer.name = 'Campus Distribution Layer',
    distributionLayer.dataset = 'vexpertai-design-ontology'
MERGE (vtp:VTPDomain {id: 'vtp-campus'})
SET vtp.name = 'CAMPUS', vtp.mode = 'transparent',
    vtp.dataset = 'vexpertai-design-ontology'
MERGE (mlag:MLAG {id: 'mlag-dist-pair'})
SET mlag.name = 'Distribution MLAG Pair', mlag.domain_id = 10,
    mlag.dataset = 'vexpertai-design-ontology'
MERGE (accessLayer)-[:CONTAINS_SWITCH]->(access1)
MERGE (distributionLayer)-[:CONTAINS_SWITCH]->(dist1)
MERGE (distributionLayer)-[:CONTAINS_SWITCH]->(dist2)
MERGE (dist1)-[:MEMBER_OF_VTP]->(vtp)
MERGE (dist2)-[:MEMBER_OF_VTP]->(vtp)
MERGE (access1)-[:MEMBER_OF_VTP]->(vtp)
MERGE (mlag)-[:SPANS]->(dist1)
MERGE (mlag)-[:SPANS]->(dist2);

MERGE (dist1member:Interface {id: 'l2-dist-01:Ethernet1/47'})
SET dist1member.name = 'Ethernet1/47', dist1member.status = 'up',
    dist1member.dataset = 'vexpertai-design-ontology'
MERGE (dist2member:Interface {id: 'l2-dist-02:Ethernet1/47'})
SET dist2member.name = 'Ethernet1/47', dist2member.status = 'up',
    dist2member.dataset = 'vexpertai-design-ontology'
MERGE (accessMember:Interface {id: 'l2-access-01:Ethernet1/49'})
SET accessMember.name = 'Ethernet1/49', accessMember.status = 'up',
    accessMember.dataset = 'vexpertai-design-ontology'
MERGE (pc1:Interface:Trunk:PortChannel {id: 'l2-dist-01:PortChannel10'})
SET pc1.name = 'dist-01 PortChannel10', pc1.allowed_vlans = [10, 20, 30],
    pc1.unused_vlans = [20], pc1.unused_vlan_count = 1,
    pc1.dataset = 'vexpertai-design-ontology'
MERGE (pc2:Interface:Trunk:PortChannel:STPBlockedPort {id: 'l2-dist-02:PortChannel10'})
SET pc2.name = 'dist-02 PortChannel10', pc2.allowed_vlans = [10, 20, 30],
    pc2.unused_vlans = [20], pc2.unused_vlan_count = 1,
    pc2.status = 'blocking', pc2.reason = 'Alternate path to VLAN 10 root',
    pc2.dataset = 'vexpertai-design-ontology'
MERGE (accessTrunk:Interface:Trunk {id: 'l2-access-01:Ethernet1/49-trunk'})
SET accessTrunk.name = 'access-01 uplink', accessTrunk.allowed_vlans = [10, 20, 30],
    accessTrunk.unused_vlans = [20], accessTrunk.unused_vlan_count = 1,
    accessTrunk.dataset = 'vexpertai-design-ontology'
MERGE (lag:LAG {id: 'lag-access-uplink'})
SET lag.name = 'Access Uplink LAG', lag.protocol = 'LACP',
    lag.dataset = 'vexpertai-design-ontology'
WITH dist1member, dist2member, accessMember, pc1, pc2, accessTrunk, lag
MATCH (dist1:Device {id: 'l2-dist-01'}), (dist2:Device {id: 'l2-dist-02'}),
      (access1:Device {id: 'l2-access-01'})
MERGE (dist1)-[:HAS_INTERFACE]->(dist1member)
MERGE (dist2)-[:HAS_INTERFACE]->(dist2member)
MERGE (access1)-[:HAS_INTERFACE]->(accessMember)
MERGE (dist1)-[:HAS_INTERFACE]->(pc1)
MERGE (dist2)-[:HAS_INTERFACE]->(pc2)
MERGE (access1)-[:HAS_INTERFACE]->(accessTrunk)
MERGE (pc1)-[:AGGREGATES]->(dist1member)
MERGE (pc2)-[:AGGREGATES]->(dist2member)
MERGE (lag)-[:AGGREGATES]->(accessMember);

// VLANs, bridge domains, Ethernet segments, and trunk carriage.
MERGE (vlan10:VLAN {id: 'l2-vlan-10'})
SET vlan10.name = 'PAYMENTS', vlan10.vlan_id = 10, vlan10.active_endpoints = 120,
    vlan10.dataset = 'vexpertai-design-ontology'
MERGE (vlan20:VLAN {id: 'l2-vlan-20'})
SET vlan20.name = 'LEGACY-UNUSED', vlan20.vlan_id = 20, vlan20.active_endpoints = 0,
    vlan20.dataset = 'vexpertai-design-ontology'
MERGE (vlan30:VLAN {id: 'l2-vlan-30'})
SET vlan30.name = 'INVENTORY', vlan30.vlan_id = 30, vlan30.active_endpoints = 42,
    vlan30.dataset = 'vexpertai-design-ontology'
MERGE (bridge10:BridgeDomain {id: 'bridge-domain-10'})
SET bridge10.name = 'Payments Bridge Domain', bridge10.scope = 'campus-building-a',
    bridge10.dataset = 'vexpertai-design-ontology'
MERGE (segment10:EthernetSegment {id: 'ethernet-segment-payments'})
SET segment10.name = 'Payments Access Segment',
    segment10.dataset = 'vexpertai-design-ontology'
WITH vlan10, vlan20, vlan30, bridge10, segment10
MATCH (pc1:Trunk {id: 'l2-dist-01:PortChannel10'}),
      (pc2:Trunk {id: 'l2-dist-02:PortChannel10'}),
      (accessTrunk:Trunk {id: 'l2-access-01:Ethernet1/49-trunk'})
MERGE (vlan10)-[:CARRIED_BY]->(pc1)
MERGE (vlan10)-[:CARRIED_BY]->(pc2)
MERGE (vlan10)-[:CARRIED_BY]->(accessTrunk)
MERGE (vlan20)-[:CARRIED_BY]->(pc1)
MERGE (vlan20)-[:CARRIED_BY]->(pc2)
MERGE (vlan20)-[:CARRIED_BY]->(accessTrunk)
MERGE (vlan30)-[:CARRIED_BY]->(pc1)
MERGE (vlan30)-[:CARRIED_BY]->(pc2)
MERGE (vlan30)-[:CARRIED_BY]->(accessTrunk)
MERGE (bridge10)-[:EXTENDS]->(segment10)
MERGE (vlan10)-[:EXTENDS]->(segment10);

// Scenario 1: STP root on dist-01, HSRP active on dist-02.
MERGE (region:STPRegion {id: 'stp-region-campus'})
SET region.name = 'CAMPUS-MST', region.revision = 7,
    region.dataset = 'vexpertai-design-ontology'
MERGE (stp:STPInstance {id: 'stp-instance-10'})
SET stp.name = 'MST Instance 10', stp.instance_id = 10, stp.mode = 'MST',
    stp.dataset = 'vexpertai-design-ontology'
MERGE (root:STPRootBridge {id: 'stp-root-vlan-10'})
SET root.name = 'VLAN 10 STP Root', root.priority = 4096,
    root.dataset = 'vexpertai-design-ontology'
MERGE (placement:STPRootPlacement {id: 'stp-root-placement-campus'})
SET placement.name = 'Distribution switches own STP root roles',
    placement.dataset = 'vexpertai-design-ontology'
MERGE (rootGuard:RootGuard {id: 'root-guard-access-uplinks'})
SET rootGuard.name = 'Root Guard on Distribution-Facing Access Ports',
    rootGuard.enabled = true, rootGuard.dataset = 'vexpertai-design-ontology'
MERGE (loopGuard:LoopGuard {id: 'loop-guard-interdistribution'})
SET loopGuard.name = 'Loop Guard on Alternate Distribution Path',
    loopGuard.enabled = true, loopGuard.dataset = 'vexpertai-design-ontology'
MERGE (unidirectional:UnidirectionalLinkFailure {id: 'failure-unidirectional-interdistribution'})
SET unidirectional.name = 'Inter-distribution Unidirectional Failure',
    unidirectional.dataset = 'vexpertai-design-ontology'
WITH region, stp, root, placement, rootGuard, loopGuard, unidirectional
MATCH (vlan10:VLAN {id: 'l2-vlan-10'}),
      (bridge10:BridgeDomain {id: 'bridge-domain-10'}),
      (dist1:Switch {id: 'l2-dist-01'}), (dist2:Switch {id: 'l2-dist-02'}),
      (blocked:STPBlockedPort {id: 'l2-dist-02:PortChannel10'})
MERGE (vlan10)-[:MAPPED_TO]->(stp)
MERGE (stp)-[:MEMBER_OF_REGION]->(region)
MERGE (dist1)-[:MEMBER_OF_REGION]->(region)
MERGE (dist2)-[:MEMBER_OF_REGION]->(region)
MERGE (stp)-[:CONTROLS_BRIDGE_DOMAIN]->(bridge10)
MERGE (stp)-[:ELECTS]->(root)
MERGE (stp)-[:BLOCKS]->(blocked)
MERGE (root)-[:ROLE_ON]->(dist1)
MERGE (rootGuard)-[:PROTECTS]->(placement)
MERGE (loopGuard)-[:PROTECTS]->(unidirectional);

MERGE (hsrp:FirstHopRedundancyGroup:HSRPGroup {id: 'hsrp-vlan-10'})
SET hsrp.name = 'HSRP VLAN 10', hsrp.group_id = 10, hsrp.vlan_id = 10,
    hsrp.dataset = 'vexpertai-design-ontology'
MERGE (active:FHRPActiveGateway {id: 'hsrp-vlan-10-active'})
SET active.name = 'HSRP Active on dist-02',
    active.dataset = 'vexpertai-design-ontology'
MERGE (standby:FHRPStandbyGateway {id: 'hsrp-vlan-10-standby'})
SET standby.name = 'HSRP Standby on dist-01',
    standby.dataset = 'vexpertai-design-ontology'
MERGE (gateway:DefaultGateway {id: 'gateway-vlan-10'})
SET gateway.name = 'Payments Default Gateway',
    gateway.dataset = 'vexpertai-design-ontology'
MERGE (vip:VirtualIP {id: 'vip-10.10.10.1'})
SET vip.name = '10.10.10.1', vip.address = '10.10.10.1',
    vip.dataset = 'vexpertai-design-ontology'
MERGE (vmac:VirtualMAC {id: 'vmac-hsrp-10'})
SET vmac.name = '0000.0c07.ac0a', vmac.address = '0000.0c07.ac0a',
    vmac.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'l2-payment-service'})
SET service.name = 'Payment-App Campus Access', service.criticality = 'critical',
    service.dataset = 'vexpertai-design-ontology'
MERGE (risk:Layer2Risk {id: 'risk-stp-fhrp-misalignment'})
SET risk.name = 'Suboptimal inter-distribution Layer 2 transit',
    risk.severity = 'medium', risk.likelihood = 'high',
    risk.summary = 'STP root is dist-01 while the HSRP active gateway is dist-02.',
    risk.dataset = 'vexpertai-design-ontology'
WITH hsrp, active, standby, gateway, vip, vmac, service, risk
MATCH (vlan10:VLAN {id: 'l2-vlan-10'}),
      (root:STPRootBridge {id: 'stp-root-vlan-10'}),
      (dist1:Switch {id: 'l2-dist-01'}), (dist2:Switch {id: 'l2-dist-02'})
MERGE (vlan10)-[:USES_FHRP]->(hsrp)
MERGE (hsrp)-[:PROVIDES]->(gateway)
MERGE (hsrp)-[:HAS_ACTIVE_GATEWAY]->(active)
MERGE (hsrp)-[:HAS_STANDBY_GATEWAY]->(standby)
MERGE (hsrp)-[:HAS_VIRTUAL_IP]->(vip)
MERGE (hsrp)-[:HAS_VIRTUAL_MAC]->(vmac)
MERGE (gateway)-[:HAS_VIRTUAL_IP]->(vip)
MERGE (active)-[:ROLE_ON]->(dist2)
MERGE (standby)-[:ROLE_ON]->(dist1)
MERGE (root)-[:SHOULD_ALIGN_WITH]->(active)
MERGE (root)-[:EXPOSES_RISK]->(risk)
MERGE (risk)-[:IMPACTS]->(service)
MERGE (service)-[:DEPENDS_ON]->(vlan10);

// Scenario 2: BPDU guard shuts an edge port after an unexpected BPDU.
MERGE (port:Interface:AccessPort {id: 'l2-access-01:Ethernet1/10'})
SET port.name = 'Ethernet1/10', port.status = 'errdisabled',
    port.shutdown_reason = 'BPDU Guard', port.dataset = 'vexpertai-design-ontology'
MERGE (portfast:PortFast {id: 'portfast-access-ports'})
SET portfast.name = 'PortFast Edge', portfast.enabled = true,
    portfast.dataset = 'vexpertai-design-ontology'
MERGE (guard:BPDUGuard {id: 'bpduguard-access-ports'})
SET guard.name = 'BPDU Guard on Access Ports', guard.enabled = true,
    guard.dataset = 'vexpertai-design-ontology'
MERGE (filter:BPDUFilter {id: 'bpdufilter-exception-policy'})
SET filter.name = 'BPDU Filter Exception Policy', filter.enabled = false,
    filter.dataset = 'vexpertai-design-ontology'
MERGE (bpdu:BPDU {id: 'bpdu-access-01-eth1-10'})
SET bpdu.name = 'Unexpected superior BPDU', bpdu.source_mac = '00aa.bbcc.ddee',
    bpdu.timestamp = '2026-07-05T11:05:00Z',
    bpdu.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'evidence-bpduguard-shutdown'})
SET evidence.name = 'BPDU guard syslog and interface state',
    evidence.summary = 'Ethernet1/10 received a superior BPDU and transitioned to err-disabled.',
    evidence.source = 'syslog://access-01/Ethernet1/10',
    evidence.dataset = 'vexpertai-design-ontology'
MERGE (risk:Layer2Risk {id: 'risk-unexpected-edge-switch'})
SET risk.name = 'Unexpected switch connected to access port',
    risk.severity = 'high', risk.likelihood = 'medium',
    risk.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'l2-inventory-service'})
SET service.name = 'Inventory Workstation Access', service.criticality = 'medium',
    service.dataset = 'vexpertai-design-ontology'
WITH port, portfast, guard, filter, bpdu, evidence, risk, service
MATCH (access:Device {id: 'l2-access-01'}), (vlan30:VLAN {id: 'l2-vlan-30'})
MERGE (access)-[:HAS_INTERFACE]->(port)
MERGE (port)-[:BELONGS_TO]->(vlan30)
MERGE (port)-[:USES_FEATURE]->(portfast)
MERGE (port)-[:USES_FEATURE]->(guard)
MERGE (port)-[:USES_FEATURE]->(filter)
MERGE (guard)-[:PROTECTS]->(port)
MERGE (bpdu)-[:RECEIVED_ON]->(port)
MERGE (bpdu)-[:TRIGGERS]->(guard)
MERGE (guard)-[:SHUTS_DOWN]->(port)
MERGE (port)-[:EXPOSES_RISK]->(risk)
MERGE (risk)-[:IMPACTS]->(service)
MERGE (service)-[:DEPENDS_ON]->(vlan30)
MERGE (evidence)-[:OBSERVED_ON]->(port);

// Scenario 3: mismatched native VLANs expose a VLAN hopping risk.
MERGE (nativeLeft:NativeVLAN {id: 'native-vlan-dist-01-po10'})
SET nativeLeft.name = 'dist-01 Po10 native VLAN 10', nativeLeft.vlan_id = 10,
    nativeLeft.status = 'mismatched', nativeLeft.dataset = 'vexpertai-design-ontology'
MERGE (nativeRight:NativeVLAN {id: 'native-vlan-dist-02-po10'})
SET nativeRight.name = 'dist-02 Po10 native VLAN 99', nativeRight.vlan_id = 99,
    nativeRight.status = 'mismatched', nativeRight.dataset = 'vexpertai-design-ontology'
MERGE (risk:Layer2Risk:VLANHoppingRisk {id: 'risk-native-vlan-hopping'})
SET risk.name = 'VLAN hopping through native VLAN mismatch',
    risk.severity = 'critical', risk.likelihood = 'medium',
    risk.summary = 'Untagged frames are classified into different VLANs at opposite trunk ends.',
    risk.dataset = 'vexpertai-design-ontology'
WITH nativeLeft, nativeRight, risk
MATCH (left:Trunk {id: 'l2-dist-01:PortChannel10'}),
      (right:Trunk {id: 'l2-dist-02:PortChannel10'}),
      (service:BusinessService {id: 'l2-payment-service'})
MERGE (left)-[:HAS_NATIVE_VLAN]->(nativeLeft)
MERGE (right)-[:HAS_NATIVE_VLAN]->(nativeRight)
MERGE (nativeLeft)-[:MISMATCHED_WITH]->(nativeRight)
MERGE (nativeLeft)-[:MAY_ENABLE]->(risk)
MERGE (nativeLeft)-[:EXPOSES_RISK]->(risk)
MERGE (risk)-[:IMPACTS]->(service);

// Additional FHRP forms make protocol roles explicit without full state tables.
MERGE (vrrp:FirstHopRedundancyGroup:VRRPGroup {id: 'vrrp-vlan-30'})
SET vrrp.name = 'VRRP VLAN 30', vrrp.group_id = 30, vrrp.vlan_id = 30,
    vrrp.dataset = 'vexpertai-design-ontology'
MERGE (vrrpActive:FHRPActiveGateway {id: 'vrrp-vlan-30-active'})
SET vrrpActive.name = 'VRRP Master on dist-01',
    vrrpActive.dataset = 'vexpertai-design-ontology'
MERGE (glbp:FirstHopRedundancyGroup:GLBPGroup {id: 'glbp-vlan-40'})
SET glbp.name = 'GLBP VLAN 40', glbp.group_id = 40,
    glbp.dataset = 'vexpertai-design-ontology'
MERGE (avg:ActiveVirtualGateway {id: 'glbp-vlan-40-avg'})
SET avg.name = 'GLBP AVG on dist-01', avg.dataset = 'vexpertai-design-ontology'
MERGE (avf:ActiveVirtualForwarder {id: 'glbp-vlan-40-avf'})
SET avf.name = 'GLBP AVF on dist-02', avf.dataset = 'vexpertai-design-ontology'
WITH vrrp, vrrpActive, glbp, avg, avf
MATCH (vlan30:VLAN {id: 'l2-vlan-30'}),
      (dist1:Switch {id: 'l2-dist-01'}), (dist2:Switch {id: 'l2-dist-02'})
MERGE (vlan30)-[:USES_FHRP]->(vrrp)
MERGE (vrrp)-[:HAS_ACTIVE_GATEWAY]->(vrrpActive)
MERGE (vrrpActive)-[:ROLE_ON]->(dist1)
MERGE (glbp)-[:HAS_AVG]->(avg)
MERGE (glbp)-[:HAS_AVF]->(avf)
MERGE (avg)-[:ROLE_ON]->(dist1)
MERGE (avf)-[:ROLE_ON]->(dist2);

// Scenario 4: original comparison of access design options.
MERGE (looped:DesignOption:LoopedL2Design {id: 'design-looped-l2-access'})
SET looped.name = 'Looped Layer 2 Access', looped.suitability_score = 55,
    looped.best_for = 'Legacy Layer 2 adjacency with physical path redundancy',
    looped.failure_domain = 'VLAN and STP domain',
    looped.operational_complexity = 'high', looped.stp_dependency = 'high',
    looped.rationale = 'Provides redundant links but relies on blocked paths and careful root placement.',
    looped.dataset = 'vexpertai-design-ontology'
MERGE (loopFree:DesignOption:LoopFreeL2Design {id: 'design-loop-free-l2-access'})
SET loopFree.name = 'Loop-Free Layer 2 Access', loopFree.suitability_score = 78,
    loopFree.best_for = 'Dual-homed access with multichassis aggregation',
    loopFree.failure_domain = 'Bridge domain with active-active uplinks',
    loopFree.operational_complexity = 'medium', loopFree.stp_dependency = 'fallback',
    loopFree.rationale = 'Uses one logical forwarding topology while retaining Layer 2 service behavior.',
    loopFree.dataset = 'vexpertai-design-ontology'
MERGE (routed:DesignOption:RoutedAccessDesign {id: 'design-routed-access'})
SET routed.name = 'Routed Access', routed.suitability_score = 92,
    routed.best_for = 'New deployments prioritizing fault isolation and deterministic convergence',
    routed.failure_domain = 'Access switch or routed link',
    routed.operational_complexity = 'medium', routed.stp_dependency = 'none across uplinks',
    routed.rationale = 'Removes campus-wide Layer 2 loops but may constrain endpoint VLAN extension.',
    routed.dataset = 'vexpertai-design-ontology'
MERGE (loopedTradeoff:Tradeoff {id: 'tradeoff-looped-l2'})
SET loopedTradeoff.name = 'Link redundancy versus STP complexity',
    loopedTradeoff.benefit = 'Physical redundant paths',
    loopedTradeoff.cost = 'Blocked capacity and larger failure scope',
    loopedTradeoff.dataset = 'vexpertai-design-ontology'
MERGE (loopFreeTradeoff:Tradeoff {id: 'tradeoff-loop-free-l2'})
SET loopFreeTradeoff.name = 'Active uplinks versus MLAG coupling',
    loopFreeTradeoff.benefit = 'Uses both uplinks without an intentional STP block',
    loopFreeTradeoff.cost = 'Multichassis control-plane dependency',
    loopFreeTradeoff.dataset = 'vexpertai-design-ontology'
MERGE (routedTradeoff:Tradeoff {id: 'tradeoff-routed-access'})
SET routedTradeoff.name = 'Failure isolation versus Layer 2 extension',
    routedTradeoff.benefit = 'Small failure domains and deterministic routing',
    routedTradeoff.cost = 'Less support for VLAN extension across access switches',
    routedTradeoff.dataset = 'vexpertai-design-ontology'
MERGE (risk:Layer2Risk {id: 'risk-looped-l2-control-plane'})
SET risk.name = 'STP event affects multiple access blocks',
    risk.severity = 'high', risk.likelihood = 'low',
    risk.dataset = 'vexpertai-design-ontology'
MERGE (looped)-[:HAS_TRADEOFF]->(loopedTradeoff)
MERGE (loopFree)-[:HAS_TRADEOFF]->(loopFreeTradeoff)
MERGE (routed)-[:HAS_TRADEOFF]->(routedTradeoff)
MERGE (looped)-[:EXPOSES_RISK]->(risk);
