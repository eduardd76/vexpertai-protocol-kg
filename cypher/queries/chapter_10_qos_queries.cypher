// 1. Which business services have QoS requirements?
MATCH (service:BusinessService)-[:DEPENDS_ON]->(requirement:SLARequirement)
OPTIONAL MATCH (requirement)-[:MAPS_TO]->(class:QoSClass)
RETURN service.name AS business_service,
       service.criticality AS criticality,
       requirement.name AS qos_requirement,
       requirement.metric AS metric,
       requirement.threshold AS threshold,
       collect(DISTINCT class.name) AS mapped_qos_classes
ORDER BY business_service, metric;

// 2. Which interfaces lack a required QoS policy?
MATCH (interface:Interface)-[:REQUIRES_QOS_POLICY]->(policy:QoSPolicy)
WHERE NOT (policy)-[:APPLIED_TO]->(interface)
RETURN interface.name AS interface,
       interface.capacity_mbps AS capacity_mbps,
       policy.name AS missing_policy,
       policy.status AS policy_status,
       policy.direction AS required_direction;

// 3. Which applications are mismarked?
MATCH (traffic:ApplicationTraffic)-[:REQUIRES_MARKING]->(expected:DSCP)
MATCH (traffic)-[:CLASSIFIED_BY]->(class_map:ClassMap)
      -[:CLASSIFIES_AS]->(class:QoSClass)-[:MARKED_WITH]->(actual:DSCP)
WHERE expected.value <> actual.value
RETURN traffic.name AS application_traffic,
       class_map.name AS class_map,
       class.name AS actual_class,
       expected.value AS expected_dscp,
       actual.value AS actual_dscp
ORDER BY application_traffic;

// 4. Which traffic classes are dropped during congestion?
MATCH (event:CongestionEvent)-[:DROPS_TRAFFIC]->(class:TrafficClass)
OPTIONAL MATCH (event)-[:AFFECTS]->(queue:InterfaceQueue)
OPTIONAL MATCH (policer:PolicingPolicy)-[:MAY_DROP]->(class)
RETURN event.name AS congestion_event,
       event.severity AS severity,
       class.name AS dropped_traffic_class,
       queue.name AS affected_queue,
       queue.drop_percent AS observed_drop_percent,
       policer.name AS related_policer,
       policer.rate_mbps AS policer_rate_mbps;

// 5. Which QoS policies violate design intent?
MATCH (policy:QoSPolicy)-[violation:VIOLATES_QOS_INTENT]->(intent:QoSDesignIntent)
RETURN policy.name AS qos_policy,
       policy.status AS policy_status,
       intent.name AS violated_intent,
       violation.reason AS reason
ORDER BY qos_policy;

// 6. Which SLA violations correlate with congestion evidence?
MATCH (event:CongestionEvent)-[:CAUSES_SLA_VIOLATION]->(violation:SLAViolation)
      -[:VIOLATES_REQUIREMENT]->(requirement:SLARequirement)
MATCH (evidence:Evidence)-[:SUPPORTS_QOS_STATE]->(event)
OPTIONAL MATCH (event)-[:AFFECTS]->(queue:InterfaceQueue)
OPTIONAL MATCH (service:BusinessService)-[:DEPENDS_ON]->(requirement)
RETURN event.name AS congestion_event,
       queue.name AS affected_queue,
       requirement.name AS sla_requirement,
       requirement.threshold AS threshold,
       violation.measured_value AS measured_value,
       collect(DISTINCT service.name) AS impacted_services,
       evidence.summary AS congestion_evidence;
