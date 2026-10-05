---
title: 'Managed Kubernetes Benchmark Protocol'
description: 'Comparable metrics and benchmark methodology for minimal three-node EKS, GKE, and AKS sandbox clusters'
status: 'draft'
tier: 2
last_updated: '2026-10-05'
related_files:
  [
    'docs/adr/0002-managed-kubernetes-sandbox-brokers.md',
    'docs/kubernetes/managed-kubernetes-broker-architecture.md',
  ]
---

# Managed Kubernetes Benchmark Protocol

## Objective

Measure small-cluster behavior across EKS, GKE Standard, and AKS using identical synthetic workloads and a fixed three-node steady state. Results describe the tested cluster profiles; they do not establish a general ranking for larger or production clusters.

The benchmark may run only on providers approved for the selected environment. Until EKS and AKS approvals change, this protocol can be implemented and rehearsed on GKE but cannot produce a three-provider live comparison.

## Comparison Profiles

| Profile             | Purpose                            | Rule                                                                                                                       |
| ------------------- | ---------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `portable-baseline` | Isolate infrastructure differences | Match worker capacity, Kubernetes minor, workload resources, storage targets, and network exposure as closely as supported |
| `managed-default`   | Measure normal provider experience | Use documented provider defaults while retaining three fixed workers and identical workloads                               |

Do not mix profile results.

## Fairness Controls

- Exactly three Ready, schedulable, on-demand worker nodes.
- Target 2 vCPU and 8 GiB per node using non-burstable general-purpose classes.
- Same Kubernetes minor; provider patch versions are recorded.
- Same architecture and container runtime.
- Cluster autoscaler, HPA, VPA, serverless profiles, spot, and preemptible capacity disabled.
- Same application ResourceQuota based on the smallest observed allocatable capacity.
- Same immutable OCI image digests mirrored to a registry in each test region.
- Same synthetic data seed and workload order.
- Same storage size, filesystem, requested IOPS, and throughput where available.
- At least two independent external load-generator locations for public ingress tests.
- No upgrade, repair, or maintenance window during a measurement run.

Report both raw allocatable capacity and equal-budget workload results. Provider system add-ons consume different resources and are part of the managed-service operational cost.

## Metrics

| Category       | Metrics                                                                                                       |
| -------------- | ------------------------------------------------------------------------------------------------------------- |
| Provisioning   | cluster create duration, node-pool create duration, time to three Ready nodes, bind duration, delete duration |
| Kubernetes API | request success, p50/p95/p99 latency by verb/resource, HTTP 429 and 5xx rate                                  |
| Scheduling     | pod create-to-scheduled, create-to-started, create-to-Ready                                                   |
| HTTP           | successful requests/s, p50/p95/p99 latency, error rate, saturation point, recovery time                       |
| DNS            | cached/uncached queries/s, p50/p95/p99 latency, timeout and SERVFAIL rate                                     |
| Network        | same-node and cross-node throughput, RTT, jitter, loss, retransmits, CPU/Gbit                                 |
| Storage        | dynamic provisioning time, IOPS, MiB/s, p95/p99/p99.9 latency, detach/delete time                             |
| Reliability    | replacement pod time, worker drain impact, restored target throughput time                                    |
| Efficiency     | system CPU/memory tax, CPU-seconds and GiB-seconds per successful workload unit                               |
| Cost           | effective and list cost per cluster-hour and per million successful requests                                  |
| Security       | applicable passed checks, critical/high findings, exceptions, not-observable controls                         |

## Toolchain

Every tool and image must be pinned by exact version and digest/checksum in `toolchain.lock.yaml` before execution.

| Tool                          | Execution boundary | Purpose                                                 |
| ----------------------------- | ------------------ | ------------------------------------------------------- |
| kube-burner                   | External           | API, object churn, and scheduling tests                 |
| k6                            | External           | HTTP/TLS load generation                                |
| Fortio                        | In cluster         | Identical HTTP server and internal request measurements |
| Prometheus                    | In cluster         | Common cross-provider metrics collection                |
| kube-state-metrics            | In cluster         | Kubernetes object-state metrics                         |
| fio                           | In cluster         | Block-storage tests                                     |
| iperf3                        | In cluster         | Pod and node networking tests                           |
| dnsperf                       | In cluster         | Cluster DNS tests                                       |
| Kubescape                     | External           | Common Kubernetes configuration checks                  |
| Prowler                       | External           | Cloud and Kubernetes security evidence                  |
| Provider billing exports/APIs | External           | Actual cost reconciliation                              |

Do not use floating image tags, floating dependency ranges, or installation scripts downloaded and executed during a benchmark.

## Workload Suite

### W0: Idle Baseline

- Stabilize for 20 minutes.
- Measure idle behavior for 30 minutes.
- Capture system pod CPU/memory, node background activity, API watches, DNS traffic, restarts, events, observer overhead, and idle hourly cost.

### W1: API And Scheduler

- Create namespaces, ConfigMaps, and small Deployments at low and moderate concurrency.
- Scale deployments and delete all objects.
- Measure client-observed API latency, throttles/errors, scheduling timestamps, readiness timestamps, and deletion completion.

### W2: Stateless HTTP

Deploy three Fortio replicas with topology spread and fixed resource requests/limits.

| Phase    |       Duration |                        Load |
| -------- | -------------: | --------------------------: |
| Warm-up  |      5 minutes |   25 requests/s per replica |
| Low      |     10 minutes |   50 requests/s per replica |
| Target   |     20 minutes |  100 requests/s per replica |
| Stress   | 5-minute steps | Increase until an SLO fails |
| Recovery |     10 minutes |            Return to target |

Measure internal ClusterIP and external load-balancer paths separately.

### W3: Cluster DNS

- Query service, headless-service, cached external, and controlled uncached synthetic names.
- Measure throughput, latency, errors, and CoreDNS resources.
- Do not load arbitrary public DNS infrastructure.

### W4: Network

- Same-node pod-to-pod.
- Cross-node pod-to-pod.
- Pod-to-ClusterIP.
- External runner to load balancer.
- Test single-stream TCP, parallel TCP, controlled UDP, and small-message latency.

### W5: Storage

Use direct I/O against an encrypted block-storage PVC with a working set larger than node memory.

| Profile          | Block size | Queue depth | Mix              |
| ---------------- | ---------: | ----------: | ---------------- |
| Random read      |      4 KiB |          32 | 100% read        |
| Random write     |      4 KiB |          32 | 100% write       |
| Sequential read  |      1 MiB |          16 | 100% read        |
| Sequential write |      1 MiB |          16 | 100% write       |
| Database-like    |      8 KiB |          32 | 70/30 read/write |

### W6: Reversible Resilience

- Delete one application pod.
- Delete replicas one at a time.
- Cordon and drain one worker.
- Restore and uncordon the worker.
- Restart one CoreDNS replica at a time.

Do not manipulate managed control planes or use unapproved cloud fault injection.

### W7: Cold Image Pull

- Clear only through provider-supported node replacement or a fresh node/cluster profile.
- Record image pull, unpack, and pod readiness times separately.
- Use the same image bytes in provider-local registries.

## Candidate SLOs

| SLO                                |     Threshold |
| ---------------------------------- | ------------: |
| HTTP success at target load        |      >= 99.9% |
| Internal HTTP p95                  |     <= 100 ms |
| Internal HTTP p99                  |     <= 250 ms |
| External HTTP p99                  |     <= 500 ms |
| Kubernetes API operation success   |      >= 99.9% |
| Ordinary API CRUD p99              |  <= 2 seconds |
| Cached DNS success                 |     >= 99.99% |
| Cached DNS p99                     |      <= 20 ms |
| Pre-pulled pod create-to-Ready p95 | <= 10 seconds |
| Pod deletion recovery              | <= 60 seconds |
| Storage I/O errors                 |             0 |
| Telemetry completeness             |      >= 99.5% |
| Critical security findings         |             0 |
| High security findings             |  0 unaccepted |

A provider/profile that fails a mandatory workload SLO is ineligible for a performance rank for that workload.

## Statistical Method

- Run at least five measured repetitions per workload/provider/profile.
- Share one deterministic seed per repetition across providers.
- Randomize workload order with a recorded Latin square.
- Preserve failed runs and classify their status instead of deleting them.
- Report the median, each repetition, bootstrap 95% confidence intervals, and coefficient of variation.
- Calculate percentiles from raw observations, not percentiles of percentiles.
- Mark differences inconclusive when confidence intervals substantially overlap.

## Cost Boundary

Include:

- managed Kubernetes control-plane fee;
- three worker VMs and boot disks;
- persistent volumes;
- load balancers, public IPs, NAT, and cross-zone traffic;
- registry storage/transfer;
- log and metrics ingestion;
- security and benchmark infrastructure.

Publish both effective billed cost, excluding credits, and public on-demand list cost captured at run time. Billing results remain preliminary until delayed provider usage records are reconciled.

Derived metrics:

```text
cost_per_cluster_hour = run_cost / measured_cluster_hours
cost_per_million_requests = run_cost / successful_requests * 1_000_000
cost_per_1000_pods_ready = run_cost / ready_pods * 1_000
```

## Security Gate

Before and after each run, verify:

- private workers and restricted/private API endpoint;
- encrypted node and workload disks;
- audit logging and approved retention;
- workload identity with no static cloud credentials in pods;
- required tags and TTL;
- restricted Pod Security Admission;
- default-deny NetworkPolicy;
- non-root workloads, no privilege escalation, dropped capabilities, `RuntimeDefault` seccomp;
- least-privilege RBAC and disabled service-account token automount where unnecessary;
- immutable image digests and vulnerability scan results;
- no public dashboard, metrics endpoint, registry, or storage.

Classify each check as pass, applicable failure, accepted exception, provider-managed/not observable, not applicable, or tool error. Not observable is not a pass.

## Run Sequence

1. Confirm provider approval, region, account boundary, data classification, budget, and TTL.
2. Freeze the protocol, SLOs, toolchain lock, image lock, exclusions, and workload order.
3. Provision clusters through reviewed brokerpaks.
4. Capture inventory and provider settings.
5. Run the security preflight and stop on unaccepted critical/high findings.
6. Install pinned instrumentation with identical resource budgets.
7. Validate clocks and external load-generator headroom.
8. Stabilize, then execute W0-W7 in the recorded order.
9. Repeat at least five times.
10. Run the post-test security check.
11. Collect and later reconcile billing evidence.
12. Deprovision through OSBAPI and verify no tagged chargeable resources remain.
13. Validate, redact, checksum, and publish the result package.

## Artifact Layout

```text
benchmark-results/
  protocol/
    protocol.yaml
    toolchain.lock.yaml
    images.lock.yaml
    workload-order.csv
    slo.yaml
  inventory/
    eks.json
    gke.json
    aks.json
  raw/<run-id>/
    observations.ndjson
    events.ndjson
    prometheus/
    workload-output/
    security/
    billing/
  normalized/
    observations.parquet
    costs.parquet
    findings.parquet
  reports/
    summary.json
    scorecard.csv
    methodology.md
    limitations.md
  checksums.sha256
  provenance.json
```

Artifacts must not contain kubeconfigs, bearer tokens, cloud credentials, account/billing identifiers, internal hostnames, or unapproved network details.

## Normalized Observation

```json
{
  "schema_version": "1.0.0",
  "run_id": "timestamp-provider-repetition-workload",
  "protocol_digest": "sha256:...",
  "provider": "aws|gcp|azure",
  "service": "eks|gke-standard|aks",
  "cluster_profile": "portable-baseline|managed-default",
  "kubernetes_version": "string",
  "node_count": 3,
  "node_shape": {
    "vcpu_each": 2,
    "memory_gib_each": 8,
    "architecture": "amd64",
    "cpu_model": "recorded-at-runtime"
  },
  "workload": "w0|w1|w2|w3|w4|w5|w6|w7",
  "repetition": 1,
  "seed": 104729,
  "measurement_origin": "external|in-cluster|provider-native",
  "metric": "string",
  "statistic": "raw|count|mean|p50|p95|p99|p99.9|max",
  "value": 0,
  "unit": "string",
  "sample_count": 0,
  "window_start": "ISO-8601",
  "window_end": "ISO-8601",
  "status": "valid|failed_slo|invalid_instrumentation|provider_incident|operator_error|blocked",
  "exclusion_reason": null,
  "tool": {
    "name": "string",
    "version": "exact-version",
    "sha256": "sha256:..."
  }
}
```

## References

- [Managed Kubernetes broker architecture](managed-kubernetes-broker-architecture.md)
- [Proposed managed Kubernetes ADR](../adr/0002-managed-kubernetes-sandbox-brokers.md)
- [Kubernetes performance tests](https://github.com/kubernetes/perf-tests)
- [kube-burner](https://github.com/kube-burner/kube-burner)
- [Grafana k6](https://github.com/grafana/k6)
- [Fortio](https://github.com/fortio/fortio)
- [Prometheus](https://prometheus.io/)
- [OpenCost](https://www.opencost.io/)
- [Kubescape](https://github.com/kubescape/kubescape)
- [Prowler](https://github.com/prowler-cloud/prowler)
