// Scenario 1: IPsec is established, but routing across the tunnel is down.
MERGE (hq:Site {id: 'ch6-site-hq'})
SET hq.name = 'Headquarters', hq.dataset = 'vexpertai-design-ontology'
MERGE (branch:Site {id: 'ch6-site-branch'})
SET branch.name = 'Branch 42', branch.dataset = 'vexpertai-design-ontology'
MERGE (underlay:UnderlayTransport {id: 'ch6-underlay-internet'})
SET underlay.name = 'Business Internet Underlay', underlay.transport_type = 'Internet',
    underlay.status = 'up', underlay.dataset = 'vexpertai-design-ontology'
MERGE (vpn:VPNService:SiteToSiteVPN {id: 'ch6-vpn-hq-branch'})
SET vpn.name = 'HQ-to-Branch Site VPN', vpn.vpn_type = 'site-to-site IPsec',
    vpn.status = 'impacted', vpn.dataset = 'vexpertai-design-ontology'
MERGE (tunnel:OverlayTunnel:IPsecTunnel {id: 'ch6-ipsec-hq-branch'})
SET tunnel.name = 'HQ-Branch IPsec Tunnel', tunnel.crypto_state = 'up',
    tunnel.status = 'degraded', tunnel.dataset = 'vexpertai-design-ontology'
MERGE (ike:IKEPolicy {id: 'ch6-ike-policy-main'})
SET ike.name = 'IKEv2 AES256 Policy', ike.version = 'IKEv2',
    ike.dataset = 'vexpertai-design-ontology'
MERGE (crypto:CryptoMap {id: 'ch6-crypto-map-main'})
SET crypto.name = 'CMAP-HQ-BRANCH', crypto.sequence = 10,
    crypto.dataset = 'vexpertai-design-ontology'
MERGE (tunnelIf:TunnelInterface {id: 'ch6-tunnel-interface-100'})
SET tunnelIf.name = 'Tunnel100', tunnelIf.status = 'up',
    tunnelIf.dataset = 'vexpertai-design-ontology'
MERGE (domain:EncryptionDomain {id: 'ch6-domain-hq-branch'})
SET domain.name = 'HQ 10.6.0.0/16 to Branch 10.42.0.0/16',
    domain.local_selector = '10.6.0.0/16', domain.remote_selector = '10.42.0.0/16',
    domain.status = 'matched', domain.dataset = 'vexpertai-design-ontology'
MERGE (ikeState:IKEState {id: 'ch6-ike-state-hq-branch'})
SET ikeState.name = 'HQ-Branch IKE State', ikeState.state = 'up',
    ikeState.dataset = 'vexpertai-design-ontology'
MERGE (routingState:RoutingState {id: 'ch6-routing-state-hq-branch'})
SET routingState.name = 'HQ-Branch Routing State', routingState.state = 'down',
    routingState.reason = 'remote prefix absent',
    routingState.dataset = 'vexpertai-design-ontology'
MERGE (health:TunnelHealth {id: 'ch6-health-hq-branch'})
SET health.name = 'HQ-Branch Tunnel Health', health.status = 'degraded',
    health.dataset = 'vexpertai-design-ontology'
MERGE (vpn)-[:CONNECTS]->(hq)
MERGE (vpn)-[:CONNECTS]->(branch)
MERGE (vpn)-[:DEPENDS_ON]->(underlay)
MERGE (vpn)-[:HAS_TUNNEL]->(tunnel)
MERGE (vpn)-[:HAS_HEALTH]->(health)
MERGE (tunnel)-[:DEPENDS_ON]->(ike)
MERGE (tunnel)-[:PROTECTS]->(domain)
MERGE (tunnel)-[:HAS_STATE]->(ikeState)
MERGE (tunnel)-[:HAS_STATE]->(routingState)
MERGE (tunnel)-[:HAS_HEALTH]->(health)
MERGE (health)-[:DEPENDS_ON]->(ikeState)
MERGE (health)-[:DEPENDS_ON]->(routingState)
MERGE (crypto)-[:USES_IKE_POLICY]->(ike)
MERGE (crypto)-[:HAS_ENCRYPTION_DOMAIN]->(domain)
MERGE (vpn)-[:HAS_TUNNEL]->(tunnelIf);

MERGE (app:Application {id: 'ch6-app-erp'})
SET app.name = 'Branch ERP Client', app.status = 'unreachable',
    app.dataset = 'vexpertai-design-ontology'
MERGE (service:BusinessService {id: 'ch6-service-erp'})
SET service.name = 'Enterprise Resource Planning', service.criticality = 'critical',
    service.dataset = 'vexpertai-design-ontology'
MERGE (ikeEvidence:Evidence {id: 'ch6-evidence-ike-up'})
SET ikeEvidence.name = 'IKE and IPsec security associations established',
    ikeEvidence.summary = 'IKEv2 and child security associations are active in both directions.',
    ikeEvidence.source = 'vpn-state://hq-branch/ipsec',
    ikeEvidence.dataset = 'vexpertai-design-ontology'
MERGE (routeEvidence:Evidence {id: 'ch6-evidence-route-missing'})
SET routeEvidence.name = 'Remote branch route missing',
    routeEvidence.summary = '10.42.0.0/16 is absent from the tunnel routing table.',
    routeEvidence.source = 'rib-summary://hq/Tunnel100',
    routeEvidence.dataset = 'vexpertai-design-ontology'
WITH app, service, ikeEvidence, routeEvidence
MATCH (vpn:VPNService {id: 'ch6-vpn-hq-branch'}),
      (ikeState:IKEState {id: 'ch6-ike-state-hq-branch'}),
      (routingState:RoutingState {id: 'ch6-routing-state-hq-branch'})
MERGE (app)-[:DEPENDS_ON]->(vpn)
MERGE (service)-[:DEPENDS_ON]->(app)
MERGE (service)-[:CONSUMES_VPN]->(vpn)
MERGE (ikeEvidence)-[:SUPPORTS_STATE]->(ikeState)
MERGE (routeEvidence)-[:SUPPORTS_STATE]->(routingState);

// Scenario 2: MPLS L3VPN route-target export has no matching import.
MERGE (l3vpn:VPNService:MPLSL3VPN {id: 'ch6-mpls-l3vpn-prod'})
SET l3vpn.name = 'Production MPLS L3VPN', l3vpn.vpn_type = 'MPLS L3VPN',
    l3vpn.status = 'degraded', l3vpn.dataset = 'vexpertai-design-ontology'
MERGE (vrfHq:VRF {id: 'ch6-vrf-prod-hq'})
SET vrfHq.name = 'PROD-HQ', vrfHq.dataset = 'vexpertai-design-ontology'
MERGE (vrfBranch:VRF {id: 'ch6-vrf-prod-branch'})
SET vrfBranch.name = 'PROD-BRANCH', vrfBranch.dataset = 'vexpertai-design-ontology'
MERGE (exportTarget:RouteTarget:VPNRouteTarget {id: 'ch6-rt-65000-100'})
SET exportTarget.name = 'RT 65000:100', exportTarget.value = '65000:100',
    exportTarget.dataset = 'vexpertai-design-ontology'
MERGE (wrongImport:RouteTarget:VPNRouteTarget {id: 'ch6-rt-65000-200'})
SET wrongImport.name = 'RT 65000:200', wrongImport.value = '65000:200',
    wrongImport.dataset = 'vexpertai-design-ontology'
MERGE (rd:RouteDistinguisher {id: 'ch6-rd-65000-100'})
SET rd.name = 'RD 65000:100', rd.value = '65000:100',
    rd.dataset = 'vexpertai-design-ontology'
MERGE (mpbgp:MPBGP {id: 'ch6-mpbgp-vpnv4'})
SET mpbgp.name = 'MP-BGP VPNv4', mpbgp.status = 'up',
    mpbgp.dataset = 'vexpertai-design-ontology'
MERGE (route:VPNRoute {id: 'ch6-vpn-route-10.42.0.0-16'})
SET route.name = 'VPN Route 10.42.0.0/16', route.cidr = '10.42.0.0/16',
    route.status = 'not_imported', route.dataset = 'vexpertai-design-ontology'
MERGE (risk:VPNRisk:AsymmetricRoutingRisk {id: 'ch6-risk-asymmetric-rt'})
SET risk.name = 'Route-target mismatch creates asymmetric reachability',
    risk.severity = 'critical', risk.likelihood = 'high',
    risk.dataset = 'vexpertai-design-ontology'
MERGE (l3vpn)-[:USES]->(vrfHq)
MERGE (l3vpn)-[:USES]->(vrfBranch)
MERGE (l3vpn)-[:USES]->(exportTarget)
MERGE (l3vpn)-[:USES]->(rd)
MERGE (l3vpn)-[:USES]->(mpbgp)
MERGE (vrfHq)-[:EXPORTS]->(exportTarget)
MERGE (vrfBranch)-[:IMPORTS]->(wrongImport)
MERGE (route)-[:IMPORTED_BY]->(exportTarget)
MERGE (l3vpn)-[:EXPOSES_VPN_RISK]->(risk);

// Scenario 3: DMVPN NHRP failure prevents spoke-to-spoke reachability.
MERGE (dmvpn:VPNService:DMVPN {id: 'ch6-dmvpn-wan'})
SET dmvpn.name = 'Enterprise DMVPN', dmvpn.vpn_type = 'DMVPN Phase 3',
    dmvpn.status = 'impacted', dmvpn.dataset = 'vexpertai-design-ontology'
MERGE (gre:GRE {id: 'ch6-gre-dmvpn'})
SET gre.name = 'mGRE Tunnel', gre.status = 'up',
    gre.dataset = 'vexpertai-design-ontology'
MERGE (nhrp:NHRP {id: 'ch6-nhrp-dmvpn'})
SET nhrp.name = 'DMVPN NHRP Resolution', nhrp.status = 'broken',
    nhrp.reason = 'spoke registration expired',
    nhrp.dataset = 'vexpertai-design-ontology'
MERGE (ipsec:IPsecTunnel {id: 'ch6-ipsec-dmvpn'})
SET ipsec.name = 'DMVPN IPsec Protection', ipsec.crypto_state = 'up',
    ipsec.dataset = 'vexpertai-design-ontology'
MERGE (hub:Hub {id: 'ch6-dmvpn-hub'})
SET hub.name = 'DMVPN Hub', hub.dataset = 'vexpertai-design-ontology'
MERGE (spoke1:Spoke {id: 'ch6-dmvpn-spoke-01'})
SET spoke1.name = 'DMVPN Spoke 01', spoke1.dataset = 'vexpertai-design-ontology'
MERGE (spoke2:Spoke {id: 'ch6-dmvpn-spoke-02'})
SET spoke2.name = 'DMVPN Spoke 02', spoke2.dataset = 'vexpertai-design-ontology'
MERGE (dmvpn)-[:USES]->(gre)
MERGE (dmvpn)-[:USES]->(nhrp)
MERGE (dmvpn)-[:USES]->(ipsec)
MERGE (dmvpn)-[:HAS_ENDPOINT]->(hub)
MERGE (dmvpn)-[:HAS_ENDPOINT]->(spoke1)
MERGE (dmvpn)-[:HAS_ENDPOINT]->(spoke2);

// Scenario 4: failover route exists, but failed SLA prevents activation.
MERGE (policy:VPNFailoverPolicy {id: 'ch6-failover-hq-branch'})
SET policy.name = 'HQ-Branch VPN Failover', policy.status = 'not_triggered',
    policy.dataset = 'vexpertai-design-ontology'
MERGE (sla:VPNSLA {id: 'ch6-sla-hq-branch'})
SET sla.name = 'Branch Tunnel Reachability SLA', sla.status = 'failed',
    sla.target = '10.42.0.1', sla.dataset = 'vexpertai-design-ontology'
MERGE (route:VPNRoute {id: 'ch6-failover-route-branch'})
SET route.name = 'Branch Backup Route', route.cidr = '10.42.0.0/16',
    route.status = 'available_not_installed',
    route.dataset = 'vexpertai-design-ontology'
WITH policy, sla, route
MATCH (vpn:VPNService {id: 'ch6-vpn-hq-branch'})
MERGE (policy)-[:TRACKS]->(sla)
MERGE (policy)-[:HAS_FAILOVER_ROUTE]->(route)
MERGE (policy)-[:PROTECTS]->(vpn);

// Scenario 5: application selectors do not match the negotiated domain.
MERGE (mismatch:EncryptionDomain {id: 'ch6-domain-mismatch'})
SET mismatch.name = 'Mismatched ERP Encryption Domain',
    mismatch.local_selector = '10.6.0.0/16',
    mismatch.remote_selector = '10.99.0.0/16',
    mismatch.required_remote_selector = '10.42.0.0/16',
    mismatch.status = 'mismatch', mismatch.dataset = 'vexpertai-design-ontology'
MERGE (risk:VPNRisk:EncryptionDomainRisk {id: 'ch6-risk-encryption-domain'})
SET risk.name = 'ERP traffic excluded from encryption domain',
    risk.severity = 'critical', risk.likelihood = 'high',
    risk.dataset = 'vexpertai-design-ontology'
MERGE (evidence:Evidence {id: 'ch6-evidence-selector-mismatch'})
SET evidence.name = 'IPsec selector mismatch',
    evidence.summary = 'Negotiated remote selector is 10.99.0.0/16; ERP requires 10.42.0.0/16.',
    evidence.source = 'vpn-debug://hq-branch/selectors',
    evidence.dataset = 'vexpertai-design-ontology'
WITH mismatch, risk, evidence
MATCH (tunnel:IPsecTunnel {id: 'ch6-ipsec-hq-branch'}),
      (service:BusinessService {id: 'ch6-service-erp'})
MERGE (tunnel)-[:PROTECTS]->(mismatch)
MERGE (mismatch)-[:EXPOSES_VPN_RISK]->(risk)
MERGE (risk)-[:IMPACTS]->(service)
MERGE (evidence)-[:SUPPORTS_STATE]->(mismatch);

// Additional remote-access and NAT traversal concepts.
MERGE (remote:VPNService:RemoteAccessVPN {id: 'ch6-remote-access'})
SET remote.name = 'Employee Remote Access', remote.vpn_type = 'remote-access',
    remote.status = 'up', remote.dataset = 'vexpertai-design-ontology'
MERGE (split:SplitTunnelPolicy {id: 'ch6-split-policy'})
SET split.name = 'Corporate Prefix Split Tunnel',
    split.dataset = 'vexpertai-design-ontology'
MERGE (nat:NATTraversal {id: 'ch6-nat-traversal'})
SET nat.name = 'IPsec NAT-T UDP 4500', nat.status = 'enabled',
    nat.dataset = 'vexpertai-design-ontology'
WITH remote, split, nat
MATCH (tunnel:IPsecTunnel {id: 'ch6-ipsec-hq-branch'})
MERGE (remote)-[:APPLIES_SPLIT_POLICY]->(split)
MERGE (tunnel)-[:USES_NAT_TRAVERSAL]->(nat);
