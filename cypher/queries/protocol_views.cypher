// OSPF local view example.
MATCH path=(source)-[relationship]-(target)
WHERE source.dataset = 'vexpertai-design-ontology'
  AND toLower(coalesce(source.module, '')) = 'ospf'
  AND (toLower(coalesce(target.module, '')) = 'ospf'
       OR relationship.interaction IS NOT NULL)
RETURN path
LIMIT 250;

// BGP local view example.
MATCH path=(source)-[relationship]-(target)
WHERE source.dataset = 'vexpertai-design-ontology'
  AND toLower(coalesce(source.module, '')) = 'bgp'
  AND (toLower(coalesce(target.module, '')) = 'bgp'
       OR relationship.interaction IS NOT NULL)
RETURN path
LIMIT 250;
