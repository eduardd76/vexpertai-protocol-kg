// Beat 4 — repair abr-01's backbone link, then re-run 02_blast_radius.cypher.
MATCH (abr:ABR {name:'abr-01'})-[c:CONNECTS]->(a0:OSPFArea {area_id:'0.0.0.0'})
SET c.state = 'up', abr.status = 'up'
RETURN abr.name AS abr, abr.status AS status, c.state AS backbone_link;

// Beat 4 — break it again, then re-run 02_blast_radius.cypher. Order API returns.
MATCH (abr:ABR {name:'abr-01'})-[c:CONNECTS]->(a0:OSPFArea {area_id:'0.0.0.0'})
SET c.state = 'down', abr.status = 'down'
RETURN abr.name AS abr, abr.status AS status, c.state AS backbone_link;
