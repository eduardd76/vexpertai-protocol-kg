# Chapter 2 Network Design Tools and Best Practices

This ontology makes design reasoning traceable from business need through
migration validation. It models why a design was chosen, what it violates, what
risk it accepts, and how the transition remains recoverable.

## Requirements and priority

`Requirement` is the common query label. Business, technical, availability,
scalability, convergence, security, operational, and monitoring requirements
add more specific meaning. A `BusinessCriticality` node explains priority
instead of treating priority as an unexplained number.

Requirements include acceptance criteria. They describe intended outcomes, not
device configuration.

## Options, constraints, and decisions

A `DesignOption` can:

- `SATISFIES` one or more requirements;
- `VIOLATES` cost, skill, hardware, or general constraints;
- have an explicit `Tradeoff`;
- depend on an `Assumption`;
- expose a `Risk`.

A `DesignDecision` `CHOOSES` an option and records its rationale. Accepted risk
is linked with `CREATES_RISK`, while a `Control` provides explicit mitigation.
This preserves considered options rather than storing only the winning answer.

## Migration safety

`MigrationPlan` contains ordered `MigrationStep` nodes. A step depends on its
prerequisite and can have a tested `RollbackPlan`. The model flags execution
when a prerequisite has not been validated or no tested rollback exists.

`TechnologyReplacement` requires a `CoexistencePlan` in a brownfield network.
The old and new protocol can therefore be reasoned about during the transition,
not only at the target state.

## Organizational change

`MergerDesign` requires a `RoutingIntegrationPlan` that identifies existing
protocols and exchange policy. `DivestmentDesign`, `BrownfieldNetwork`, and
`GreenfieldNetwork` make organizational and inherited-state context explicit.

## Monitoring and operational complexity

A `TechnologyAddition` impacts an `ExistingProtocol`, adds a
`ProtocolFeature`, and can increase `OperationalComplexity`.
`MonitoringRequirement` covers the added feature with named signals. This
connects design change to operational readiness before deployment.
