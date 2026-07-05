// 1. Rank options by requirement coverage, risk count, and unmitigated risk.
MATCH (option:DesignOption {chapter: '02'})
OPTIONAL MATCH (option)-[:SATISFIES]->(requirement:Requirement)
WITH option, count(DISTINCT requirement) AS requirement_count
OPTIONAL MATCH (option)-[:HAS_RISK]->(risk:Risk)
OPTIONAL MATCH (risk)-[:MITIGATED_BY]->(control:Control)
WITH option, requirement_count, count(DISTINCT risk) AS risk_count,
     count(DISTINCT CASE WHEN control IS NOT NULL THEN risk END) AS mitigated_risk_count
RETURN option.name AS option, option.status AS status,
       requirement_count, risk_count,
       risk_count - mitigated_risk_count AS unmitigated_risks,
       requirement_count * 10 - risk_count * 2
         - (risk_count - mitigated_risk_count) * 5 AS decision_score
ORDER BY decision_score DESC, requirement_count DESC, risk_count ASC;

// 2. Assumptions that have not been validated.
MATCH (assumption:Assumption)
WHERE assumption.status <> 'validated'
  AND NOT (assumption)-[:VALIDATED_BY]->()
OPTIONAL MATCH (source)-[:BASED_ON_ASSUMPTION]->(assumption)
RETURN assumption.name AS assumption, assumption.owner AS owner,
       assumption.status AS status, collect(source.name) AS used_by
ORDER BY assumption;

// 3. Migration steps with incomplete prerequisites or no tested rollback.
MATCH (step:MigrationStep)-[:DEPENDS_ON]->(prerequisite:MigrationStep)
OPTIONAL MATCH (step)-[:HAS_ROLLBACK]->(rollback:RollbackPlan)
WITH step, prerequisite, collect(rollback) AS rollback_plans
WHERE prerequisite.status <> 'validated'
   OR none(plan IN rollback_plans WHERE plan.tested = true)
RETURN step.sequence AS sequence, step.name AS unsafe_step,
       prerequisite.name AS prerequisite,
       prerequisite.status AS prerequisite_status,
       CASE
         WHEN prerequisite.status <> 'validated' THEN 'prerequisite not validated'
         ELSE 'no tested rollback'
       END AS unsafe_reason
ORDER BY sequence;

// 4. Protocol changes that introduce monitoring requirements.
MATCH (addition:TechnologyAddition)-[:IMPACTS]->(protocol:ExistingProtocol)
MATCH (protocol)-[:HAS_FEATURE]->(feature:ProtocolFeature)
MATCH (monitoring:MonitoringRequirement)-[:COVERS]->(feature)
RETURN addition.name AS protocol_change, protocol.name AS affected_protocol,
       feature.name AS feature, monitoring.name AS monitoring_requirement,
       monitoring.signal AS required_signal
ORDER BY protocol_change;

// 5. Technology additions that increase operational complexity.
MATCH (addition:TechnologyAddition)-[:INCREASES]->(complexity:OperationalComplexity)
OPTIONAL MATCH (addition)-[:IMPACTS]->(protocol:ExistingProtocol)
RETURN addition.name AS technology_addition, protocol.name AS affected_protocol,
       complexity.name AS complexity, complexity.score AS complexity_score,
       complexity.drivers AS complexity_drivers
ORDER BY complexity_score DESC;

// 6. Risks without a mitigation control.
MATCH (risk:Risk)
WHERE NOT (risk)-[:MITIGATED_BY]->(:Control)
OPTIONAL MATCH (option:DesignOption)-[:HAS_RISK]->(risk)
OPTIONAL MATCH (decision:DesignDecision)-[:CREATES_RISK]->(risk)
RETURN risk.name AS risk, risk.severity AS severity,
       risk.likelihood AS likelihood, risk.state AS state,
       collect(DISTINCT option.name) AS exposed_by_options,
       collect(DISTINCT decision.name) AS accepted_by_decisions,
       CASE risk.severity
         WHEN 'critical' THEN 1
         WHEN 'high' THEN 2
         WHEN 'medium' THEN 3
         ELSE 4
       END AS severity_rank
ORDER BY severity_rank, risk;
