// Shared MPLS domain, routers, LDP process, and LFIB.
MERGE (domain:MPLSDomain {id: 'ch11-domain-provider'})
SET domain.name = 'Provider MPLS Core', domain.control_plane = 'LDP and RSVP-TE',
    domain.status = 'degraded', domain.dataset = 'vexpertai-design-ontology'
MERGE (pe1:Device:LabelSwitchRouter:ProviderEdge {id: 'ch11-pe-01'})
SET pe1.name = 'pe-01', pe1.role = 'provider_edge',
    pe1.dataset = 'vexpertai-design-ontology'
MERGE (p1:Device:LabelSwitchRouter:ProviderRouter {id: 'ch11-p-01'})
SET p1.name = 'p-01', p1.role = 'provider_core',
    p1.dataset = 'vexpertai-design-ontology'
MERGE (ce1:Device:CustomerEdge {id: 'ch11-ce-01'})
SET ce1.name = 'customer-edge-01', ce1.role = 'customer_edge',
    ce1.dataset = 'vexpertai-design-ontology'
MERGE (ldp:LDP:LabelDistributionProcess {id: 'ch11-ldp-pe1'})
SET ldp.name = 'LDP pe-01', ldp.router_id = '10.11.255.1',
    ldp.status = 'degraded', ldp.dataset = 'vexpertai-design-ontology'
MERGE (lfib:MPLSForwardingTable:LFIB {id: 'ch11-lfib-pe1'})
SET lfib.name = 'pe-01 LFIB', lfib.state = 'partial',
    lfib.dataset = 'vexpertai-design-ontology'
MERGE (pe1)-[:PARTICIPATES_IN_MPLS]->(domain)
MERGE (p1)-[:PARTICIPATES_IN_MPLS]->(domain)
MERGE (pe1)-[:MEMBER_OF_MPLS_DOMAIN]->(domain)
MERGE (p1)-[:MEMBER_OF_MPLS_DOMAIN]->(domain)
MERGE (ldp)-[:MEMBER_OF_MPLS_DOMAIN]->(domain)
MERGE (pe1)-[:HAS_FORWARDING_TABLE]->(lfib);

// Scenario 1: VPN route and IGP reachability exist, but no label path is installed.
MERGE (service:MPLSService:MPLSL3VPN {id: 'ch11-service-payments-l3vpn'})
SET service.name = 'Payments MPLS L3VPN', service.service_type = 'MPLS L3VPN',
    service.status = 'blackholed', service.dataset = 'vexpertai-design-ontology'
MERGE (business:BusinessService {id: 'ch11-business-payments'})
SET business.name = 'Payments WAN', business.criticality = 'critical',
    business.dataset = 'vexpertai-design-ontology'
MERGE (lsp:LSP:MPLSLSP:LabelSwitchedPath {id: 'ch11-lsp-payments'})
SET lsp.name = 'pe-01 to pe-02 Payments LSP', lsp.state = 'no_label_path',
    lsp.dataset = 'vexpertai-design-ontology'
MERGE (route:VPNRoute {id: 'ch11-vpn-route-payments'})
SET route.name = 'Payments VPN Route', route.prefix = '10.11.10.0/24',
    route.state = 'present', route.dataset = 'vexpertai-design-ontology'
MERGE (prefix:Prefix {id: 'ch11-prefix-payments'})
SET prefix.name = 'Payments Prefix', prefix.cidr = '10.11.10.0/24',
    prefix.dataset = 'vexpertai-design-ontology'
MERGE (fec:FEC {id: 'ch11-fec-payments'})
SET fec.name = 'Payments 10.11.10.0/24 FEC', fec.state = 'unlabeled',
    fec.dataset = 'vexpertai-design-ontology'
MERGE (igp:IGPReachability {id: 'ch11-igp-payments'})
SET igp.name = 'IGP Reachability to Payments Egress', igp.state = 'up',
    igp.reason = 'OSPF route installed', igp.dataset = 'vexpertai-design-ontology'
MERGE (vrf:VRF {id: 'ch11-vrf-payments'})
SET vrf.name = 'PAYMENTS', vrf.status = 'up',
    vrf.dataset = 'vexpertai-design-ontology'
MERGE (rd:RouteDistinguisher {id: 'ch11-rd-payments'})
SET rd.name = 'RD 65011:10', rd.value = '65011:10',
    rd.dataset = 'vexpertai-design-ontology'
MERGE (rt:RouteTarget {id: 'ch11-rt-payments'})
SET rt.name = 'RT 65011:10', rt.value = '65011:10',
    rt.dataset = 'vexpertai-design-ontology'
MERGE (vpnv4:MPBGPVPNv4 {id: 'ch11-vpnv4-control'})
SET vpnv4.name = 'Provider VPNv4 Control Plane', vpnv4.state = 'up',
    vpnv4.dataset = 'vexpertai-design-ontology'
MERGE (vpnv6:MPBGPVPNv6 {id: 'ch11-vpnv6-control'})
SET vpnv6.name = 'Provider VPNv6 Control Plane', vpnv6.state = 'up',
    vpnv6.dataset = 'vexpertai-design-ontology'
MERGE (risk:MPLSRisk {id: 'ch11-risk-route-no-label'})
SET risk.name = 'VPN route has no label path', risk.severity = 'critical',
    risk.likelihood = 'high', risk.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'ch11-evidence-route-no-label'})
SET evidence.name = 'VPN RIB and LFIB comparison',
    evidence.summary = 'VPN route and IGP next hop exist, but no LFIB binding exists for the FEC.',
    evidence.source = 'summarized VPN RIB, IGP RIB, and LFIB',
    evidence.dataset = 'vexpertai-design-ontology'
MERGE (business)-[:DEPENDS_ON]->(service)
MERGE (service)-[:DEPENDS_ON]->(lsp)
MERGE (service)-[:HAS_TRANSPORT_LSP]->(lsp)
MERGE (service)-[:HAS_VPN_ROUTE]->(route)
MERGE (service)-[:DEPENDS_ON]->(vrf)
MERGE (service)-[:DEPENDS_ON]->(rd)
MERGE (service)-[:DEPENDS_ON]->(rt)
MERGE (service)-[:DEPENDS_ON]->(vpnv4)
MERGE (service)-[:DEPENDS_ON]->(vpnv6)
MERGE (route)-[:CARRIES_PREFIX]->(prefix)
MERGE (route)-[:TARGETS_VRF]->(vrf)
MERGE (fec)-[:FEC_FOR_PREFIX]->(prefix)
MERGE (prefix)-[:HAS_IGP_REACHABILITY]->(igp)
MERGE (service)-[:EXPOSES_MPLS_RISK]->(risk)
MERGE (risk)-[:IMPACTS]->(business)
MERGE (evidence)-[:SUPPORTS_MPLS_STATE]->(lsp);

// Scenario 2: LDP adjacency is down although IGP reachability remains up.
MERGE (service:MPLSService {id: 'ch11-service-branch-transport'})
SET service.name = 'Branch MPLS Transport', service.service_type = 'MPLS transport',
    service.status = 'down', service.dataset = 'vexpertai-design-ontology'
MERGE (business:BusinessService {id: 'ch11-business-branch-connectivity'})
SET business.name = 'Branch Connectivity', business.criticality = 'critical',
    business.dataset = 'vexpertai-design-ontology'
MERGE (lsp:LSP:MPLSLSP:LabelSwitchedPath {id: 'ch11-lsp-branch'})
SET lsp.name = 'pe-01 to branch-pe LSP', lsp.state = 'down_ldp',
    lsp.dataset = 'vexpertai-design-ontology'
MERGE (binding:LabelBinding {id: 'ch11-binding-branch'})
SET binding.name = 'Branch Transport Label Binding', binding.state = 'withdrawn',
    binding.dataset = 'vexpertai-design-ontology'
MERGE (label:Label {id: 'ch11-label-16011'})
SET label.name = 'Label 16011', label.value = 16011,
    label.dataset = 'vexpertai-design-ontology'
MERGE (fec:FEC {id: 'ch11-fec-branch-pe'})
SET fec.name = 'Branch PE Loopback FEC', fec.state = 'reachable',
    fec.dataset = 'vexpertai-design-ontology'
MERGE (adjacency:LDPAdjacency {id: 'ch11-ldp-adjacency-p1'})
SET adjacency.name = 'LDP pe-01 to p-01', adjacency.state = 'down',
    adjacency.peer = '10.11.255.2', adjacency.reason = 'TCP session reset',
    adjacency.dataset = 'vexpertai-design-ontology'
MERGE (igp:IGPReachability {id: 'ch11-igp-p1'})
SET igp.name = 'IGP Reachability to p-01', igp.state = 'up',
    igp.reason = 'OSPF adjacency full and loopback reachable',
    igp.dataset = 'vexpertai-design-ontology'
MERGE (overlay:ServiceOverlay {id: 'ch11-overlay-branch'})
SET overlay.name = 'Branch Service Overlay', overlay.state = 'down',
    overlay.dataset = 'vexpertai-design-ontology'
MERGE (underlay:TransportUnderlay {id: 'ch11-underlay-label-distribution'})
SET underlay.name = 'Provider Label Transport Underlay',
    underlay.state = 'label_distribution_down',
    underlay.dataset = 'vexpertai-design-ontology'
MERGE (sessionProtection:LDPSessionProtection {id: 'ch11-ldp-session-protection'})
SET sessionProtection.name = 'LDP Session Protection', sessionProtection.state = 'not_configured',
    sessionProtection.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'ch11-evidence-ldp-down'})
SET evidence.name = 'LDP and IGP state comparison',
    evidence.summary = 'IGP loopback reachability is up while LDP peer state is down.',
    evidence.source = 'summarized IGP and LDP neighbor state',
    evidence.dataset = 'vexpertai-design-ontology'
WITH service, business, lsp, binding, label, fec, adjacency, igp, overlay,
     underlay, sessionProtection, evidence
MATCH (ldp:LDP {id: 'ch11-ldp-pe1'})
MATCH (lfib:LFIB {id: 'ch11-lfib-pe1'})
MERGE (business)-[:DEPENDS_ON]->(service)
MERGE (service)-[:DEPENDS_ON]->(lsp)
MERGE (service)-[:DEPENDS_ON]->(overlay)
MERGE (service)-[:HAS_TRANSPORT_LSP]->(lsp)
MERGE (lsp)-[:DEPENDS_ON]->(binding)
MERGE (binding)-[:CREATED_BY]->(ldp)
MERGE (binding)-[:BINDS_LABEL]->(label)
MERGE (binding)-[:BINDS_FEC]->(fec)
MERGE (lfib)-[:CONTAINS_LABEL_BINDING]->(binding)
MERGE (ldp)-[:HAS_LDP_ADJACENCY]->(adjacency)
MERGE (adjacency)-[:DEPENDS_ON]->(igp)
MERGE (adjacency)-[:HAS_IGP_REACHABILITY]->(igp)
MERGE (overlay)-[:DEPENDS_ON]->(underlay)
MERGE (evidence)-[:SUPPORTS_MPLS_STATE]->(adjacency)
MERGE (evidence)-[:SUPPORTS_MPLS_STATE]->(underlay);

// Scenario 3: one VPN route imports correctly while another has an RT mismatch.
MERGE (vrf:VRF {id: 'ch11-vrf-customer-a'})
SET vrf.name = 'CUSTOMER-A', vrf.status = 'partial',
    vrf.dataset = 'vexpertai-design-ontology'
MERGE (importRT:RouteTarget {id: 'ch11-rt-customer-a-import'})
SET importRT.name = 'RT 65011:100', importRT.value = '65011:100',
    importRT.dataset = 'vexpertai-design-ontology'
MERGE (wrongRT:RouteTarget {id: 'ch11-rt-customer-a-wrong'})
SET wrongRT.name = 'RT 65011:200', wrongRT.value = '65011:200',
    wrongRT.dataset = 'vexpertai-design-ontology'
MERGE (goodRoute:VPNRoute {id: 'ch11-vpn-route-customer-a-good'})
SET goodRoute.name = 'Customer A Imported Route', goodRoute.prefix = '10.11.100.0/24',
    goodRoute.state = 'imported', goodRoute.dataset = 'vexpertai-design-ontology'
MERGE (badRoute:VPNRoute {id: 'ch11-vpn-route-customer-a-bad'})
SET badRoute.name = 'Customer A Missing Route', badRoute.prefix = '10.11.200.0/24',
    badRoute.state = 'not_imported', badRoute.dataset = 'vexpertai-design-ontology'
MERGE (service:MPLSService:MPLSL3VPN {id: 'ch11-service-customer-a'})
SET service.name = 'Customer A MPLS L3VPN', service.service_type = 'MPLS L3VPN',
    service.status = 'degraded', service.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'ch11-evidence-rt-mismatch'})
SET evidence.name = 'Route-target policy comparison',
    evidence.summary = 'Route 10.11.200.0/24 carries RT 65011:200 while CUSTOMER-A imports 65011:100.',
    evidence.source = 'summarized VPN route and VRF policy',
    evidence.dataset = 'vexpertai-design-ontology'
MERGE (vrf)-[:IMPORTS]->(importRT)
MERGE (importRT)-[:IMPORTS_VPN_ROUTE]->(goodRoute)
MERGE (importRT)-[:IMPORTS_INTO]->(vrf)
MERGE (goodRoute)-[:EXPORTED_WITH]->(importRT)
MERGE (goodRoute)-[:TARGETS_VRF]->(vrf)
MERGE (badRoute)-[:EXPORTED_WITH]->(wrongRT)
MERGE (badRoute)-[:TARGETS_VRF]->(vrf)
MERGE (service)-[:HAS_VPN_ROUTE]->(goodRoute)
MERGE (service)-[:HAS_VPN_ROUTE]->(badRoute)
MERGE (evidence)-[:SUPPORTS_MPLS_STATE]->(wrongRT);

// Scenario 4: VPWS pseudowire is down because targeted LDP signaling failed.
MERGE (service:MPLSService:MPLSL2VPN:VPWS {id: 'ch11-service-vpws'})
SET service.name = 'Data Center VPWS', service.service_type = 'VPWS',
    service.status = 'down', service.dataset = 'vexpertai-design-ontology'
MERGE (pseudowire:Pseudowire {id: 'ch11-pseudowire-dc'})
SET pseudowire.name = 'PW 1100 pe-01 to pe-02', pseudowire.state = 'down',
    pseudowire.vc_id = 1100, pseudowire.dataset = 'vexpertai-design-ontology'
MERGE (targeted:TargetedLDP {id: 'ch11-targeted-ldp-dc'})
SET targeted.name = 'Targeted LDP pe-01 to pe-02', targeted.state = 'down',
    targeted.reason = 'transport address unreachable',
    targeted.dataset = 'vexpertai-design-ontology'
MERGE (signaling:L2VPNSignaling {id: 'ch11-l2vpn-signaling-dc'})
SET signaling.name = 'VPWS Signaling', signaling.state = 'down',
    signaling.dataset = 'vexpertai-design-ontology'
MERGE (business:BusinessService {id: 'ch11-business-dc-interconnect'})
SET business.name = 'Data Center Layer 2 Interconnect', business.criticality = 'high',
    business.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'ch11-evidence-pseudowire'})
SET evidence.name = 'Pseudowire signaling state',
    evidence.summary = 'Attachment circuits are up, but targeted LDP and pseudowire signaling are down.',
    evidence.source = 'summarized pseudowire and targeted LDP state',
    evidence.dataset = 'vexpertai-design-ontology'
WITH service, pseudowire, targeted, signaling, business, evidence
MATCH (lsp:MPLSLSP {id: 'ch11-lsp-branch'})
MERGE (business)-[:DEPENDS_ON]->(service)
MERGE (service)-[:DEPENDS_ON]->(lsp)
MERGE (service)-[:HAS_PSEUDOWIRE]->(pseudowire)
MERGE (pseudowire)-[:DEPENDS_ON]->(targeted)
MERGE (pseudowire)-[:DEPENDS_ON]->(signaling)
MERGE (pseudowire)-[:USES_SIGNALING]->(targeted)
MERGE (pseudowire)-[:USES_SIGNALING]->(signaling)
MERGE (evidence)-[:SUPPORTS_MPLS_STATE]->(pseudowire);

// Scenario 5: RSVP-TE tunnel requires IGP TE extensions and has FRR protection.
MERGE (rsvp:RSVPTE:LabelDistributionProcess {id: 'ch11-rsvp-te'})
SET rsvp.name = 'Provider RSVP-TE', rsvp.state = 'up',
    rsvp.dataset = 'vexpertai-design-ontology'
MERGE (extensions:IGPTEExtensions {id: 'ch11-igp-te-extensions'})
SET extensions.name = 'OSPF TE Extensions', extensions.state = 'up',
    extensions.dataset = 'vexpertai-design-ontology'
MERGE (tunnel:TrafficEngineeringTunnel {id: 'ch11-te-tunnel-primary'})
SET tunnel.name = 'TE Tunnel pe-01 to pe-02', tunnel.state = 'up',
    tunnel.bandwidth_mbps = 500, tunnel.dataset = 'vexpertai-design-ontology'
MERGE (lsp:LSP:MPLSLSP:LabelSwitchedPath {id: 'ch11-lsp-te-primary'})
SET lsp.name = 'RSVP-TE Primary LSP', lsp.state = 'up',
    lsp.dataset = 'vexpertai-design-ontology'
MERGE (binding:LabelBinding {id: 'ch11-binding-te-primary'})
SET binding.name = 'RSVP-TE Label Binding', binding.state = 'installed',
    binding.dataset = 'vexpertai-design-ontology'
MERGE (label:Label {id: 'ch11-label-24001'})
SET label.name = 'RSVP Label 24001', label.value = 24001,
    label.dataset = 'vexpertai-design-ontology'
MERGE (frr:FastReroute:FastReroutePolicy {id: 'ch11-frr-link-protection'})
SET frr.name = 'RSVP-TE Link Protection', frr.state = 'armed',
    frr.dataset = 'vexpertai-design-ontology'
MERGE (php:PenultimateHopPopping {id: 'ch11-php'})
SET php.name = 'Penultimate Hop Popping', php.state = 'enabled',
    php.dataset = 'vexpertai-design-ontology'
MERGE (tunnel)-[:DEPENDS_ON]->(rsvp)
MERGE (tunnel)-[:DEPENDS_ON]->(extensions)
MERGE (lsp)-[:DEPENDS_ON]->(binding)
MERGE (binding)-[:CREATED_BY]->(rsvp)
MERGE (binding)-[:BINDS_LABEL]->(label)
MERGE (lsp)-[:ENGINEERED_BY]->(tunnel)
MERGE (frr)-[:PROTECTS]->(lsp)
MERGE (lsp)-[:PROTECTED_WITH]->(frr)
MERGE (lsp)-[:USES_PHP]->(php);

// Scenario 6: LDP-IGP synchronization holds IGP metric until labels converge.
MERGE (sync:LDPIGPSynchronization {id: 'ch11-ldp-igp-sync'})
SET sync.name = 'LDP-IGP Synchronization on p-01', sync.state = 'holding_igp_metric',
    sync.dataset = 'vexpertai-design-ontology'
MERGE (blackhole:TrafficBlackhole {id: 'ch11-blackhole-convergence'})
SET blackhole.name = 'Unlabeled Transit During Convergence',
    blackhole.state = 'prevented', blackhole.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'ch11-evidence-sync'})
SET evidence.name = 'LDP-IGP synchronization state',
    evidence.summary = 'IGP maximum metric remains advertised until required LDP labels install.',
    evidence.source = 'summarized IGP metric and LDP synchronization state',
    evidence.dataset = 'vexpertai-design-ontology'
WITH sync, blackhole, evidence
MATCH (ldp:LDP {id: 'ch11-ldp-pe1'})
MATCH (underlay:TransportUnderlay {id: 'ch11-underlay-label-distribution'})
MERGE (sync)-[:PREVENTS]->(blackhole)
MERGE (evidence)-[:SUPPORTS_MPLS_STATE]->(sync)
SET underlay.convergence_protection = 'LDP-IGP synchronization';
