"""Deterministic query functions for the MVP scenarios."""

from typing import Any, Optional

from neo4j import Driver


QueryRows = list[dict[str, Any]]


def run_query(
    driver: Driver,
    cypher: str,
    parameters: Optional[dict[str, Any]] = None,
) -> QueryRows:
    """Run a read query and return plain dictionaries."""
    with driver.session() as session:
        result = session.run(cypher, parameters or {})
        return [record.data() for record in result]


def overlay_service_impact(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (incident:Incident)-[:CONTAINS]->(alert:Alert)
              -[:OBSERVED_ON]->(overlay:VXLANOverlay)
        MATCH (incident)-[:IMPACTS]->(service:BusinessService)
        WHERE alert.name = 'VXLAN tunnel down'
        RETURN incident.id AS incident, overlay.name AS overlay,
               service.name AS impacted_service,
               service.criticality AS criticality
        """,
    )


def likely_underlay_cause(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (alert:Alert {id: 'ALT-VXLAN-001'})
              -[:OBSERVED_ON]->(overlay:VXLANOverlay)
        MATCH (alert)-[:OBSERVED_ON]->(device:Device)-[:HOSTS]->(vtep:VTEP)
        MATCH (overlay)-[:DEPENDS_ON]->(:EVPNControlPlane)
              -[:DEPENDS_ON]->(vtep)
        MATCH (vtep)-[:DEPENDS_ON]->(underlay:UnderlayRouting)
              -[:DEPENDS_ON]->(link:PhysicalLink)
        MATCH (link)-[:HAS_ENDPOINT]->(interface:Interface)
        WHERE interface.status = 'degraded'
        RETURN device.name AS device, vtep.name AS vtep,
               underlay.name AS underlay, link.name AS likely_failed_link,
               interface.id AS degraded_interface,
               interface.crc_errors AS crc_errors
        """,
    )


def vtep_dependencies(driver: Driver, vtep_id: str = "vtep-leaf-01") -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (vtep:VTEP {id: $vtep_id})<-[:DEPENDS_ON]-(:EVPNControlPlane)
              <-[:DEPENDS_ON]-(overlay:VXLANOverlay)-[:CARRIES]->(vni:VNI)
              -[:MAPS_TO]->(vrf:VRF)
        MATCH (service:BusinessService)-[:DEPENDS_ON]->(overlay)
        MATCH (service)-[:DEPENDS_ON]->(vni)
        MATCH (service)-[:DEPENDS_ON]->(vrf)
        RETURN vtep.name AS vtep, vni.number AS vni, vrf.name AS vrf,
               service.name AS business_service
        """,
        {"vtep_id": vtep_id},
    )


def redistributed_prefixes(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (ospf:OSPFProcess)-[:REDISTRIBUTES_TO]->(bgp:BGPProcess)
        MATCH (rule:RedistributionRule)-[:SOURCE]->(ospf)
        MATCH (rule)-[:TARGET]->(bgp)
        MATCH (rule)-[:APPLIES_TO]->(prefix:Prefix)
        RETURN ospf.name AS source, bgp.name AS target, rule.name AS rule,
               prefix.cidr AS prefix, prefix.current_state AS current_state
        """,
    )


def redistribution_controls(
    driver: Driver,
    cidr: str = "10.20.30.0/24",
) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (rule:RedistributionRule)-[:APPLIES_TO]->(prefix:Prefix {cidr: $cidr})
        MATCH (rule)-[:CONTROLLED_BY]->(route_map:RouteMap)
              -[:REFERENCES]->(prefix_list:PrefixList)
        MATCH (route_map)-[:SETS]->(community:Community)
        RETURN prefix.cidr AS prefix, rule.name AS redistribution_rule,
               route_map.name AS route_map, prefix_list.name AS prefix_list,
               prefix_list.current_action AS current_action,
               community.value AS community
        """,
        {"cidr": cidr},
    )


def likely_prefix_change(
    driver: Driver,
    cidr: str = "10.20.30.0/24",
) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (change:Change)-[:MODIFIES]->(prefix_list:PrefixList)
              -[:CONTROLS]->(prefix:Prefix)
        WHERE prefix.cidr = $cidr
        RETURN change.id AS change, change.timestamp AS timestamp,
               change.summary AS reason,
               prefix_list.name AS modified_object
        """,
        {"cidr": cidr},
    )


def rca_evidence(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (incident:Incident)-[:SUPPORTED_BY]->(evidence:Evidence)
        RETURN incident.id AS incident, incident.name AS incident_name,
               evidence.name AS evidence, evidence.summary AS summary,
               evidence.source AS source
        ORDER BY incident.id
        """,
    )


def safe_recommendations(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (validation:ValidationRun)-[:TESTS]->(recommendation:Recommendation)
              -[:BASED_ON]->(evidence:Evidence)
        RETURN recommendation.name AS recommendation,
               recommendation.action AS action,
               recommendation.risk AS risk,
               validation.name AS validation,
               validation.status AS validation_status,
               evidence.name AS based_on
        ORDER BY recommendation
        """,
    )


def layer2_stp_fhrp_misalignment(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (vlan:VLAN)-[:MAPPED_TO]->(stp:STPInstance)
              -[:ELECTS]->(root:STPRootBridge)-[:ROLE_ON]->(root_switch:Switch)
        MATCH (vlan)-[:USES_FHRP]->(group:HSRPGroup)
              -[:HAS_ACTIVE_GATEWAY]->(:FHRPActiveGateway)
              -[:ROLE_ON]->(active_switch:Switch)
        WHERE root_switch <> active_switch
        RETURN vlan.vlan_id AS vlan, vlan.name AS vlan_name,
               root_switch.name AS stp_root,
               active_switch.name AS fhrp_active,
               'Suboptimal inter-distribution transit' AS effect
        ORDER BY vlan
        """,
    )


def layer2_blocked_ports(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (stp:STPInstance)-[:BLOCKS]->(port:STPBlockedPort)
        OPTIONAL MATCH (switch:Switch)-[:HAS_INTERFACE]->(port)
        RETURN stp.name AS stp_instance, switch.name AS switch,
               port.name AS blocked_port, port.reason AS reason,
               port.status AS state
        ORDER BY stp_instance, blocked_port
        """,
    )


def layer2_bpduguard_ports(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (guard:BPDUGuard)-[:PROTECTS]->(port:AccessPort)
        OPTIONAL MATCH (bpdu:BPDU)-[:RECEIVED_ON]->(port)
        RETURN port.id AS port, port.status AS status,
               guard.name AS protection, bpdu.name AS observed_bpdu,
               port.shutdown_reason AS shutdown_reason
        ORDER BY port
        """,
    )


def layer2_unused_vlans(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (vlan:VLAN)-[:CARRIED_BY]->(trunk:Trunk)
        WHERE vlan.active_endpoints = 0
        RETURN trunk.name AS trunk, collect(vlan.vlan_id) AS unused_vlans,
               collect(vlan.name) AS unused_vlan_names,
               trunk.allowed_vlans AS allowed_vlans
        ORDER BY trunk
        """,
    )


def layer2_service_risks(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (risk:Layer2Risk)-[:IMPACTS]->(service:BusinessService)
        OPTIONAL MATCH (source)-[:EXPOSES_RISK|MAY_ENABLE]->(risk)
        RETURN risk.name AS risk, risk.severity AS severity,
               collect(DISTINCT source.name) AS sources,
               collect(DISTINCT service.name) AS affected_services
        ORDER BY severity, risk
        """,
    )


def layer2_design_comparison(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (design:DesignOption)-[:HAS_TRADEOFF]->(tradeoff:Tradeoff)
        WHERE design:LoopedL2Design
           OR design:LoopFreeL2Design
           OR design:RoutedAccessDesign
        RETURN design.name AS design,
               design.suitability_score AS suitability_score,
               design.best_for AS best_for,
               design.failure_domain AS failure_domain,
               design.stp_dependency AS stp_dependency,
               tradeoff.benefit AS benefit, tradeoff.cost AS cost
        ORDER BY suitability_score DESC
        """,
    )


def design_option_ranking(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (option:DesignOption {chapter: '02'})
        OPTIONAL MATCH (option)-[:SATISFIES]->(requirement:Requirement)
        WITH option, count(DISTINCT requirement) AS requirement_count
        OPTIONAL MATCH (option)-[:HAS_RISK]->(risk:Risk)
        OPTIONAL MATCH (risk)-[:MITIGATED_BY]->(control:Control)
        WITH option, requirement_count, count(DISTINCT risk) AS risk_count,
             count(DISTINCT CASE WHEN control IS NOT NULL THEN risk END)
               AS mitigated_risk_count
        RETURN option.name AS option, option.status AS status,
               requirement_count, risk_count,
               risk_count - mitigated_risk_count AS unmitigated_risks,
               requirement_count * 10 - risk_count * 2
                 - (risk_count - mitigated_risk_count) * 5 AS decision_score
        ORDER BY decision_score DESC, requirement_count DESC, risk_count ASC
        """,
    )


def unvalidated_assumptions(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (assumption:Assumption)
        WHERE assumption.status <> 'validated'
          AND NOT (assumption)-[:VALIDATED_BY]->()
        OPTIONAL MATCH (source)-[:BASED_ON_ASSUMPTION]->(assumption)
        RETURN assumption.name AS assumption, assumption.owner AS owner,
               assumption.status AS status, collect(source.name) AS used_by
        ORDER BY assumption
        """,
    )


def unsafe_migration_steps(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (step:MigrationStep)-[:DEPENDS_ON]->(prerequisite:MigrationStep)
        OPTIONAL MATCH (step)-[:HAS_ROLLBACK]->(rollback:RollbackPlan)
        WITH step, prerequisite, collect(rollback) AS rollback_plans
        WHERE prerequisite.status <> 'validated'
           OR none(plan IN rollback_plans WHERE plan.tested = true)
        RETURN step.sequence AS sequence, step.name AS unsafe_step,
               prerequisite.name AS prerequisite,
               prerequisite.status AS prerequisite_status,
               CASE
                 WHEN prerequisite.status <> 'validated'
                   THEN 'prerequisite not validated'
                 ELSE 'no tested rollback'
               END AS unsafe_reason
        ORDER BY sequence
        """,
    )


def protocol_monitoring_impacts(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (addition:TechnologyAddition)-[:IMPACTS]->(protocol:ExistingProtocol)
        MATCH (protocol)-[:HAS_FEATURE]->(feature:ProtocolFeature)
        MATCH (monitoring:MonitoringRequirement)-[:COVERS]->(feature)
        RETURN addition.name AS protocol_change,
               protocol.name AS affected_protocol, feature.name AS feature,
               monitoring.name AS monitoring_requirement,
               monitoring.signal AS required_signal
        ORDER BY protocol_change
        """,
    )


def technology_complexity_impacts(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (addition:TechnologyAddition)
              -[:INCREASES]->(complexity:OperationalComplexity)
        OPTIONAL MATCH (addition)-[:IMPACTS]->(protocol:ExistingProtocol)
        RETURN addition.name AS technology_addition,
               protocol.name AS affected_protocol,
               complexity.name AS complexity,
               complexity.score AS complexity_score,
               complexity.drivers AS complexity_drivers
        ORDER BY complexity_score DESC
        """,
    )


def unmitigated_design_risks(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
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
        ORDER BY severity_rank, risk
        """,
    )


def global_service_protocol_dependencies(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH path=(access:Interface {id: 'global-branch-sw1:Gi1/0/10'})
              -[:SUPPORTS_LAYER*1..12]->
              (service:BusinessService {id: 'global-business-payment'})
        RETURN service.name AS business_service,
               [node IN nodes(path) WHERE node:Protocol | node.name]
                 AS protocol_dependencies,
               [node IN nodes(path) | node.name] AS dependency_chain
        """,
    )


def global_interface_blast_radius(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH path=(interface:Interface {simulated_status: 'failed'})
              -[:SUPPORTS_LAYER*1..12]->(service:BusinessService)
        RETURN interface.id AS failed_interface,
               service.name AS impacted_service,
               service.criticality AS criticality,
               [node IN nodes(path) | node.name] AS blast_radius_path
        """,
    )


def global_policy_change_impact(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (change:Change)-[:MODIFIES]->(prefix_list:PrefixList)
              -[:CONTROLS_PREFIX]->(prefix:Prefix)
        MATCH (route_map:RouteMap)-[:REFERENCES]->(prefix_list)
        MATCH (prefix)-[:SUPPORTS_LAYER]->(application:Application)
              -[:SUPPORTS_LAYER]->(service:BusinessService)
        RETURN change.id AS change, prefix_list.name AS prefix_list,
               route_map.name AS route_map, prefix.cidr AS impacted_prefix,
               collect(DISTINCT application.name) AS impacted_applications,
               collect(DISTINCT service.name) AS impacted_services
        """,
    )


def global_underlay_overlay_impact(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (overlay:OverlayService)-[:DEPENDS_ON]->(underlay)
        WHERE (underlay:TransportUnderlay OR underlay:UnderlayRouting
               OR underlay:ISISUnderlay OR underlay:IGPReachability)
          AND coalesce(underlay.state, underlay.status, 'unknown') <> 'up'
        RETURN underlay.name AS failed_underlay,
               coalesce(underlay.state, underlay.status) AS underlay_state,
               collect(DISTINCT overlay.name) AS impacted_overlays
        """,
    )


def global_valid_design_options(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (option:DesignOption)-[:SATISFIES]->(requirement:Requirement)
        WHERE NOT (option)-[:VIOLATES]->(:Constraint)
        OPTIONAL MATCH (decision:DesignDecision)-[:SELECTS]->(option)
        RETURN requirement.name AS requirement,
               collect(DISTINCT option.name) AS valid_options,
               collect(DISTINCT decision.name) AS selecting_decisions
        ORDER BY requirement
        """,
    )


def global_change_blast_radius(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (change:Change {id: 'global-change-pl-payment'})
        OPTIONAL MATCH (change)-[:AFFECTS]->(prefix:Prefix)
        OPTIONAL MATCH (change)-[:AFFECTS]->(application:Application)
        OPTIONAL MATCH (change)-[:AFFECTS]->(service:BusinessService)
        OPTIONAL MATCH (change)-[:INTRODUCES_RISK]->(risk:Risk)
        OPTIONAL MATCH (service)-[:OWNED_BY]->(owner:ServiceOwner)
        RETURN change.name AS change,
               collect(DISTINCT prefix.cidr) AS affected_prefixes,
               collect(DISTINCT application.name) AS affected_applications,
               collect(DISTINCT service.name) AS affected_services,
               collect(DISTINCT risk.name) AS introduced_risks,
               collect(DISTINCT owner.name) AS owners
        """,
    )


def global_risk_mitigation_validation(driver: Driver) -> QueryRows:
    return run_query(
        driver,
        """
        MATCH (risk:Risk)-[:MITIGATED_BY]->(recommendation:Recommendation)
        MATCH (validation:ValidationRun)-[:TESTS]->(recommendation)
        OPTIONAL MATCH (recommendation)-[:BASED_ON]->(evidence:Evidence)
        OPTIONAL MATCH (risk)-[:OWNED_BY]->(owner:ServiceOwner)
        RETURN risk.name AS risk, risk.severity AS severity,
               recommendation.name AS mitigation,
               recommendation.action AS safe_action,
               validation.name AS validation_plan,
               validation.status AS validation_status,
               evidence.name AS evidence,
               owner.name AS owner
        """,
    )
