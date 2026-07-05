# Ontology YAML Format

Each ontology file is an independently readable design domain. The loader
merges all documents and validates references across files. This allows a
chapter domain to use shared core concepts without repeating their definitions.

Every file contains:

- `ontology`: stable ID, title, version, and scope description.
- `node_labels`: semantic object names and original descriptions.
- `properties`: typed properties by label. `*` defines common properties.
- `relationship_types`: allowed source labels, target labels, and meaning.
- `constraints`: unique constraints or indexes that generate Neo4j DDL.
- `dependency_rules`: required semantic paths with a rationale.
- `risk_rules`: conditions, severity, and expected response.
- `validation_queries`: Cypher assertions that detect design gaps.
- `example_scenarios`: small original examples showing intended use.

Example:

```yaml
node_labels:
  DesignDecision: Selected approach with rationale.

properties:
  DesignDecision:
    rationale: {type: string, required: true}

relationship_types:
  INTRODUCES_RISK:
    from: [DesignDecision]
    to: [DesignRisk]
    description: Decision creates or increases a risk.

dependency_rules:
  - id: decision-risk
    source: DesignDecision
    relationship: INTRODUCES_RISK
    target: [DesignRisk]
    rationale: Material design risk must be visible.
```

`src/validation.py` rejects unknown labels, unknown relationships, incompatible
dependency endpoints, unsupported constraint types, and incomplete risk or
validation rules. `src/schema_generator.py` converts declared unique
constraints and indexes into idempotent Cypher.

The YAML is a semantic design model, not a device configuration schema. Raw
routes, MAC addresses, telemetry samples, and logs remain in their source
systems.
