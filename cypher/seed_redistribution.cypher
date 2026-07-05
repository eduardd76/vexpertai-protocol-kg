// Routing devices and protocol instances.
MERGE (edge:Device {id: 'dc-edge-01'})
SET edge.name = 'dc-edge-01', edge.role = 'data-center-edge',
    edge.platform = 'IOS-XE', edge.dataset = 'vexpertai-mvp'
MERGE (branch:Device {id: 'branch-router-01'})
SET branch.name = 'branch-router-01', branch.role = 'branch-edge',
    branch.platform = 'IOS-XE', branch.dataset = 'vexpertai-mvp'
MERGE (site:Site {id: 'site-dc1'})
SET site.name = 'Primary Data Center', site.dataset = 'vexpertai-mvp'
WITH edge, branch, site
MERGE (edge)-[:LOCATED_IN]->(site)
MERGE (branch)-[:LOCATED_IN]->(site);

MERGE (ospf:OSPFProcess {id: 'dc-edge-01:ospf:100'})
SET ospf.name = 'OSPF process 100', ospf.process_id = 100,
    ospf.router_id = '10.255.1.1', ospf.status = 'up',
    ospf.dataset = 'vexpertai-mvp'
MERGE (bgp:BGPProcess {id: 'dc-edge-01:bgp:65001'})
SET bgp.name = 'dc-edge-01 BGP', bgp.asn = 65001,
    bgp.router_id = '10.255.1.1', bgp.status = 'up',
    bgp.dataset = 'vexpertai-mvp'
MERGE (branchbgp:BGPProcess {id: 'branch-router-01:bgp:65100'})
SET branchbgp.name = 'branch-router-01 BGP', branchbgp.asn = 65100,
    branchbgp.status = 'up', branchbgp.dataset = 'vexpertai-mvp'
WITH ospf, bgp, branchbgp
MATCH (edge:Device {id: 'dc-edge-01'}), (branch:Device {id: 'branch-router-01'})
MERGE (edge)-[:RUNS]->(ospf)
MERGE (edge)-[:RUNS]->(bgp)
MERGE (branch)-[:RUNS]->(branchbgp)
MERGE (ospf)-[:REDISTRIBUTES_TO {rule_id: 'REDIST-OSPF-BGP-PROD'}]->(bgp);

MERGE (neighbor:BGPNeighbor {id: 'dc-edge-01->branch-router-01'})
SET neighbor.name = 'branch-router-01', neighbor.peer_address = '192.0.2.2',
    neighbor.remote_as = 65100, neighbor.session_state = 'established',
    neighbor.dataset = 'vexpertai-mvp'
WITH neighbor
MATCH (bgp:BGPProcess {id: 'dc-edge-01:bgp:65001'}),
      (branchbgp:BGPProcess {id: 'branch-router-01:bgp:65100'})
MERGE (bgp)-[:HAS_NEIGHBOR]->(neighbor)
MERGE (neighbor)-[:PEERS_WITH]->(branchbgp);

// Prefix lineage and redistribution policy.
MERGE (prefix:Prefix {id: 'prefix-10.20.30.0-24'})
SET prefix.name = 'Payment production prefix', prefix.cidr = '10.20.30.0/24',
    prefix.current_state = 'missing_from_bgp', prefix.dataset = 'vexpertai-mvp'
MERGE (route:Route {id: 'route-10.20.30.0-24'})
SET route.name = 'Route 10.20.30.0/24', route.protocol_origin = 'OSPF',
    route.bgp_state = 'withdrawn', route.last_advertised = '2026-07-05T08:58:42Z',
    route.dataset = 'vexpertai-mvp'
WITH prefix, route
MATCH (ospf:OSPFProcess {id: 'dc-edge-01:ospf:100'}),
      (bgp:BGPProcess {id: 'dc-edge-01:bgp:65001'})
MERGE (ospf)-[:ADVERTISES {state: 'installed'}]->(prefix)
MERGE (bgp)-[:ADVERTISES {state: 'withdrawn_after_change', peer: 'branch-router-01'}]->(prefix)
MERGE (route)-[:REPRESENTS]->(prefix)
MERGE (route)-[:ORIGINATED_IN]->(ospf)
MERGE (route)-[:LAST_ADVERTISED_BY]->(bgp);

MERGE (rule:RedistributionRule {id: 'REDIST-OSPF-BGP-PROD'})
SET rule.name = 'REDIST-OSPF-BGP-PROD', rule.source_protocol = 'OSPF',
    rule.target_protocol = 'BGP', rule.status = 'policy_reject',
    rule.dataset = 'vexpertai-mvp'
MERGE (routeMap:RouteMap {id: 'RM-OSPF-TO-BGP'})
SET routeMap.name = 'RM-OSPF-TO-BGP', routeMap.sequence = 10,
    routeMap.action = 'permit', routeMap.dataset = 'vexpertai-mvp'
MERGE (prefixList:PrefixList {id: 'PL-PROD'})
SET prefixList.name = 'PL-PROD', prefixList.current_action = 'deny',
    prefixList.previous_action = 'permit', prefixList.sequence = 10,
    prefixList.dataset = 'vexpertai-mvp'
MERGE (community:Community {id: 'community-65001-100'})
SET community.name = '65001:100', community.value = '65001:100',
    community.meaning = 'Production redistributed route',
    community.dataset = 'vexpertai-mvp'
WITH rule, routeMap, prefixList, community
MATCH (ospf:OSPFProcess {id: 'dc-edge-01:ospf:100'}),
      (bgp:BGPProcess {id: 'dc-edge-01:bgp:65001'}),
      (prefix:Prefix {id: 'prefix-10.20.30.0-24'}),
      (route:Route {id: 'route-10.20.30.0-24'})
MERGE (rule)-[:SOURCE]->(ospf)
MERGE (rule)-[:TARGET]->(bgp)
MERGE (rule)-[:CONTROLLED_BY]->(routeMap)
MERGE (rule)-[:APPLIES_TO]->(prefix)
MERGE (rule)-[:PRODUCES]->(route)
MERGE (routeMap)-[:REFERENCES]->(prefixList)
MERGE (routeMap)-[:SETS]->(community)
MERGE (prefixList)-[:CONTROLS {current_action: 'deny', previous_action: 'permit'}]->(prefix);

MATCH (prefix:Prefix {id: 'prefix-10.20.30.0-24'}),
      (service:BusinessService {id: 'payment-service'})
MERGE (prefix)-[:SUPPORTS]->(service)
MERGE (service)-[:DEPENDS_ON]->(prefix);

// Change correlation, outage evidence, and recommendation.
MERGE (change:Change {id: 'CHG-8821'})
SET change.name = 'Update production redistribution prefix-list',
    change.timestamp = '2026-07-05T08:57:00Z',
    change.summary = 'PL-PROD sequence 10 changed from permit to deny for 10.20.30.0/24.',
    change.status = 'implemented', change.dataset = 'vexpertai-mvp'
WITH change
MATCH (prefixList:PrefixList {id: 'PL-PROD'}),
      (service:BusinessService {id: 'payment-service'})
MERGE (change)-[:MODIFIES]->(prefixList)
MERGE (change)-[:AFFECTS]->(service);

MERGE (alert:Alert {id: 'ALT-BGP-PREFIX-001'})
SET alert.name = 'BGP prefix missing', alert.severity = 'critical',
    alert.status = 'open', alert.timestamp = '2026-07-05T08:59:10Z',
    alert.dataset = 'vexpertai-mvp'
MERGE (symptom:Symptom {id: 'SYM-BGP-PREFIX-MISSING'})
SET symptom.name = '10.20.30.0/24 absent from branch BGP advertisement',
    symptom.dataset = 'vexpertai-mvp'
WITH alert, symptom
MATCH (edge:Device {id: 'dc-edge-01'})
MERGE (alert)-[:OBSERVED_ON]->(edge)
MERGE (alert)-[:INDICATES]->(symptom);

MERGE (incident:Incident {id: 'INC-REDIST-001'})
SET incident.name = 'Payment-App branch reachability loss',
    incident.status = 'investigating', incident.severity = 'critical',
    incident.dataset = 'vexpertai-mvp'
MERGE (evidence:Evidence {id: 'EVD-REDIST-CHANGE-001'})
SET evidence.name = 'Prefix withdrawal correlated with CHG-8821',
    evidence.summary = '10.20.30.0/24 disappeared from the branch advertisement 102 seconds after PL-PROD changed from permit to deny.',
    evidence.source = 'config-diff://CHG-8821;rib-summary://dc-edge-01/10.20.30.0-24',
    evidence.scenario = 'redistribution', evidence.dataset = 'vexpertai-mvp'
WITH incident, evidence
MATCH (alert:Alert {id: 'ALT-BGP-PREFIX-001'}),
      (service:BusinessService {id: 'payment-service'}),
      (prefix:Prefix {id: 'prefix-10.20.30.0-24'}),
      (change:Change {id: 'CHG-8821'})
MERGE (incident)-[:CONTAINS]->(alert)
MERGE (incident)-[:IMPACTS]->(service)
MERGE (incident)-[:SUPPORTED_BY]->(evidence)
MERGE (evidence)-[:SUPPORTS]->(alert)
MERGE (evidence)-[:ABOUT]->(prefix)
MERGE (evidence)-[:IDENTIFIES]->(change);

MERGE (recommendation:Recommendation {id: 'REC-RESTORE-PL-PROD'})
SET recommendation.name = 'Validate and restore PL-PROD permit',
    recommendation.action = 'In a validation run, restore the intended permit for 10.20.30.0/24 and verify OSPF presence, BGP advertisement, community 65001:100, and branch reachability before remediation.',
    recommendation.risk = 'medium', recommendation.dataset = 'vexpertai-mvp'
MERGE (validation:ValidationRun {id: 'VAL-REDIST-001'})
SET validation.name = 'Redistribution policy validation',
    validation.status = 'pending',
    validation.tests = 'Prefix-list match, route-map result, BGP advertisement, branch reachability',
    validation.dataset = 'vexpertai-mvp'
WITH recommendation, validation
MATCH (evidence:Evidence {id: 'EVD-REDIST-CHANGE-001'})
MERGE (recommendation)-[:BASED_ON]->(evidence)
MERGE (validation)-[:TESTS]->(recommendation);
