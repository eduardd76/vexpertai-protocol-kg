// Beat 5 — the canonical shapes your network is made of. Reuse these patterns;
// your whole graph is these repeated. (Reference — the example at the bottom runs.)
//
//   (BusinessService)-[:DEPENDS_ON]->(Prefix)
//   (Prefix)-[:SUPPORTS]->(BusinessService)
//   (Prefix)-[:ORIGINATES_IN]->(OSPFArea)
//   (Prefix)-[:ADVERTISED_BY]->(LSA)-[:HAS_LSA_TYPE]->(LSAType)
//   (Device:OSPFRouter:ABR)-[:CONNECTS]->(OSPFArea)
//   (StubArea)-[:RESTRICTS]->(LSAType)
//   (ExternalRoute)-[:CARRIED_BY_LSA]->(LSA)
//
// Runnable example of the service->prefix->area shape (tagged so reset keeps it):
CREATE (svc:BusinessService {name:'Example Service', dataset:'vexpertai-builder'})
CREATE (p:Prefix {cidr:'198.51.100.0/24', dataset:'vexpertai-builder'})
CREATE (a:OSPFArea:NormalArea {area_id:'0.0.0.99', name:'Example Area', dataset:'vexpertai-builder'})
CREATE (p)-[:SUPPORTS]->(svc)
CREATE (p)-[:ORIGINATES_IN]->(a);
