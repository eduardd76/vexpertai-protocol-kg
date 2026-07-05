// Scenario 1: voice is marked correctly, but the required policy is not attached.
MERGE (wan:Interface:WANLink {id: 'ch10-wan-interface-hq'})
SET wan.name = 'WAN GigabitEthernet0/0', wan.capacity_mbps = 100,
    wan.peak_utilization_percent = 72, wan.status = 'up',
    wan.dataset = 'vexpertai-design-ontology'
MERGE (policy:QoSPolicy {id: 'ch10-policy-wan-edge'})
SET policy.name = 'WAN-EDGE-QOS', policy.status = 'defined_not_applied',
    policy.direction = 'egress', policy.dataset = 'vexpertai-design-ontology'
MERGE (policyMap:PolicyMap {id: 'ch10-policy-map-wan-edge'})
SET policyMap.name = 'PM-WAN-EDGE', policyMap.status = 'defined',
    policyMap.dataset = 'vexpertai-design-ontology'
MERGE (classMap:ClassMap {id: 'ch10-class-map-voice'})
SET classMap.name = 'CM-VOICE-RTP', classMap.match = 'RTP audio',
    classMap.dataset = 'vexpertai-design-ontology'
MERGE (voiceClass:QoSClass:TrafficClass {id: 'ch10-class-voice'})
SET voiceClass.name = 'VOICE', voiceClass.treatment = 'priority',
    voiceClass.dataset = 'vexpertai-design-ontology'
MERGE (voice:ApplicationTraffic:VoiceTraffic {id: 'ch10-traffic-voice'})
SET voice.name = 'Enterprise Voice RTP', voice.application = 'Unified Communications',
    voice.dataset = 'vexpertai-design-ontology'
MERGE (ef:DSCP {id: 'ch10-dscp-ef'})
SET ef.name = 'Expedited Forwarding', ef.value = 'EF',
    ef.dataset = 'vexpertai-design-ontology'
MERGE (cos5:CoS {id: 'ch10-cos-5'})
SET cos5.name = 'CoS 5', cos5.value = 5,
    cos5.dataset = 'vexpertai-design-ontology'
MERGE (marking:MarkingPolicy {id: 'ch10-marking-voice'})
SET marking.name = 'Preserve Voice EF', marking.action = 'set EF',
    marking.dataset = 'vexpertai-design-ontology'
MERGE (queuing:QueuingPolicy {id: 'ch10-queue-policy-wan'})
SET queuing.name = 'WAN Low-Latency Queuing', queuing.scheduler = 'LLQ',
    queuing.dataset = 'vexpertai-design-ontology'
MERGE (priority:PriorityQueue:InterfaceQueue:Queue {id: 'ch10-priority-queue'})
SET priority.name = 'WAN Priority Queue', priority.utilization_percent = 45,
    priority.state = 'healthy', priority.dataset = 'vexpertai-design-ontology'
MERGE (guarantee:BandwidthGuarantee {id: 'ch10-voice-guarantee'})
SET guarantee.name = 'Voice Priority 20 Percent', guarantee.percent = 20,
    guarantee.dataset = 'vexpertai-design-ontology'
MERGE (latency:SLARequirement:LatencyRequirement:SLAObjective {id: 'ch10-sla-voice-latency'})
SET latency.name = 'Voice One-Way Latency', latency.metric = 'latency',
    latency.threshold = '<=150ms', latency.dataset = 'vexpertai-design-ontology'
MERGE (jitter:SLARequirement:JitterRequirement:SLAObjective {id: 'ch10-sla-voice-jitter'})
SET jitter.name = 'Voice Jitter', jitter.metric = 'jitter',
    jitter.threshold = '<=30ms', jitter.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch10-service-voice'})
SET service.name = 'Enterprise Voice', service.criticality = 'critical',
    service.dataset = 'vexpertai-design-ontology'
MERGE (policy)-[:HAS_POLICY_MAP]->(policyMap)
MERGE (policy)-[:HAS_CLASS_MAP]->(classMap)
MERGE (policy)-[:HAS_MARKING_POLICY]->(marking)
MERGE (policy)-[:HAS_QUEUING_POLICY]->(queuing)
MERGE (policyMap)-[:HAS_CLASS_MAP]->(classMap)
MERGE (classMap)-[:BELONGS_TO]->(policy)
MERGE (classMap)-[:CLASSIFIES_AS]->(voiceClass)
MERGE (voice)-[:CLASSIFIED_BY]->(classMap)
MERGE (voice)-[:REQUIRES_MARKING]->(ef)
MERGE (voiceClass)-[:MARKED_WITH]->(ef)
MERGE (voiceClass)-[:MARKED_WITH]->(cos5)
MERGE (queuing)-[:ALLOCATES]->(guarantee)
MERGE (queuing)-[:USES_QUEUE]->(priority)
MERGE (voiceClass)-[:USES_QUEUE]->(priority)
MERGE (priority)-[:PROTECTS]->(voice)
MERGE (wan)-[:HAS_QUEUE]->(priority)
MERGE (wan)-[:REQUIRES_QOS_POLICY]->(policy)
MERGE (latency)-[:MAPS_TO]->(voiceClass)
MERGE (jitter)-[:MAPS_TO]->(voiceClass)
MERGE (service)-[:DEPENDS_ON]->(latency)
MERGE (service)-[:DEPENDS_ON]->(jitter);

// Scenario 2: a critical application is classified and marked as best effort.
MERGE (traffic:ApplicationTraffic:CriticalDataTraffic {id: 'ch10-traffic-payments'})
SET traffic.name = 'Payments Transaction Traffic', traffic.application = 'Payment API',
    traffic.dataset = 'vexpertai-design-ontology'
MERGE (classMap:ClassMap {id: 'ch10-class-map-payments-wrong'})
SET classMap.name = 'CM-PAYMENTS-DEFAULT', classMap.match = 'unmatched default',
    classMap.dataset = 'vexpertai-design-ontology'
MERGE (bestEffort:QoSClass:TrafficClass:BestEffortTraffic {id: 'ch10-class-best-effort'})
SET bestEffort.name = 'BEST-EFFORT', bestEffort.treatment = 'default queue',
    bestEffort.dataset = 'vexpertai-design-ontology'
MERGE (expected:DSCP {id: 'ch10-dscp-af31'})
SET expected.name = 'Assured Forwarding 31', expected.value = 'AF31',
    expected.dataset = 'vexpertai-design-ontology'
MERGE (actual:DSCP {id: 'ch10-dscp-cs0'})
SET actual.name = 'Default Forwarding CS0', actual.value = 'CS0',
    actual.dataset = 'vexpertai-design-ontology'
MERGE (intent:QoSDesignIntent {id: 'ch10-intent-critical-marking'})
SET intent.name = 'Critical applications receive AF31 treatment',
    intent.expected_result = 'Payments traffic is classified as critical data and marked AF31.',
    intent.dataset = 'vexpertai-design-ontology'
MERGE (risk:QoSRisk {id: 'ch10-risk-payments-best-effort'})
SET risk.name = 'Payments traffic competes as best effort', risk.severity = 'critical',
    risk.likelihood = 'high', risk.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch10-service-payments'})
SET service.name = 'Payment Processing', service.criticality = 'critical',
    service.dataset = 'vexpertai-design-ontology'
WITH traffic, classMap, bestEffort, expected, actual, intent, risk, service
MATCH (policy:QoSPolicy {id: 'ch10-policy-wan-edge'})
MERGE (traffic)-[:CLASSIFIED_BY]->(classMap)
MERGE (traffic)-[:REQUIRES_MARKING]->(expected)
MERGE (classMap)-[:BELONGS_TO]->(policy)
MERGE (classMap)-[:CLASSIFIES_AS]->(bestEffort)
MERGE (bestEffort)-[:MARKED_WITH]->(actual)
MERGE (policy)-[:HAS_CLASS_MAP]->(classMap)
MERGE (classMap)-[:VIOLATES_QOS_INTENT]->(intent)
MERGE (policy)-[:VIOLATES_QOS_INTENT {reason: 'critical traffic classified as default'}]->(intent)
MERGE (classMap)-[:EXPOSES_QOS_RISK]->(risk)
MERGE (risk)-[:IMPACTS]->(service);

// Scenario 3: excessive priority allowance and poor policing starve other traffic.
MERGE (policer:PolicingPolicy {id: 'ch10-policer-priority-bad'})
SET policer.name = 'Priority Policier 90 Mbps', policer.rate_mbps = 90,
    policer.status = 'overallocated', policer.dataset = 'vexpertai-design-ontology'
MERGE (dataClass:QoSClass:TrafficClass {id: 'ch10-class-other-data'})
SET dataClass.name = 'OTHER-DATA', dataClass.treatment = 'bandwidth 10 percent',
    dataClass.dataset = 'vexpertai-design-ontology'
MERGE (classMap:ClassMap {id: 'ch10-class-map-other-data'})
SET classMap.name = 'CM-OTHER-DATA', classMap.match = 'remaining business traffic',
    classMap.dataset = 'vexpertai-design-ontology'
MERGE (dataTraffic:ApplicationTraffic:BestEffortTraffic {id: 'ch10-traffic-other-data'})
SET dataTraffic.name = 'General Business Data', dataTraffic.application = 'Office Applications',
    dataTraffic.dataset = 'vexpertai-design-ontology'
MERGE (queue:InterfaceQueue:Queue {id: 'ch10-queue-other-data'})
SET queue.name = 'Other Data Queue', queue.utilization_percent = 100,
    queue.state = 'tail_drop', queue.drop_percent = 12.5,
    queue.dataset = 'vexpertai-design-ontology'
MERGE (event:CongestionEvent {id: 'ch10-event-priority-starvation'})
SET event.name = 'Priority Queue Starvation Event', event.severity = 'high',
    event.started_at = '2026-07-05T14:00:00Z',
    event.dataset = 'vexpertai-design-ontology'
MERGE (intent:QoSDesignIntent {id: 'ch10-intent-priority-bounded'})
SET intent.name = 'Priority traffic must be bounded',
    intent.expected_result = 'Priority traffic cannot consume bandwidth guaranteed to other classes.',
    intent.dataset = 'vexpertai-design-ontology'
MERGE (risk:OversubscriptionRisk {id: 'ch10-risk-priority-starvation'})
SET risk.name = 'Priority queue starves other traffic', risk.severity = 'high',
    risk.likelihood = 'high', risk.dataset = 'vexpertai-design-ontology'
WITH policer, dataClass, classMap, dataTraffic, queue, event, intent, risk
MATCH (policy:QoSPolicy {id: 'ch10-policy-wan-edge'})
MATCH (priority:PriorityQueue {id: 'ch10-priority-queue'})
MATCH (wan:WANLink {id: 'ch10-wan-interface-hq'})
MERGE (priority)-[:HAS_POLICING_POLICY]->(policer)
MERGE (policer)-[:MAY_DROP]->(dataClass)
MERGE (classMap)-[:BELONGS_TO]->(policy)
MERGE (classMap)-[:CLASSIFIES_AS]->(dataClass)
MERGE (policy)-[:HAS_CLASS_MAP]->(classMap)
MERGE (dataClass)-[:USES_QUEUE]->(queue)
MERGE (dataTraffic)-[:CLASSIFIED_BY]->(classMap)
MERGE (wan)-[:HAS_QUEUE]->(queue)
MERGE (event)-[:AFFECTS]->(queue)
MERGE (event)-[:DROPS_TRAFFIC]->(dataClass)
MERGE (queue)-[:DROPS_TRAFFIC]->(dataClass)
MERGE (policer)-[:VIOLATES_QOS_INTENT]->(intent)
MERGE (policy)-[:VIOLATES_QOS_INTENT {reason: 'priority policer permits 90 percent of link'}]->(intent)
MERGE (policer)-[:EXPOSES_QOS_RISK]->(risk);

// Scenario 4: WAN congestion correlates with loss SLA violation.
MERGE (wan:Interface:WANLink:CongestionPoint {id: 'ch10-wan-interface-branch'})
SET wan.name = 'Branch WAN Serial0/0', wan.capacity_mbps = 50,
    wan.peak_utilization_percent = 100, wan.status = 'congested',
    wan.dataset = 'vexpertai-design-ontology'
MERGE (queue:InterfaceQueue:Queue {id: 'ch10-queue-branch-default'})
SET queue.name = 'Branch Default Queue', queue.utilization_percent = 100,
    queue.state = 'congested', queue.drop_percent = 2.4,
    queue.dataset = 'vexpertai-design-ontology'
MERGE (event:CongestionEvent {id: 'ch10-event-branch-congestion'})
SET event.name = 'Branch WAN Saturation', event.severity = 'critical',
    event.started_at = '2026-07-05T14:15:00Z',
    event.dataset = 'vexpertai-design-ontology'
MERGE (policy:QoSPolicy {id: 'ch10-policy-branch-applied'})
SET policy.name = 'BRANCH-WAN-QOS', policy.status = 'applied_insufficient_capacity',
    policy.direction = 'egress', policy.dataset = 'vexpertai-design-ontology'
MERGE (transactionClass:QoSClass:TrafficClass {id: 'ch10-class-branch-transactions'})
SET transactionClass.name = 'BRANCH-TRANSACTIONS',
    transactionClass.treatment = 'bandwidth guarantee',
    transactionClass.dataset = 'vexpertai-design-ontology'
MERGE (requirement:SLARequirement:LossRequirement:SLAObjective {id: 'ch10-sla-branch-loss'})
SET requirement.name = 'Branch Transaction Loss', requirement.metric = 'packet_loss',
    requirement.threshold = '<=0.1%', requirement.dataset = 'vexpertai-design-ontology'
MERGE (violation:SLAViolation {id: 'ch10-violation-branch-loss'})
SET violation.name = 'Branch Packet Loss Breach', violation.measured_value = '2.4%',
    violation.status = 'active', violation.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'ch10-evidence-branch-congestion'})
SET evidence.name = 'WAN queue and SLA measurement',
    evidence.summary = 'WAN utilization reached 100 percent while packet loss rose to 2.4 percent.',
    evidence.source = 'interface queue counters and SLA probe summary',
    evidence.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch10-service-branch-transactions'})
SET service.name = 'Branch Transactions', service.criticality = 'critical',
    service.dataset = 'vexpertai-design-ontology'
MERGE (risk:OversubscriptionRisk {id: 'ch10-risk-branch-capacity'})
SET risk.name = 'Branch WAN capacity exhaustion', risk.severity = 'critical',
    risk.likelihood = 'high', risk.dataset = 'vexpertai-design-ontology'
MERGE (wan)-[:HAS_QUEUE]->(queue)
MERGE (policy)-[:APPLIED_TO]->(wan)
MERGE (policy)-[:APPLIED_AT]->(wan)
MERGE (event)-[:AFFECTS]->(queue)
MERGE (event)-[:CAUSES_SLA_VIOLATION]->(violation)
MERGE (violation)-[:VIOLATES_REQUIREMENT]->(requirement)
MERGE (requirement)-[:MAPS_TO]->(transactionClass)
MERGE (service)-[:DEPENDS_ON]->(requirement)
MERGE (evidence)-[:SUPPORTS_QOS_STATE]->(event)
MERGE (evidence)-[:SUPPORTS_QOS_STATE]->(queue)
MERGE (evidence)-[:SUPPORTS_QOS_STATE]->(violation)
MERGE (wan)-[:EXPOSES_QOS_RISK]->(risk)
MERGE (risk)-[:IMPACTS]->(service);

// Scenario 5: measured headroom shows that additional QoS is unnecessary.
MERGE (wan:Interface:WANLink {id: 'ch10-wan-interface-dc'})
SET wan.name = 'Data Center Interconnect 10G', wan.capacity_mbps = 10000,
    wan.peak_utilization_percent = 18, wan.status = 'healthy',
    wan.dataset = 'vexpertai-design-ontology'
MERGE (policy:QoSPolicy {id: 'ch10-policy-dc-overengineered'})
SET policy.name = 'Proposed DCI Eight-Class QoS', policy.status = 'unnecessary',
    policy.direction = 'egress', policy.dataset = 'vexpertai-design-ontology'
MERGE (intent:QoSDesignIntent {id: 'ch10-intent-operational-simplicity'})
SET intent.name = 'Avoid QoS without a real bandwidth constraint',
    intent.expected_result = 'Use available capacity when measured headroom meets all service needs.',
    intent.dataset = 'vexpertai-design-ontology'
MERGE (assessment:QoSDesignAssessment {id: 'ch10-assessment-dc-qos'})
SET assessment.name = 'DCI QoS Necessity Assessment', assessment.status = 'not_required',
    assessment.rationale = 'Peak utilization is 18 percent and no differentiated SLA is present.',
    assessment.dataset = 'vexpertai-design-ontology'
MERGE (risk:OversubscriptionRisk {id: 'ch10-risk-dc-capacity'})
SET risk.name = 'DCI Oversubscription Risk', risk.severity = 'low',
    risk.likelihood = 'unlikely', risk.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'ch10-evidence-dc-headroom'})
SET evidence.name = 'DCI capacity trend',
    evidence.summary = 'Thirty-day peak utilization is 18 percent on a 10 Gbps link.',
    evidence.source = 'capacity planning summary',
    evidence.dataset = 'vexpertai-design-ontology'
MERGE (policy)-[:VIOLATES_QOS_INTENT {reason: 'adds complexity without congestion constraint'}]->(intent)
MERGE (assessment)-[:EVALUATES_LINK]->(wan)
MERGE (evidence)-[:SUPPORTS_QOS_STATE]->(assessment)
MERGE (wan)-[:EXPOSES_QOS_RISK]->(risk);
