// Apply canonical parent labels to chapter-specific instances.
MATCH (protocol)
WHERE protocol.dataset = 'vexpertai-design-ontology'
  AND (protocol:OSPFProcess OR protocol:ISISProcess
       OR protocol:EIGRPProcess OR protocol:BGPProcess)
SET protocol:Protocol:RoutingProtocolInstance;

MATCH (protocol)
WHERE protocol.dataset = 'vexpertai-design-ontology'
  AND (protocol:PIMProcess OR protocol:LDP OR protocol:RSVPTE
       OR protocol:IGMP OR protocol:MPBGP OR protocol:MPBGPVPNv4
       OR protocol:MPBGPVPNv6)
SET protocol:Protocol;

MATCH (policy)
WHERE policy.dataset = 'vexpertai-design-ontology'
  AND (policy:RouteMap OR policy:PrefixList OR policy:RoutePolicy
       OR policy:BGPPolicy OR policy:RedistributionPolicy
       OR policy:SummarizationPolicy OR policy:FirewallRule
       OR policy:QoSPolicy OR policy:MarkingPolicy OR policy:PolicingPolicy
       OR policy:ShapingPolicy OR policy:QueuingPolicy)
SET policy:Policy;

MATCH (security)
WHERE security.dataset = 'vexpertai-design-ontology' AND security:FirewallRule
SET security:SecurityPolicy;

MATCH (overlay)
WHERE overlay.dataset = 'vexpertai-design-ontology'
  AND (overlay:VPNService OR overlay:MPLSL3VPN OR overlay:MPLSL2VPN
       OR overlay:MPLSService OR overlay:VXLANOverlay OR overlay:DMVPN
       OR overlay:CarrierEthernetService OR overlay:SegmentRoutingPolicy
       OR overlay:ServiceOverlay)
SET overlay:OverlayService;

MATCH (risk)
WHERE risk.dataset = 'vexpertai-design-ontology'
  AND (risk:DesignRisk OR risk:Layer2Risk OR risk:OSPFAdjacencyRisk
       OR risk:ISISAdjacencyRisk OR risk:VPNRisk OR risk:BGPPathRisk
       OR risk:MulticastRisk OR risk:QoSRisk OR risk:OversubscriptionRisk
       OR risk:MPLSRisk)
SET risk:Risk,
    risk.state = coalesce(risk.state, 'open'),
    risk.likelihood = coalesce(risk.likelihood, 'unknown');

MATCH (requirement)
WHERE requirement.dataset = 'vexpertai-design-ontology'
  AND (requirement:DesignRequirement OR requirement:BusinessRequirement
       OR requirement:TechnicalRequirement OR requirement:HighAvailabilityRequirement
       OR requirement:ScalabilityRequirement OR requirement:ConvergenceRequirement
       OR requirement:SecurityRequirement OR requirement:OperationalRequirement
       OR requirement:MonitoringRequirement OR requirement:SLARequirement)
SET requirement:Requirement;

MATCH (constraint)
WHERE constraint.dataset = 'vexpertai-design-ontology'
  AND (constraint:DesignConstraint OR constraint:CostConstraint
       OR constraint:SkillConstraint OR constraint:HardwareConstraint)
SET constraint:Constraint;

MATCH (application)
WHERE application.dataset = 'vexpertai-design-ontology'
  AND (application:MulticastApplication OR application:ApplicationTraffic)
SET application:Application;

MATCH (route)
WHERE route.dataset = 'vexpertai-design-ontology'
  AND (route:BGPRoute OR route:VPNRoute OR route:MulticastRoute
       OR route:ExternalRoute OR route:SuccessorRoute OR route:SummaryRoute)
SET route:Route;

// Payment-App end-to-end physical, Layer 2, routing, overlay, policy, and service chain.
MERGE (site:Site:BranchSite {id: 'global-site-branch-01'})
SET site.name = 'Branch 01', site.dataset = 'vexpertai-design-ontology'
MERGE (users:UserGroup {id: 'global-users-branch-01'})
SET users.name = 'Branch Payment Users', users.user_count = 85,
    users.dataset = 'vexpertai-design-ontology'
MERGE (access:Interface:AccessPort {id: 'global-branch-sw1:Gi1/0/10'})
SET access.name = 'Branch User Access Port', access.status = 'up',
    access.simulated_status = 'failed', access.dataset = 'vexpertai-design-ontology'
MERGE (vlan:VLAN {id: 'global-vlan-110'})
SET vlan.name = 'Branch Users VLAN', vlan.vlan_id = 110,
    vlan.dataset = 'vexpertai-design-ontology'
MERGE (fhrp:FirstHopRedundancyGroup:HSRPGroup {id: 'global-hsrp-110'})
SET fhrp.name = 'Branch VLAN 110 HSRP', fhrp.group = 110,
    fhrp.dataset = 'vexpertai-design-ontology'
MERGE (gateway:DefaultGateway:FHRPActiveGateway {id: 'global-gateway-vlan-110'})
SET gateway.name = 'Branch VLAN 110 Default Gateway', gateway.address = '10.110.0.1',
    gateway.dataset = 'vexpertai-design-ontology'
MERGE (ospf:Protocol:RoutingProtocolInstance:OSPFProcess {id: 'global-ospf-110'})
SET ospf.name = 'Branch OSPF 110', ospf.process_id = 110,
    ospf.router_id = '10.255.110.1', ospf.state = 'up',
    ospf.dataset = 'vexpertai-design-ontology'
MERGE (bgp:Protocol:RoutingProtocolInstance:BGPProcess {id: 'global-bgp-65110'})
SET bgp.name = 'DC Edge BGP 65110', bgp.asn = 65110,
    bgp.router_id = '10.255.110.2', bgp.state = 'degraded',
    bgp.dataset = 'vexpertai-design-ontology'
MERGE (rule:RedistributionRule {id: 'global-redist-payment'})
SET rule.name = 'REDIST-OSPF-BGP-PAYMENT', rule.status = 'filtered',
    rule.dataset = 'vexpertai-design-ontology'
MERGE (routeMap:Policy:RouteMap {id: 'global-rm-payment'})
SET routeMap.name = 'RM-OSPF-TO-BGP-PAYMENT', routeMap.action = 'permit-list',
    routeMap.dataset = 'vexpertai-design-ontology'
MERGE (prefixList:Policy:PrefixList {id: 'global-pl-payment'})
SET prefixList.name = 'PL-PAYMENT-APP', prefixList.action = 'deny',
    prefixList.previous_action = 'permit', prefixList.dataset = 'vexpertai-design-ontology'
MERGE (prefix:Prefix {id: 'global-prefix-payment-app'})
SET prefix.name = 'Payment-App Prefix', prefix.cidr = '10.50.10.0/24',
    prefix.current_state = 'withdrawn', prefix.dataset = 'vexpertai-design-ontology'
MERGE (mpls:OverlayService:MPLSService:MPLSL3VPN {id: 'global-mpls-payment'})
SET mpls.name = 'Payment Production MPLS VPN', mpls.service_type = 'MPLS L3VPN',
    mpls.status = 'control_plane_failed', mpls.dataset = 'vexpertai-design-ontology'
MERGE (firewall:Policy:SecurityPolicy:FirewallRule {id: 'global-fw-payment'})
SET firewall.name = 'Allow Branch to Payment-App', firewall.action = 'permit',
    firewall.status = 'configured', firewall.dataset = 'vexpertai-design-ontology'
MERGE (qos:Policy:QoSPolicy {id: 'global-qos-payment'})
SET qos.name = 'Payment Critical Data QoS', qos.status = 'applied',
    qos.dataset = 'vexpertai-design-ontology'
MERGE (qosClass:QoSClass:TrafficClass:CriticalDataTraffic {id: 'global-qos-class-payment'})
SET qosClass.name = 'PAYMENT-CRITICAL', qosClass.treatment = 'AF31 guaranteed bandwidth',
    qosClass.dataset = 'vexpertai-design-ontology'
MERGE (application:Application {id: 'global-application-payment'})
SET application.name = 'Payment-App', application.status = 'unreachable_from_branch',
    application.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'global-business-payment'})
SET service.name = 'Payment-App Branch Service', service.criticality = 'critical',
    service.status = 'impacted', service.dataset = 'vexpertai-design-ontology'
MERGE (sla:Requirement:SLARequirement:LatencyRequirement {id: 'global-sla-payment'})
SET sla.name = 'Payment Transaction SLA', sla.metric = 'latency',
    sla.threshold = '<=200ms and 99.95% availability',
    sla.priority = 'critical',
    sla.acceptance_criteria = 'Branch transaction probes pass through primary and recovery paths.',
    sla.dataset = 'vexpertai-design-ontology'
MERGE (owner:ServiceOwner {id: 'global-owner-payment-platform'})
SET owner.name = 'Payment Platform Operations', owner.team = 'Payments SRE',
    owner.contact = 'payments-sre@example.invalid',
    owner.dataset = 'vexpertai-design-ontology'
MERGE (users)-[:LOCATED_IN]->(site)
MERGE (users)-[:USES_ACCESS_INTERFACE]->(access)
MERGE (access)-[:BELONGS_TO]->(vlan)
MERGE (vlan)-[:USES_FHRP]->(fhrp)
MERGE (fhrp)-[:PROVIDES]->(gateway)
MERGE (access)-[:SUPPORTS_LAYER]->(vlan)
MERGE (vlan)-[:SUPPORTS_LAYER]->(gateway)
MERGE (gateway)-[:SUPPORTS_LAYER]->(ospf)
MERGE (ospf)-[:REDISTRIBUTES_TO]->(bgp)
MERGE (ospf)-[:SUPPORTS_LAYER]->(bgp)
MERGE (rule)-[:HAS_SOURCE_PROTOCOL]->(ospf)
MERGE (rule)-[:HAS_TARGET_PROTOCOL]->(bgp)
MERGE (rule)-[:CONTROLLED_BY]->(routeMap)
MERGE (rule)-[:APPLIES_TO_PREFIX]->(prefix)
MERGE (routeMap)-[:REFERENCES]->(prefixList)
MERGE (routeMap)-[:APPLIES_TO_PREFIX]->(prefix)
MERGE (prefixList)-[:CONTROLS_PREFIX]->(prefix)
MERGE (prefixList)-[:APPLIES_TO_PREFIX]->(prefix)
MERGE (bgp)-[:SUPPORTS_LAYER]->(mpls)
MERGE (mpls)-[:SUPPORTS_LAYER]->(firewall)
MERGE (firewall)-[:SUPPORTS_LAYER]->(qos)
MERGE (qos)-[:SUPPORTS_LAYER]->(qosClass)
MERGE (qosClass)-[:SUPPORTS_LAYER]->(application)
MERGE (prefix)-[:SUPPORTS_LAYER]->(application)
MERGE (application)-[:SUPPORTS_LAYER]->(service)
MERGE (service)-[:DEPENDS_ON]->(application)
MERGE (service)-[:DEPENDS_ON]->(mpls)
MERGE (service)-[:DEPENDS_ON]->(sla)
MERGE (service)-[:HAS_SLA]->(sla)
MERGE (service)-[:OWNED_BY]->(owner)
MERGE (application)-[:OWNED_BY]->(owner)
MERGE (sla)-[:OWNED_BY]->(owner);

// Reified dependency patterns distinguish control-plane failure from healthy forwarding.
MERGE (controlDependency:ControlPlaneDependency {id: 'global-cpdep-payment-redist'})
SET controlDependency.name = 'Payment Route Redistribution Control Plane',
    controlDependency.status = 'failed',
    controlDependency.failure_reason = 'prefix-list denies 10.50.10.0/24',
    controlDependency.dataset = 'vexpertai-design-ontology'
MERGE (dataDependency:DataPlaneDependency {id: 'global-dpdep-payment-mpls'})
SET dataDependency.name = 'Payment MPLS Forwarding Path',
    dataDependency.status = 'healthy_without_route',
    dataDependency.dataset = 'vexpertai-design-ontology'
WITH controlDependency, dataDependency
MATCH (mpls:OverlayService {id: 'global-mpls-payment'}),
      (bgp:BGPProcess {id: 'global-bgp-65110'}),
      (rule:RedistributionRule {id: 'global-redist-payment'}),
      (routeMap:RouteMap {id: 'global-rm-payment'}),
      (prefixList:PrefixList {id: 'global-pl-payment'}),
      (access:Interface {id: 'global-branch-sw1:Gi1/0/10'})
MERGE (mpls)-[:HAS_CONTROL_PLANE_DEPENDENCY]->(controlDependency)
MERGE (mpls)-[:HAS_DATA_PLANE_DEPENDENCY]->(dataDependency)
MERGE (controlDependency)-[:DEPENDS_ON_COMPONENT]->(bgp)
MERGE (controlDependency)-[:DEPENDS_ON_COMPONENT]->(rule)
MERGE (controlDependency)-[:DEPENDS_ON_COMPONENT]->(routeMap)
MERGE (controlDependency)-[:DEPENDS_ON_COMPONENT]->(prefixList)
MERGE (dataDependency)-[:DEPENDS_ON_COMPONENT]->(access);

// Change, evidence, risk, recommendation, and validation chain.
MERGE (change:Change {id: 'global-change-pl-payment'})
SET change.name = 'Restrict Payment-App Prefix List',
    change.timestamp = '2026-07-05T15:00:00Z',
    change.summary = 'PL-PAYMENT-APP changed 10.50.10.0/24 from permit to deny.',
    change.dataset = 'vexpertai-design-ontology'
MERGE (risk:Risk {id: 'global-risk-payment-route-loss'})
SET risk.name = 'Payment-App route withdrawal', risk.severity = 'critical',
    risk.likelihood = 'high', risk.state = 'active',
    risk.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'global-evidence-payment-change'})
SET evidence.name = 'Payment prefix policy correlation',
    evidence.summary = 'The prefix disappeared from BGP immediately after PL-PAYMENT-APP changed to deny.',
    evidence.source = 'change://global-change-pl-payment and route-summary://10.50.10.0/24',
    evidence.dataset = 'vexpertai-design-ontology'
MERGE (recommendation:Recommendation {id: 'global-recommendation-payment'})
SET recommendation.name = 'Restore and validate Payment-App prefix advertisement',
    recommendation.action = 'Validate the intended prefix, stage permit restoration, confirm OSPF-to-BGP propagation, run branch transaction probes, and retain rollback.',
    recommendation.risk = 'Do not broadly permit unrelated prefixes.',
    recommendation.dataset = 'vexpertai-design-ontology'
MERGE (validation:ValidationRun {id: 'global-validation-payment'})
SET validation.name = 'Payment-App safe restoration validation',
    validation.status = 'planned',
    validation.pre_checks = ['prefix-list diff', 'expected OSPF route', 'MPLS forwarding state'],
    validation.post_checks = ['BGP advertisement', 'branch application probe', 'SLA probe'],
    validation.dataset = 'vexpertai-design-ontology'
WITH change, risk, evidence, recommendation, validation
MATCH (prefixList:PrefixList {id: 'global-pl-payment'}),
      (prefix:Prefix {id: 'global-prefix-payment-app'}),
      (application:Application {id: 'global-application-payment'}),
      (service:BusinessService {id: 'global-business-payment'}),
      (dependency:ControlPlaneDependency {id: 'global-cpdep-payment-redist'}),
      (owner:ServiceOwner {id: 'global-owner-payment-platform'})
MERGE (change)-[:MODIFIES]->(prefixList)
MERGE (change)-[:AFFECTS]->(prefix)
MERGE (change)-[:AFFECTS]->(application)
MERGE (change)-[:AFFECTS]->(service)
MERGE (change)-[:INTRODUCES_RISK]->(risk)
MERGE (risk)-[:IMPACTS]->(service)
MERGE (risk)-[:MITIGATED_BY]->(recommendation)
MERGE (risk)-[:VALIDATED_BY]->(validation)
MERGE (risk)-[:OWNED_BY]->(owner)
MERGE (evidence)-[:EVIDENCES]->(change)
MERGE (evidence)-[:EVIDENCES]->(prefixList)
MERGE (evidence)-[:EVIDENCES]->(prefix)
MERGE (evidence)-[:EVIDENCES]->(dependency)
MERGE (recommendation)-[:BASED_ON]->(evidence)
MERGE (recommendation)-[:VALIDATED_BY]->(validation)
MERGE (validation)-[:TESTS]->(recommendation);

// Requirement-to-option traceability for the end-to-end design.
MERGE (requirement:Requirement:DesignRequirement {id: 'global-requirement-payment-connectivity'})
SET requirement.name = 'Resilient Branch Payment Connectivity',
    requirement.priority = 'critical',
    requirement.acceptance_criteria = 'Payment-App remains policy-compliant and meets SLA after a single transport or control-plane failure.',
    requirement.dataset = 'vexpertai-design-ontology'
MERGE (valid:DesignOption {id: 'global-option-mpls-policy-chain'})
SET valid.name = 'MPLS L3VPN with explicit route, firewall, and QoS policy',
    valid.status = 'valid', valid.dataset = 'vexpertai-design-ontology'
MERGE (invalid:DesignOption {id: 'global-option-flat-l2-extension'})
SET invalid.name = 'Flat Layer 2 extension to the data center',
    invalid.status = 'rejected', invalid.dataset = 'vexpertai-design-ontology'
MERGE (constraint:Constraint {id: 'global-constraint-no-campus-stretch'})
SET constraint.name = 'Do not extend branch broadcast domains into the data center',
    constraint.dataset = 'vexpertai-design-ontology'
MERGE (decision:DesignDecision {id: 'global-decision-payment-connectivity'})
SET decision.name = 'Select policy-controlled MPLS L3VPN',
    decision.rationale = 'Provides routed failure isolation and explicit route, security, and QoS policy.',
    decision.status = 'approved', decision.dataset = 'vexpertai-design-ontology'
WITH requirement, valid, invalid, constraint, decision
MATCH (owner:ServiceOwner {id: 'global-owner-payment-platform'})
MERGE (valid)-[:SATISFIES]->(requirement)
MERGE (invalid)-[:SATISFIES]->(requirement)
MERGE (invalid)-[:VIOLATES]->(constraint)
MERGE (decision)-[:CONSIDERS]->(valid)
MERGE (decision)-[:CONSIDERS]->(invalid)
MERGE (decision)-[:SELECTS]->(valid)
MERGE (requirement)-[:OWNED_BY]->(owner);
