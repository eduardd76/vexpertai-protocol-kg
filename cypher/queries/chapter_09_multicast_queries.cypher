// 1. Which receivers joined each multicast group?
MATCH (receiver:Receiver)-[:JOINS]->(group:MulticastGroup)
OPTIONAL MATCH (source:Source)-[:SENDS_TO]->(group)
RETURN group.group_address AS multicast_group,
       group.name AS group_name,
       collect(DISTINCT receiver.name) AS joined_receivers,
       collect(DISTINCT source.address) AS known_sources
ORDER BY multicast_group;

// 2. Which RP controls this multicast group?
MATCH (mapping:RPMapping)-[:MAPS_GROUP]->(group:MulticastGroup)
OPTIONAL MATCH (mapping)-[:MAPS_TO_RP]->(rp)
RETURN group.group_address AS multicast_group,
       mapping.name AS rp_mapping,
       mapping.state AS mapping_state,
       rp.name AS rendezvous_point,
       rp.address AS rp_address
ORDER BY multicast_group;

// 3. Which unicast route controls the RPF path?
MATCH (multicast_route:MulticastRoute)-[:HAS_RPF_CHECK]->(check:RPFCheck)
      -[:DEPENDS_ON]->(table:UnicastRoutingTable)
MATCH (check)-[:USES_UNICAST_ROUTE]->(unicast_route:UnicastRoute)
OPTIONAL MATCH (check)-[:USES_RPF_INTERFACE]->(rpf_interface:RPFInterface)
RETURN multicast_route.name AS multicast_route,
       check.state AS rpf_state,
       table.name AS unicast_table,
       unicast_route.prefix AS controlling_unicast_prefix,
       unicast_route.state AS unicast_route_state,
       rpf_interface.name AS selected_rpf_interface,
       check.reason AS rpf_reason;

// 4. Which multicast services are impacted by this PIM neighbor failure?
MATCH (service:BusinessService)-[:DEPENDS_ON]->(application:MulticastApplication)
      -[:DEPENDS_ON]->(group:MulticastGroup)
MATCH (route:MulticastRoute)-[:DEPENDS_ON]->(neighbor:PIMNeighbor)
WHERE route.group_address = group.group_address AND neighbor.state = 'down'
RETURN neighbor.name AS failed_pim_neighbor,
       neighbor.reason AS failure_reason,
       route.name AS lost_multicast_route,
       application.name AS impacted_application,
       service.name AS impacted_business_service,
       service.criticality AS criticality;

// 5. Which group is filtered by a multicast boundary?
MATCH (boundary:MulticastBoundary)-[filter:FILTERS]->(group:MulticastGroup)
OPTIONAL MATCH (application:MulticastApplication)-[:DEPENDS_ON]->(group)
OPTIONAL MATCH (service:BusinessService)-[:DEPENDS_ON]->(application)
RETURN boundary.name AS multicast_boundary,
       boundary.interface AS boundary_interface,
       coalesce(filter.action, boundary.action) AS action,
       group.group_address AS filtered_group,
       collect(DISTINCT application.name) AS affected_applications,
       collect(DISTINCT service.name) AS affected_services;

// 6. Which evidence indicates an RP, RPF, receiver-side, or PIM issue?
MATCH (evidence:Evidence)-[:SUPPORTS_MULTICAST_STATE]->(state)
WHERE state:RPMapping OR state:RPFCheck OR state:ReceiverMembership
   OR state:Receiver OR state:PIMNeighbor OR state:MulticastBoundary
RETURN evidence.issue_type AS issue_type,
       evidence.name AS evidence,
       evidence.summary AS observation,
       labels(state) AS supported_state_type,
       state.name AS supported_state,
       coalesce(state.state, state.status, state.action) AS state
ORDER BY issue_type;
