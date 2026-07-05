// Incident 1: STP root and FHRP active gateway are misaligned.
MERGE (incident:Incident {id: 'view-incident-stp-fhrp'})
SET incident.name = 'VLAN 100 STP/FHRP Misalignment',
    incident.scenario = 'stp-fhrp', incident.status = 'open',
    incident.dataset = 'vexpertai-design-ontology'
MERGE (alert:Alert {id: 'view-alert-interdist-utilization'})
SET alert.name = 'High Inter-Distribution Utilization',
    alert.severity = 'warning', alert.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'view-evidence-stp-fhrp'})
SET evidence.name = 'Suboptimal VLAN 100 Forwarding Path',
    evidence.summary = 'STP root is Dist-01 while HSRP active is Dist-02; traffic crosses the inter-distribution link at 86 percent utilization.',
    evidence.source = 'path-analysis://vlan100 and telemetry://interdist/utilization',
    evidence.dataset = 'vexpertai-design-ontology'
MERGE (recommendation:Recommendation {id: 'view-recommendation-stp-fhrp'})
SET recommendation.name = 'Align VLAN 100 STP and FHRP Roles',
    recommendation.action = 'Move the VLAN 100 HSRP active role to Dist-01 or move the STP root after validating failure behavior.',
    recommendation.dataset = 'vexpertai-design-ontology'
MERGE (validation:ValidationRun {id: 'view-validation-stp-fhrp'})
SET validation.name = 'VLAN 100 Role Alignment Validation',
    validation.status = 'planned', validation.dataset = 'vexpertai-design-ontology'
WITH incident, alert, evidence, recommendation, validation
MATCH (service:BusinessService {id: 'view-service-payment'}),
      (distLink:Interface {id: 'view-interface-ethernet1-49'})
MERGE (alert)-[:OBSERVED_ON]->(distLink)
MERGE (incident)-[:CONTAINS]->(alert)
MERGE (incident)-[:IMPACTS]->(service)
MERGE (evidence)-[:SUPPORTS]->(incident)
MERGE (recommendation)-[:BASED_ON]->(evidence)
MERGE (recommendation)-[:REQUIRES]->(validation)
MERGE (validation)-[:TESTS]->(recommendation);

// Incident 2: CHG-8821 removes the OSPF-originated Payment-App prefix from BGP.
MERGE (change:Change {id: 'view-change-chg-8821'})
SET change.name = 'CHG-8821 Prefix-List Update', change.external_id = 'CHG-8821',
    change.timestamp = '2026-07-05T08:57:00Z',
    change.summary = 'PL-PROD changed 10.20.30.0/24 from permit to deny.',
    change.dataset = 'vexpertai-design-ontology'
MERGE (incident:Incident {id: 'view-incident-redist'})
SET incident.name = 'Payment-App Redistribution Failure',
    incident.scenario = 'ospf-bgp', incident.status = 'open',
    incident.dataset = 'vexpertai-design-ontology'
MERGE (alert:Alert {id: 'view-alert-payment-prefix-missing'})
SET alert.name = 'Payment-App Prefix Missing from BGP',
    alert.severity = 'critical', alert.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'view-evidence-redist'})
SET evidence.name = 'CHG-8821 Route Withdrawal Correlation',
    evidence.summary = '10.20.30.0/24 disappeared from BGP immediately after PL-PROD changed to deny.',
    evidence.source = 'change://CHG-8821 and bgp-rib://10.20.30.0/24',
    evidence.dataset = 'vexpertai-design-ontology'
MERGE (recommendation:Recommendation {id: 'view-recommendation-redist'})
SET recommendation.name = 'Restore PL-PROD Payment Prefix',
    recommendation.action = 'Restore only 10.20.30.0/24, validate OSPF presence and BGP advertisement, then run Payment-App probes before production remediation.',
    recommendation.dataset = 'vexpertai-design-ontology'
MERGE (validation:ValidationRun {id: 'view-validation-redist'})
SET validation.name = 'Payment Prefix Advertisement Validation',
    validation.status = 'planned', validation.dataset = 'vexpertai-design-ontology'
WITH change, incident, alert, evidence, recommendation, validation
MATCH (prefixList:PrefixList {id: 'view-pl-prod'}),
      (bgp:BGPProcess {id: 'view-bgp-65001'}),
      (service:BusinessService {id: 'view-service-payment'})
MERGE (change)-[:MODIFIES]->(prefixList)
MERGE (change)-[:AFFECTS]->(service)
MERGE (alert)-[:OBSERVED_ON]->(bgp)
MERGE (incident)-[:CONTAINS]->(alert)
MERGE (incident)-[:IMPACTS]->(service)
MERGE (evidence)-[:SUPPORTS]->(incident)
MERGE (evidence)-[:EVIDENCES]->(change)
MERGE (evidence)-[:EVIDENCES]->(prefixList)
MERGE (recommendation)-[:BASED_ON]->(evidence)
MERGE (recommendation)-[:REQUIRES]->(validation)
MERGE (validation)-[:TESTS]->(recommendation);

// Incident 3: VPN control plane is correct, but the MPLS data plane has no label.
MERGE (incident:Incident {id: 'view-incident-bgp-mpls'})
SET incident.name = 'Payment VPN Label Blackhole',
    incident.scenario = 'bgp-mpls', incident.status = 'open',
    incident.dataset = 'vexpertai-design-ontology'
MERGE (alert:Alert {id: 'view-alert-mpls-label-missing'})
SET alert.name = 'Remote PE Label Missing',
    alert.severity = 'critical', alert.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'view-evidence-bgp-mpls'})
SET evidence.name = 'VPN Route Present but LFIB Missing',
    evidence.summary = 'VPNv4 route and RT 65001:100 are correct, but the remote-PE LSP and service label are absent.',
    evidence.source = 'vpnv4-rib://payment and lfib://remote-pe',
    evidence.dataset = 'vexpertai-design-ontology'
MERGE (recommendation:Recommendation {id: 'view-recommendation-bgp-mpls'})
SET recommendation.name = 'Validate Label Path Before BGP Policy',
    recommendation.action = 'Verify LDP or SR label allocation, remote-PE LSP, and IGP underlay before changing BGP policy.',
    recommendation.dataset = 'vexpertai-design-ontology'
MERGE (validation:ValidationRun {id: 'view-validation-bgp-mpls'})
SET validation.name = 'MPLS Label Path Validation',
    validation.status = 'planned', validation.dataset = 'vexpertai-design-ontology'
WITH incident, alert, evidence, recommendation, validation
MATCH (lsp:MPLSLSP {id: 'view-lsp-payment'}),
      (service:BusinessService {id: 'view-service-payment'})
MERGE (alert)-[:OBSERVED_ON]->(lsp)
MERGE (incident)-[:CONTAINS]->(alert)
MERGE (incident)-[:IMPACTS]->(service)
MERGE (evidence)-[:SUPPORTS]->(incident)
MERGE (recommendation)-[:BASED_ON]->(evidence)
MERGE (recommendation)-[:REQUIRES]->(validation)
MERGE (validation)-[:TESTS]->(recommendation);

// Incident 4: Payment traffic remains best effort during WAN congestion.
MERGE (incident:Incident {id: 'view-incident-qos'})
SET incident.name = 'Payment-App QoS SLA Violation',
    incident.scenario = 'qos-wan', incident.status = 'open',
    incident.dataset = 'vexpertai-design-ontology'
MERGE (alert:Alert {id: 'view-alert-payment-latency'})
SET alert.name = 'Payment-App Latency Above SLA',
    alert.severity = 'high', alert.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'view-evidence-qos'})
SET evidence.name = 'Best-Effort Classification During Congestion',
    evidence.summary = 'Payment-App traffic maps to BEST-EFFORT while WAN congestion raises latency above 200 ms.',
    evidence.source = 'qos-policy://wan and sla-probe://payment',
    evidence.dataset = 'vexpertai-design-ontology'
MERGE (recommendation:Recommendation {id: 'view-recommendation-qos'})
SET recommendation.name = 'Classify Payment Traffic as Business Critical',
    recommendation.action = 'Map Payment-App to the business-critical class and validate egress policy on WAN interfaces under load.',
    recommendation.dataset = 'vexpertai-design-ontology'
MERGE (validation:ValidationRun {id: 'view-validation-qos'})
SET validation.name = 'Payment QoS Load Validation',
    validation.status = 'planned', validation.dataset = 'vexpertai-design-ontology'
WITH incident, alert, evidence, recommendation, validation
MATCH (uplink:Interface {id: 'view-interface-ethernet1-49'}),
      (service:BusinessService {id: 'view-service-payment'})
MERGE (alert)-[:OBSERVED_ON]->(uplink)
MERGE (incident)-[:CONTAINS]->(alert)
MERGE (incident)-[:IMPACTS]->(service)
MERGE (evidence)-[:SUPPORTS]->(incident)
MERGE (recommendation)-[:BASED_ON]->(evidence)
MERGE (recommendation)-[:REQUIRES]->(validation)
MERGE (validation)-[:TESTS]->(recommendation);
