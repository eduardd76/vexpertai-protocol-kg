// Decisions, selected options, and objectives.
MATCH (domain:DesignDomain)-[:HAS_OBJECTIVE]->(objective:DesignObjective)
MATCH (decision:DesignDecision)-[:SUPPORTS]->(objective)
OPTIONAL MATCH (decision)-[:SELECTS]->(option:DesignOption)
RETURN domain.name AS domain, objective.name AS objective,
       decision.name AS decision, option.name AS selected_option,
       decision.status AS status
ORDER BY domain.name;

// Risks with service or failure-domain impact, mitigation, and validation.
MATCH (source)-[:INTRODUCES_RISK]->(risk:DesignRisk)
OPTIONAL MATCH (risk)-[:IMPACTS]->(impact)
OPTIONAL MATCH (risk)-[:MITIGATED_BY]->(mitigation)
OPTIONAL MATCH (risk)-[:VALIDATED_BY]->(validation)
RETURN risk.name AS risk, risk.severity AS severity, labels(source)[0] AS introduced_by_type,
       source.name AS introduced_by, impact.name AS impact,
       mitigation.name AS mitigation, validation.name AS validation
ORDER BY risk.severity, risk.name;

// Merger protocol boundary, overlap, and phase exit validation.
MATCH (organization:Organization)-[:OWNS_DOMAIN]->(network:NetworkDomain)
MATCH (network)-[:HAS_OVERLAP]->(overlap:AddressOverlap)
MATCH (phase:IntegrationPhase)-[:USES_INTERIM_POLICY]->(rule:RedistributionRule)
MATCH (phase)-[:VALIDATED_BY]->(check:ValidationCheck)
RETURN organization.name AS organization, network.protocol AS protocol,
       overlap.cidr AS overlap, phase.name AS integration_phase,
       rule.name AS boundary_policy, check.name AS exit_validation
ORDER BY organization.name;

// Enterprise service transport, VPN, and QoS dependencies.
MATCH (service:BusinessService {id: 'design-payment-service'})
MATCH (service)-[:USES_TRANSPORT]->(transport:WANTransport)
MATCH (service)-[:CONSUMES_VPN]->(vpn:VPNService)
MATCH (service)-[:DEPENDS_ON]->(qos:QoSPolicy)
RETURN service.name AS service, collect(DISTINCT transport.name) AS transports,
       vpn.name AS vpn, qos.name AS qos_policy;

// Explicit option tradeoffs.
MATCH (decision:DesignDecision)-[:HAS_TRADEOFF]->(tradeoff:Tradeoff)
RETURN decision.name AS decision, tradeoff.benefit AS benefit,
       tradeoff.cost AS cost
ORDER BY decision.name;

// Validation coverage for material design decisions.
MATCH (decision:DesignDecision)
OPTIONAL MATCH (decision)-[:VALIDATED_BY]->(check:ValidationCheck)
RETURN decision.name AS decision, decision.status AS status,
       collect(check.name) AS validation_checks,
       CASE WHEN count(check) > 0 THEN 'covered' ELSE 'gap' END AS coverage
ORDER BY decision.name;
