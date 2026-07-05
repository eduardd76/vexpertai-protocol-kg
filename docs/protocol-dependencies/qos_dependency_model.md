# QoS Dependency Model

## Application-to-policy treatment

```text
ApplicationTraffic -> ClassMap -> QoSClass -> DSCP / CoS
                           |
                       QoSPolicy -> Interface
```

Correct marking alone does not prove enforcement. The policy must also be
attached to the intended interface and direction.

## Scheduler treatment

```text
QoSClass -> InterfaceQueue
                |
         QueuingPolicy -> BandwidthGuarantee
                |
       PolicingPolicy / ShapingPolicy / WRED
```

Policing enforces a rate through drop or remark behavior. Shaping buffers
bursts. Queue scheduling allocates constrained link capacity. These controls
remain separate so root cause is not reduced to a generic “QoS problem.”

## Voice protection and starvation

```text
PriorityQueue -> VoiceTraffic
       |
 PolicingPolicy
       |
remaining bandwidth -> other TrafficClass
```

Priority treatment reduces delay only when priority traffic is bounded. An
overly permissive policer can consume capacity promised to other classes and
cause queue drops.

## SLA correlation

```text
BusinessService -> SLARequirement -> QoSClass
                         ^
                  SLAViolation
                         ^
                  CongestionEvent -> InterfaceQueue
                         ^
                      Evidence
```

This path correlates a measured violation with queue congestion and service
impact while raw interface counters and SLA samples remain in telemetry
systems.

## When QoS is unnecessary

```text
QoSDesignAssessment -> WANLink
       capacity + measured utilization
```

If a link has sustained headroom and no differentiated performance
requirement, additional classes and policies add operational complexity
without solving a constrained-resource problem.
