// Shared business criticality, requirements, constraints, and network context.
MERGE (critical:BusinessCriticality {id: 'ch2-criticality-tier-1'})
SET critical.name = 'Tier 1 Revenue Service', critical.rank = 1,
    critical.dataset = 'vexpertai-design-ontology'
MERGE (continuity:Requirement:DesignRequirement:BusinessRequirement {id: 'ch2-req-merger-continuity'})
SET continuity.name = 'Preserve customer service during merger',
    continuity.priority = 'critical',
    continuity.acceptance_criteria = 'No unplanned outage during routing integration',
    continuity.dataset = 'vexpertai-design-ontology'
MERGE (integration:Requirement:DesignRequirement:TechnicalRequirement {id: 'ch2-req-ospf-bgp-integration'})
SET integration.name = 'Exchange approved reachability between OSPF and BGP',
    integration.priority = 'high',
    integration.acceptance_criteria = 'Only approved prefixes cross the boundary',
    integration.dataset = 'vexpertai-design-ontology'
MERGE (simplicity:Requirement:DesignRequirement:OperationalRequirement {id: 'ch2-req-operational-simplicity'})
SET simplicity.name = 'Keep operational procedures supportable by the current team',
    simplicity.priority = 'high',
    simplicity.acceptance_criteria = 'On-call engineers can diagnose and roll back changes',
    simplicity.dataset = 'vexpertai-design-ontology'
MERGE (security:Requirement:DesignRequirement:SecurityRequirement {id: 'ch2-req-routing-policy-security'})
SET security.name = 'Prevent unintended route exchange',
    security.priority = 'critical',
    security.acceptance_criteria = 'Route policy defaults to deny and logs exceptions',
    security.dataset = 'vexpertai-design-ontology'
MERGE (skill:Constraint:SkillConstraint {id: 'ch2-constraint-bgp-skill'})
SET skill.name = 'Limited advanced BGP policy experience',
    skill.summary = 'Only two engineers currently support complex inter-domain policy',
    skill.dataset = 'vexpertai-design-ontology'
MERGE (cost:Constraint:CostConstraint {id: 'ch2-constraint-migration-budget'})
SET cost.name = 'Migration must use the current hardware estate',
    cost.dataset = 'vexpertai-design-ontology'
MERGE (hardware:Constraint:HardwareConstraint {id: 'ch2-constraint-legacy-tcam'})
SET hardware.name = 'Legacy edge TCAM limits route scale',
    hardware.dataset = 'vexpertai-design-ontology'
MERGE (brownfield:BrownfieldNetwork {id: 'ch2-network-brownfield'})
SET brownfield.name = 'Combined Production Brownfield',
    brownfield.dataset = 'vexpertai-design-ontology'
MERGE (greenfield:GreenfieldNetwork {id: 'ch2-network-greenfield'})
SET greenfield.name = 'New Regional Greenfield',
    greenfield.dataset = 'vexpertai-design-ontology'
MERGE (continuity)-[:PRIORITIZED_BY]->(critical)
MERGE (integration)-[:PRIORITIZED_BY]->(critical)
MERGE (simplicity)-[:PRIORITIZED_BY]->(critical)
MERGE (security)-[:PRIORITIZED_BY]->(critical);

// Scenario 1: merger routing integration option analysis.
MERGE (merger:MergerDesign {id: 'ch2-merger-design'})
SET merger.name = 'North-South Company Routing Merger',
    merger.dataset = 'vexpertai-design-ontology'
MERGE (routingPlan:RoutingIntegrationPlan {id: 'ch2-routing-integration-plan'})
SET routingPlan.name = 'Controlled OSPF and BGP Integration',
    routingPlan.policy = 'Allowlist prefixes and tag origin',
    routingPlan.dataset = 'vexpertai-design-ontology'
MERGE (ospf:ExistingProtocol {id: 'ch2-existing-ospf'})
SET ospf.name = 'Production OSPF', ospf.protocol = 'OSPF',
    ospf.dataset = 'vexpertai-design-ontology'
MERGE (bgp:ExistingProtocol {id: 'ch2-existing-bgp'})
SET bgp.name = 'Production BGP', bgp.protocol = 'BGP',
    bgp.dataset = 'vexpertai-design-ontology'
MERGE (ship:DesignOption {id: 'ch2-option-ship-in-night'})
SET ship.name = 'Ship-in-the-Night Routing Domains', ship.status = 'selected',
    ship.chapter = '02',
    ship.summary = 'Keep IGP domains separate and exchange approved routes through BGP policy.',
    ship.dataset = 'vexpertai-design-ontology'
MERGE (redistribution:DesignOption {id: 'ch2-option-mutual-redistribution'})
SET redistribution.name = 'Mutual OSPF-BGP Redistribution', redistribution.status = 'rejected',
    redistribution.chapter = '02',
    redistribution.summary = 'Redistribute selected routes in both directions during integration.',
    redistribution.dataset = 'vexpertai-design-ontology'
MERGE (shipTradeoff:Tradeoff {id: 'ch2-tradeoff-ship-in-night'})
SET shipTradeoff.name = 'Isolation versus staged operations',
    shipTradeoff.benefit = 'Small failure scope and explicit route ownership',
    shipTradeoff.cost = 'More policy boundaries and phased migration work',
    shipTradeoff.dataset = 'vexpertai-design-ontology'
MERGE (redistTradeoff:Tradeoff {id: 'ch2-tradeoff-redistribution'})
SET redistTradeoff.name = 'Rapid reachability versus feedback risk',
    redistTradeoff.benefit = 'Faster initial cross-domain reachability',
    redistTradeoff.cost = 'Route feedback, metric translation, and harder troubleshooting',
    redistTradeoff.dataset = 'vexpertai-design-ontology'
WITH merger, routingPlan, ospf, bgp, ship, redistribution, shipTradeoff, redistTradeoff
MATCH (continuity:Requirement {id: 'ch2-req-merger-continuity'}),
      (integration:Requirement {id: 'ch2-req-ospf-bgp-integration'}),
      (simplicity:Requirement {id: 'ch2-req-operational-simplicity'}),
      (security:Requirement {id: 'ch2-req-routing-policy-security'}),
      (skill:SkillConstraint {id: 'ch2-constraint-bgp-skill'}),
      (brownfield:BrownfieldNetwork {id: 'ch2-network-brownfield'})
MERGE (merger)-[:REQUIRES]->(routingPlan)
MERGE (merger)-[:APPLIES_TO_NETWORK]->(brownfield)
MERGE (routingPlan)-[:INTEGRATES]->(ospf)
MERGE (routingPlan)-[:INTEGRATES]->(bgp)
MERGE (ship)-[:SATISFIES]->(continuity)
MERGE (ship)-[:SATISFIES]->(simplicity)
MERGE (ship)-[:SATISFIES]->(security)
MERGE (ship)-[:HAS_TRADEOFF]->(shipTradeoff)
MERGE (redistribution)-[:SATISFIES]->(continuity)
MERGE (redistribution)-[:SATISFIES]->(integration)
MERGE (redistribution)-[:VIOLATES]->(skill)
MERGE (redistribution)-[:HAS_TRADEOFF]->(redistTradeoff);

MERGE (shipRisk:Risk {id: 'ch2-risk-boundary-cutover'})
SET shipRisk.name = 'Boundary cutover coordination error',
    shipRisk.severity = 'medium', shipRisk.likelihood = 'low',
    shipRisk.state = 'mitigated', shipRisk.dataset = 'vexpertai-design-ontology'
MERGE (redistRisk:Risk {id: 'ch2-risk-route-feedback'})
SET redistRisk.name = 'Route feedback across mutual redistribution',
    redistRisk.severity = 'critical', redistRisk.likelihood = 'medium',
    redistRisk.state = 'open', redistRisk.dataset = 'vexpertai-design-ontology'
MERGE (metricRisk:Risk {id: 'ch2-risk-metric-translation'})
SET metricRisk.name = 'Protocol metric translation causes path inversion',
    metricRisk.severity = 'high', metricRisk.likelihood = 'medium',
    metricRisk.state = 'open', metricRisk.dataset = 'vexpertai-design-ontology'
MERGE (control:Control {id: 'ch2-control-boundary-validation'})
SET control.name = 'Prefix allowlist, origin community, and rollback validation',
    control.owner = 'Network Architecture',
    control.dataset = 'vexpertai-design-ontology'
MERGE (decision:DesignDecision {id: 'ch2-decision-merger-routing'})
SET decision.name = 'Select ship-in-the-night routing integration',
    decision.rationale = 'It satisfies continuity, security, and operability with a smaller failure scope.',
    decision.status = 'approved', decision.dataset = 'vexpertai-design-ontology'
WITH shipRisk, redistRisk, metricRisk, control, decision
MATCH (ship:DesignOption {id: 'ch2-option-ship-in-night'}),
      (redistribution:DesignOption {id: 'ch2-option-mutual-redistribution'})
MERGE (decision)-[:CHOOSES]->(ship)
MERGE (decision)-[:CREATES_RISK]->(shipRisk)
MERGE (ship)-[:HAS_RISK]->(shipRisk)
MERGE (redistribution)-[:HAS_RISK]->(redistRisk)
MERGE (redistribution)-[:HAS_RISK]->(metricRisk)
MERGE (shipRisk)-[:MITIGATED_BY]->(control);

MERGE (assumptionValidated:Assumption {id: 'ch2-assumption-bgp-capability'})
SET assumptionValidated.name = 'Existing edges support required BGP policy',
    assumptionValidated.status = 'validated', assumptionValidated.owner = 'Platform Engineering',
    assumptionValidated.dataset = 'vexpertai-design-ontology'
MERGE (check:ValidationCheck {id: 'ch2-check-bgp-capability'})
SET check.name = 'Validate edge policy and scale capability',
    check.expected_result = 'Platforms support required policy and route scale.',
    check.dataset = 'vexpertai-design-ontology'
MERGE (assumptionUnvalidated:Assumption {id: 'ch2-assumption-route-ownership'})
SET assumptionUnvalidated.name = 'Every overlapping prefix has a known owner',
    assumptionUnvalidated.status = 'unvalidated', assumptionUnvalidated.owner = 'Merger PMO',
    assumptionUnvalidated.dataset = 'vexpertai-design-ontology'
WITH assumptionValidated, check, assumptionUnvalidated
MATCH (ship:DesignOption {id: 'ch2-option-ship-in-night'}),
      (redistribution:DesignOption {id: 'ch2-option-mutual-redistribution'})
MERGE (assumptionValidated)-[:VALIDATED_BY]->(check)
MERGE (ship)-[:BASED_ON_ASSUMPTION]->(assumptionValidated)
MERGE (redistribution)-[:BASED_ON_ASSUMPTION]->(assumptionUnvalidated);

// Scenario 2: protocol replacement with coexistence and ordered migration.
MERGE (replacement:TechnologyReplacement {id: 'ch2-replace-eigrp-with-ospf'})
SET replacement.name = 'Replace EIGRP with OSPF',
    replacement.dataset = 'vexpertai-design-ontology'
MERGE (eigrp:ExistingProtocol {id: 'ch2-existing-eigrp'})
SET eigrp.name = 'Legacy EIGRP', eigrp.protocol = 'EIGRP',
    eigrp.dataset = 'vexpertai-design-ontology'
MERGE (coexist:CoexistencePlan {id: 'ch2-coexist-eigrp-ospf'})
SET coexist.name = 'EIGRP and OSPF Controlled Coexistence',
    coexist.exit_criteria = 'All sites use OSPF and redistribution is removed',
    coexist.dataset = 'vexpertai-design-ontology'
MERGE (migration:MigrationPlan {id: 'ch2-migration-eigrp-ospf'})
SET migration.name = 'EIGRP to OSPF Migration',
    migration.status = 'planned', migration.dataset = 'vexpertai-design-ontology'
MERGE (rollback:RollbackPlan {id: 'ch2-rollback-eigrp-ospf'})
SET rollback.name = 'Restore EIGRP adjacency and remove OSPF preference',
    rollback.tested = true, rollback.dataset = 'vexpertai-design-ontology'
WITH replacement, eigrp, coexist, migration, rollback
MATCH (brownfield:BrownfieldNetwork {id: 'ch2-network-brownfield'})
MERGE (replacement)-[:REPLACES]->(eigrp)
MERGE (replacement)-[:REQUIRES]->(coexist)
MERGE (replacement)-[:APPLIES_TO_NETWORK]->(brownfield)
MERGE (migration)-[:HAS_ROLLBACK]->(rollback);

MERGE (inventory:MigrationStep {id: 'ch2-step-inventory'})
SET inventory.name = 'Validate topology and route ownership', inventory.sequence = 1,
    inventory.status = 'validated', inventory.dataset = 'vexpertai-design-ontology'
MERGE (enable:MigrationStep {id: 'ch2-step-enable-ospf'})
SET enable.name = 'Enable OSPF without changing preference', enable.sequence = 2,
    enable.status = 'validated', enable.dataset = 'vexpertai-design-ontology'
MERGE (redist:MigrationStep {id: 'ch2-step-controlled-redist'})
SET redist.name = 'Enable temporary controlled redistribution', redist.sequence = 3,
    redist.status = 'planned', redist.dataset = 'vexpertai-design-ontology'
MERGE (cutover:MigrationStep {id: 'ch2-step-cutover'})
SET cutover.name = 'Prefer OSPF and validate services', cutover.sequence = 4,
    cutover.status = 'planned', cutover.dataset = 'vexpertai-design-ontology'
MERGE (remove:MigrationStep {id: 'ch2-step-remove-eigrp'})
SET remove.name = 'Remove EIGRP configuration', remove.sequence = 5,
    remove.status = 'planned', remove.dataset = 'vexpertai-design-ontology'
WITH inventory, enable, redist, cutover, remove
MATCH (migration:MigrationPlan {id: 'ch2-migration-eigrp-ospf'}),
      (rollback:RollbackPlan {id: 'ch2-rollback-eigrp-ospf'})
MERGE (migration)-[:HAS_STEP]->(inventory)
MERGE (migration)-[:HAS_STEP]->(enable)
MERGE (migration)-[:HAS_STEP]->(redist)
MERGE (migration)-[:HAS_STEP]->(cutover)
MERGE (migration)-[:HAS_STEP]->(remove)
MERGE (enable)-[:DEPENDS_ON]->(inventory)
MERGE (redist)-[:DEPENDS_ON]->(enable)
MERGE (cutover)-[:DEPENDS_ON]->(redist)
MERGE (remove)-[:DEPENDS_ON]->(cutover)
MERGE (enable)-[:HAS_ROLLBACK]->(rollback)
MERGE (redist)-[:HAS_ROLLBACK]->(rollback)
MERGE (cutover)-[:HAS_ROLLBACK]->(rollback);

// Scenario 3: scalability conflicts with operational simplicity.
MERGE (scale:Requirement:DesignRequirement:ScalabilityRequirement {id: 'ch2-req-scale-500-sites'})
SET scale.name = 'Scale to 500 sites without full-mesh state',
    scale.priority = 'high', scale.acceptance_criteria = 'Control-plane state grows sublinearly by region',
    scale.dataset = 'vexpertai-design-ontology'
MERGE (hierarchy:DesignOption {id: 'ch2-option-routing-hierarchy'})
SET hierarchy.name = 'Introduce regional routing hierarchy', hierarchy.status = 'selected',
    hierarchy.chapter = '02', hierarchy.dataset = 'vexpertai-design-ontology'
MERGE (flat:DesignOption {id: 'ch2-option-flat-routing'})
SET flat.name = 'Retain flat routing domain', flat.status = 'rejected',
    flat.chapter = '02', flat.dataset = 'vexpertai-design-ontology'
MERGE (complexity:OperationalComplexity {id: 'ch2-complexity-hierarchy'})
SET complexity.name = 'Regional hierarchy operational burden', complexity.score = 65,
    complexity.drivers = ['summarization', 'area boundaries', 'policy ownership'],
    complexity.dataset = 'vexpertai-design-ontology'
MERGE (tradeoff:Tradeoff {id: 'ch2-tradeoff-scale-simplicity'})
SET tradeoff.name = 'Scale versus operational simplicity',
    tradeoff.benefit = 'Contains routing state and failures by region',
    tradeoff.cost = 'Requires hierarchy skills and summary policy ownership',
    tradeoff.dataset = 'vexpertai-design-ontology'
WITH scale, hierarchy, flat, complexity, tradeoff
MATCH (simplicity:Requirement {id: 'ch2-req-operational-simplicity'}),
      (skill:SkillConstraint {id: 'ch2-constraint-bgp-skill'}),
      (hardware:HardwareConstraint {id: 'ch2-constraint-legacy-tcam'}),
      (criticality:BusinessCriticality {id: 'ch2-criticality-tier-1'})
MERGE (scale)-[:PRIORITIZED_BY]->(criticality)
MERGE (hierarchy)-[:SATISFIES]->(scale)
MERGE (hierarchy)-[:VIOLATES]->(skill)
MERGE (hierarchy)-[:INCREASES]->(complexity)
MERGE (hierarchy)-[:HAS_TRADEOFF]->(tradeoff)
MERGE (flat)-[:SATISFIES]->(simplicity)
MERGE (flat)-[:VIOLATES]->(hardware);

// Scenario 4: fast convergence adds BFD behavior and monitoring complexity.
MERGE (convergence:Requirement:DesignRequirement:ConvergenceRequirement {id: 'ch2-req-fast-convergence'})
SET convergence.name = 'Detect and recover from WAN failure within one second',
    convergence.priority = 'critical',
    convergence.acceptance_criteria = 'Traffic restores within 1000 ms without instability',
    convergence.dataset = 'vexpertai-design-ontology'
MERGE (monitoring:Requirement:DesignRequirement:MonitoringRequirement {id: 'ch2-monitor-bfd'})
SET monitoring.name = 'Monitor BFD session health and flap rate',
    monitoring.priority = 'high',
    monitoring.acceptance_criteria = 'Alert on session loss and abnormal flap frequency',
    monitoring.signal = 'BFD state and transition rate',
    monitoring.dataset = 'vexpertai-design-ontology'
MERGE (feature:ProtocolFeature {id: 'ch2-feature-bfd'})
SET feature.name = 'Bidirectional Forwarding Detection',
    feature.dataset = 'vexpertai-design-ontology'
MERGE (addition:TechnologyAddition {id: 'ch2-add-bfd-to-ospf'})
SET addition.name = 'Add BFD to OSPF WAN Adjacencies',
    addition.dataset = 'vexpertai-design-ontology'
MERGE (complexity:OperationalComplexity {id: 'ch2-complexity-bfd'})
SET complexity.name = 'BFD tuning and alerting complexity', complexity.score = 72,
    complexity.drivers = ['timer coordination', 'platform scale', 'flap triage'],
    complexity.dataset = 'vexpertai-design-ontology'
MERGE (option:DesignOption {id: 'ch2-option-bfd-convergence'})
SET option.name = 'Use BFD for subsecond failure detection', option.status = 'selected',
    option.chapter = '02', option.dataset = 'vexpertai-design-ontology'
MERGE (tradeoff:Tradeoff {id: 'ch2-tradeoff-bfd'})
SET tradeoff.name = 'Fast detection versus sensitivity and state',
    tradeoff.benefit = 'Subsecond failure detection independent of routing timers',
    tradeoff.cost = 'More sessions, tuning, monitoring, and false-positive risk',
    tradeoff.dataset = 'vexpertai-design-ontology'
WITH convergence, monitoring, feature, addition, complexity, option, tradeoff
MATCH (ospf:ExistingProtocol {id: 'ch2-existing-ospf'}),
      (criticality:BusinessCriticality {id: 'ch2-criticality-tier-1'}),
      (brownfield:BrownfieldNetwork {id: 'ch2-network-brownfield'})
MERGE (convergence)-[:PRIORITIZED_BY]->(criticality)
MERGE (monitoring)-[:PRIORITIZED_BY]->(criticality)
MERGE (monitoring)-[:COVERS]->(feature)
MERGE (ospf)-[:HAS_FEATURE]->(feature)
MERGE (addition)-[:ADDS_FEATURE]->(feature)
MERGE (addition)-[:IMPACTS]->(ospf)
MERGE (addition)-[:INCREASES]->(complexity)
MERGE (addition)-[:APPLIES_TO_NETWORK]->(brownfield)
MERGE (option)-[:SATISFIES]->(convergence)
MERGE (option)-[:SATISFIES]->(monitoring)
MERGE (option)-[:INCREASES]->(complexity)
MERGE (option)-[:HAS_TRADEOFF]->(tradeoff);

MERGE (bfdRisk:Risk {id: 'ch2-risk-bfd-instability'})
SET bfdRisk.name = 'Aggressive BFD timers cause false failure detection',
    bfdRisk.severity = 'high', bfdRisk.likelihood = 'medium',
    bfdRisk.state = 'mitigated', bfdRisk.dataset = 'vexpertai-design-ontology'
MERGE (bfdControl:Control {id: 'ch2-control-bfd-scale-test'})
SET bfdControl.name = 'Platform-scale timer validation and flap-rate alert',
    bfdControl.owner = 'Network Reliability',
    bfdControl.dataset = 'vexpertai-design-ontology'
MERGE (decision:DesignDecision {id: 'ch2-decision-bfd'})
SET decision.name = 'Use validated BFD profiles on WAN links',
    decision.rationale = 'Meets convergence target when timer scale and alerting are validated.',
    decision.status = 'approved', decision.dataset = 'vexpertai-design-ontology'
WITH bfdRisk, bfdControl, decision
MATCH (option:DesignOption {id: 'ch2-option-bfd-convergence'})
MERGE (decision)-[:CHOOSES]->(option)
MERGE (decision)-[:CREATES_RISK]->(bfdRisk)
MERGE (option)-[:HAS_RISK]->(bfdRisk)
MERGE (bfdRisk)-[:MITIGATED_BY]->(bfdControl);

// Additional organizational design types are explicit even when not selected.
MERGE (divestment:DivestmentDesign {id: 'ch2-divestment-template'})
SET divestment.name = 'Service-Preserving Network Separation',
    divestment.dataset = 'vexpertai-design-ontology'
WITH divestment
MATCH (brownfield:BrownfieldNetwork {id: 'ch2-network-brownfield'})
MERGE (divestment)-[:APPLIES_TO_NETWORK]->(brownfield);
