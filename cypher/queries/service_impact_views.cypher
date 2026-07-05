// Payment-App end-to-end service dependency.
MATCH path=(dependency)-[:SUPPORTS_LAYER*1..12]->
      (service:BusinessService {id: 'view-service-payment'})
RETURN path;

// Ethernet1/49 failure propagation.
MATCH path=(interface:Interface {id: 'view-interface-ethernet1-49'})
      -[:SUPPORTS_LAYER*1..12]->(service:BusinessService)
RETURN path;
