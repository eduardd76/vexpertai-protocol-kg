CREATE INDEX interaction_control_dependency_status IF NOT EXISTS FOR (n:ControlPlaneDependency) ON (n.status);
CREATE INDEX interaction_data_dependency_status IF NOT EXISTS FOR (n:DataPlaneDependency) ON (n.status);
CREATE INDEX interaction_incident_scenario IF NOT EXISTS FOR (n:Incident) ON (n.scenario);
CREATE INDEX interaction_change_external_id IF NOT EXISTS FOR (n:Change) ON (n.external_id);
