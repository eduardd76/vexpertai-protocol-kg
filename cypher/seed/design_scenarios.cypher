// Merger integration design: controlled protocol boundary with explicit risks.
MERGE (domain:DesignDomain {id: 'design-merger-integration'})
SET domain.name = 'Merger Network Integration',
    domain.dataset = 'vexpertai-design-ontology'
MERGE (objective:DesignObjective {id: 'objective-merger-continuity'})
SET objective.name = 'Preserve critical service reachability during integration',
    objective.target = 'No unplanned route loss or route feedback',
    objective.dataset = 'vexpertai-design-ontology'
MERGE (constraint:DesignConstraint {id: 'constraint-overlapping-addresses'})
SET constraint.name = 'Overlapping address space cannot be immediately renumbered',
    constraint.dataset = 'vexpertai-design-ontology'
MERGE (failure:FailureDomain {id: 'failure-merger-routing-boundary'})
SET failure.name = 'Inter-company routing boundary',
    failure.scope = 'Shared services exchanged during migration',
    failure.dataset = 'vexpertai-design-ontology'
MERGE (domain)-[:HAS_OBJECTIVE]->(objective)
MERGE (domain)-[:HAS_CONSTRAINT]->(constraint)
MERGE (domain)-[:HAS_FAILURE_DOMAIN]->(failure);

MERGE (decision:DesignDecision {id: 'decision-controlled-bgp-boundary'})
SET decision.name = 'Use a controlled BGP policy boundary',
    decision.rationale = 'Preserve protocol autonomy and make exchanged routes explicit.',
    decision.status = 'proposed', decision.dataset = 'vexpertai-design-ontology'
MERGE (selected:DesignOption {id: 'option-bgp-policy-boundary'})
SET selected.name = 'BGP boundary with allowed-prefix and community policy',
    selected.dataset = 'vexpertai-design-ontology'
MERGE (rejected:DesignOption {id: 'option-mutual-redistribution'})
SET rejected.name = 'Mutual OSPF and EIGRP redistribution',
    rejected.dataset = 'vexpertai-design-ontology'
MERGE (tradeoff:Tradeoff {id: 'tradeoff-boundary-control'})
SET tradeoff.name = 'More policy operations for smaller failure scope',
    tradeoff.benefit = 'Explicit route ownership and controlled propagation',
    tradeoff.cost = 'Additional BGP policy and migration operations',
    tradeoff.dataset = 'vexpertai-design-ontology'
MERGE (risk:DesignRisk {id: 'risk-route-feedback'})
SET risk.name = 'Route feedback during protocol integration',
    risk.severity = 'critical', risk.likelihood = 'medium',
    risk.state = 'mitigated', risk.dataset = 'vexpertai-design-ontology'
WITH decision, selected, rejected, tradeoff, risk
MATCH (objective:DesignObjective {id: 'objective-merger-continuity'}),
      (constraint:DesignConstraint {id: 'constraint-overlapping-addresses'}),
      (failure:FailureDomain {id: 'failure-merger-routing-boundary'})
MERGE (decision)-[:SUPPORTS]->(objective)
MERGE (decision)-[:DEPENDS_ON]->(constraint)
MERGE (decision)-[:CONSIDERS]->(selected)
MERGE (decision)-[:CONSIDERS]->(rejected)
MERGE (decision)-[:SELECTS]->(selected)
MERGE (decision)-[:HAS_TRADEOFF]->(tradeoff)
MERGE (rejected)-[:INTRODUCES_RISK]->(risk)
MERGE (risk)-[:IMPACTS]->(failure);

MERGE (orgA:Organization {id: 'organization-north'})
SET orgA.name = 'North Company', orgA.dataset = 'vexpertai-design-ontology'
MERGE (orgB:Organization {id: 'organization-south'})
SET orgB.name = 'South Company', orgB.dataset = 'vexpertai-design-ontology'
MERGE (netA:NetworkDomain {id: 'network-north-ospf'})
SET netA.name = 'North OSPF Domain', netA.protocol = 'OSPF',
    netA.dataset = 'vexpertai-design-ontology'
MERGE (netB:NetworkDomain {id: 'network-south-eigrp'})
SET netB.name = 'South EIGRP Domain', netB.protocol = 'EIGRP',
    netB.dataset = 'vexpertai-design-ontology'
MERGE (overlap:AddressOverlap {id: 'overlap-10.50.0.0-16'})
SET overlap.name = 'Shared use of 10.50.0.0/16', overlap.cidr = '10.50.0.0/16',
    overlap.dataset = 'vexpertai-design-ontology'
MERGE (orgA)-[:OWNS_DOMAIN]->(netA)
MERGE (orgB)-[:OWNS_DOMAIN]->(netB)
MERGE (netA)-[:HAS_OVERLAP]->(overlap)
MERGE (netB)-[:HAS_OVERLAP]->(overlap);

MERGE (phase:IntegrationPhase {id: 'phase-shared-services'})
SET phase.name = 'Shared Services Interconnection',
    phase.exit_criteria = 'Allowed routes stable, no feedback, service probes pass',
    phase.dataset = 'vexpertai-design-ontology'
MERGE (rule:RedistributionRule {id: 'design-redist-shared-services'})
SET rule.name = 'Tagged shared-services exchange',
    rule.source_protocol = 'OSPF', rule.target_protocol = 'BGP',
    rule.dataset = 'vexpertai-design-ontology'
MERGE (check:ValidationCheck {id: 'check-no-route-feedback'})
SET check.name = 'Validate allowed prefixes and no route feedback',
    check.expected_result = 'Only approved prefixes cross the boundary and none return to their origin.',
    check.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'evidence-overlap-inventory'})
SET evidence.name = 'Address and routing-domain inventory',
    evidence.summary = 'The two domains overlap on 10.50.0.0/16 and use different IGPs.',
    evidence.source = 'cmdb://merger/address-inventory',
    evidence.dataset = 'vexpertai-design-ontology'
MERGE (recommendation:Recommendation {id: 'recommendation-stage-boundary'})
SET recommendation.name = 'Stage and validate the BGP boundary',
    recommendation.action = 'Exchange an allowlisted service prefix set with origin communities and rollback checks.',
    recommendation.dataset = 'vexpertai-design-ontology'
WITH phase, rule, check, evidence, recommendation
MATCH (decision:DesignDecision {id: 'decision-controlled-bgp-boundary'}),
      (risk:DesignRisk {id: 'risk-route-feedback'})
MERGE (phase)-[:USES_INTERIM_POLICY]->(rule)
MERGE (phase)-[:VALIDATED_BY]->(check)
MERGE (decision)-[:BASED_ON]->(evidence)
MERGE (decision)-[:VALIDATED_BY]->(check)
MERGE (risk)-[:MITIGATED_BY]->(check)
MERGE (risk)-[:VALIDATED_BY]->(check)
MERGE (recommendation)-[:BASED_ON]->(evidence);

// Enterprise design: transport, VPN, QoS, BGP policy, risk, and validation.
MERGE (domain:DesignDomain {id: 'design-global-enterprise'})
SET domain.name = 'Global Enterprise Connectivity',
    domain.dataset = 'vexpertai-design-ontology'
MERGE (objective:DesignObjective {id: 'objective-branch-payment-sla'})
SET objective.name = 'Meet branch Payment-App availability and latency targets',
    objective.target = '99.95 percent availability and validated priority treatment',
    objective.dataset = 'vexpertai-design-ontology'
MERGE (constraint:DesignConstraint {id: 'constraint-small-operations-team'})
SET constraint.name = 'Operations team supports a limited protocol and policy set',
    constraint.dataset = 'vexpertai-design-ontology'
MERGE (domain)-[:HAS_OBJECTIVE]->(objective)
MERGE (domain)-[:HAS_CONSTRAINT]->(constraint);

MERGE (decision:DesignDecision {id: 'decision-dual-wan-overlay'})
SET decision.name = 'Use dual WAN transports with a policy-controlled VPN',
    decision.rationale = 'Separate transport failure while preserving consistent segmentation and service policy.',
    decision.status = 'approved', decision.dataset = 'vexpertai-design-ontology'
MERGE (option:DesignOption {id: 'option-mpls-internet-dual-transport'})
SET option.name = 'MPLS plus internet transport',
    option.dataset = 'vexpertai-design-ontology'
MERGE (tradeoff:Tradeoff {id: 'tradeoff-dual-wan'})
SET tradeoff.name = 'Higher availability with more policy state',
    tradeoff.benefit = 'Transport diversity and controlled failover',
    tradeoff.cost = 'Additional routing, security, and observability complexity',
    tradeoff.dataset = 'vexpertai-design-ontology'
MERGE (risk:DesignRisk {id: 'risk-asymmetric-wan-policy'})
SET risk.name = 'Asymmetric failover bypasses intended service policy',
    risk.severity = 'high', risk.likelihood = 'medium',
    risk.state = 'open', risk.dataset = 'vexpertai-design-ontology'
WITH decision, option, tradeoff, risk
MATCH (objective:DesignObjective {id: 'objective-branch-payment-sla'}),
      (constraint:DesignConstraint {id: 'constraint-small-operations-team'})
MERGE (decision)-[:SUPPORTS]->(objective)
MERGE (decision)-[:DEPENDS_ON]->(constraint)
MERGE (decision)-[:CONSIDERS]->(option)
MERGE (decision)-[:SELECTS]->(option)
MERGE (decision)-[:HAS_TRADEOFF]->(tradeoff)
MERGE (decision)-[:INTRODUCES_RISK]->(risk);

MERGE (service:BusinessService {id: 'design-payment-service'})
SET service.name = 'Payment-App Branch Access', service.criticality = 'critical',
    service.dataset = 'vexpertai-design-ontology'
MERGE (mpls:WANTransport {id: 'wan-mpls-primary'})
SET mpls.name = 'Managed MPLS Primary', mpls.transport_type = 'MPLS',
    mpls.dataset = 'vexpertai-design-ontology'
MERGE (internet:WANTransport {id: 'wan-internet-secondary'})
SET internet.name = 'Encrypted Internet Secondary',
    internet.transport_type = 'Internet',
    internet.dataset = 'vexpertai-design-ontology'
MERGE (vpn:VPNService {id: 'vpn-enterprise-prod'})
SET vpn.name = 'Enterprise Production VPN', vpn.vpn_type = 'L3VPN',
    vpn.encryption_required = true, vpn.dataset = 'vexpertai-design-ontology'
MERGE (qos:QoSPolicy {id: 'qos-payment-priority'})
SET qos.name = 'Payment Transaction Priority',
    qos.scope = 'end-to-end', qos.dataset = 'vexpertai-design-ontology'
MERGE (bgpPolicy:BGPPolicy {id: 'bgp-policy-branch-allowlist'})
SET bgpPolicy.name = 'Branch Allowed Prefix Policy',
    bgpPolicy.direction = 'import-export',
    bgpPolicy.dataset = 'vexpertai-design-ontology'
MERGE (service)-[:USES_TRANSPORT]->(mpls)
MERGE (service)-[:USES_TRANSPORT]->(internet)
MERGE (service)-[:CONSUMES_VPN]->(vpn)
MERGE (service)-[:DEPENDS_ON]->(vpn)
MERGE (service)-[:DEPENDS_ON]->(qos)
MERGE (qos)-[:PROTECTS]->(service);

MERGE (check:ValidationCheck {id: 'check-dual-wan-policy'})
SET check.name = 'Validate failover path, segmentation, and QoS',
    check.expected_result = 'Payment-App remains reachable through either transport with VPN and QoS policy intact.',
    check.dataset = 'vexpertai-design-ontology'
MERGE (run:ValidationRun {id: 'validation-dual-wan'})
SET run.name = 'Dual WAN design validation', run.status = 'planned',
    run.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'evidence-branch-sla'})
SET evidence.name = 'Branch transaction SLA baseline',
    evidence.summary = 'Current single transport causes service-impacting outages and variable transaction latency.',
    evidence.source = 'slo://payment-app/branch-baseline',
    evidence.dataset = 'vexpertai-design-ontology'
WITH check, run, evidence
MATCH (decision:DesignDecision {id: 'decision-dual-wan-overlay'}),
      (risk:DesignRisk {id: 'risk-asymmetric-wan-policy'}),
      (service:BusinessService {id: 'design-payment-service'})
MERGE (decision)-[:BASED_ON]->(evidence)
MERGE (decision)-[:VALIDATED_BY]->(check)
MERGE (risk)-[:MITIGATED_BY]->(check)
MERGE (risk)-[:VALIDATED_BY]->(check)
MERGE (risk)-[:IMPACTS]->(service)
MERGE (run)-[:TESTS]->(check);
