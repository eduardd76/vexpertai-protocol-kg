// FHRP to OSPF interaction.
MATCH path=(source)-[relationship]-(target)
WHERE relationship.interaction = 'fhrp-ospf'
RETURN path;

// OSPF to BGP interaction.
MATCH path=(source)-[relationship]-(target)
WHERE relationship.interaction = 'ospf-bgp'
RETURN path;

// BGP to MPLS interaction.
MATCH path=(source)-[relationship]-(target)
WHERE relationship.interaction = 'bgp-mpls'
RETURN path;
