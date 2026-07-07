# Keep-these-open queries

Three queries worth saving as Neo4j Browser favorites. Run them during a real
incident or before a change window — they answer questions your CLI can't.

## 1. What breaks if a router fails?
(Change `abr-01` to the device you're touching.)

    MATCH (r {name:'abr-01'})-[:CONNECTS]->(area:OSPFArea)
    MATCH (prefix:Prefix)-[:ORIGINATES_IN]->(area)
    MATCH (prefix)-[:SUPPORTS]->(service:BusinessService)
    RETURN service.name AS at_risk_service, service.criticality AS criticality,
           collect(DISTINCT prefix.cidr) AS prefixes
    ORDER BY criticality;

## 2. What depends on this prefix?

    MATCH (prefix:Prefix {cidr:'10.30.10.0/24'})-[:SUPPORTS]->(service:BusinessService)
    RETURN service.name AS service, service.criticality AS criticality;

## 3. Blast radius of a change (rank areas by dependent services)

    MATCH (area:OSPFArea)<-[:ORIGINATES_IN]-(prefix:Prefix)-[:SUPPORTS]->(service:BusinessService)
    RETURN area.name AS area, count(DISTINCT service) AS services_at_risk
    ORDER BY services_at_risk DESC;
