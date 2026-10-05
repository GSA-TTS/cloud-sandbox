---
title: 'Use provider-native managed Kubernetes for comparable sandbox clusters'
description: 'Proposed decision to broker minimal three-node EKS, GKE, and AKS clusters behind one normalized service contract and approval gate'
status: 'accepted'
tier: 1
date: '2026-10-05'
last_updated: '2026-10-05'
decision_makers:
  [
    'Cloud Sandbox maintainers',
    'Cloud Service Broker maintainers',
    'Security and ATO reviewers',
  ]
category: 'Deployment and Infrastructure'
nist_controls:
  [
    'AC-3',
    'AC-6',
    'AU-2',
    'AU-12',
    'CM-2',
    'CM-3',
    'CM-6',
    'RA-5',
    'SA-10',
    'SA-11',
    'SC-7',
    'SC-13',
    'SI-4',
  ]
impact_level: 'moderate'
ato_relevance: 'yes-boundary'
risk_treatment: 'mitigate'
related_files:
  [
    'docs/kubernetes/managed-kubernetes-broker-architecture.md',
    'docs/kubernetes/benchmark-protocol.md',
    'docs/aws/service-approval-review.md',
    'docs/gcp/approved-service-conditions.md',
    'docs/azure/service-approval-review.md',
  ]
---

# Use provider-native managed Kubernetes for comparable sandbox clusters

## Context and Problem Statement

The Cloud Sandbox needs a reproducible way to provision small Kubernetes clusters on AWS, Google Cloud, and Azure for portability, operations, security, cost, and performance evaluation. The design must expose a consistent Open Service Broker API contract without hiding provider-specific identity and networking behavior, and it must not deploy services that have not passed the repository's service-approval process.

## Decision Drivers

- Use provider-native managed control planes instead of operating Kubernetes control planes.
- Keep steady-state worker capacity comparable at three non-burstable, on-demand nodes near 2 vCPU and 8 GiB each.
- Preserve least privilege by returning short-lived or federated access instructions instead of static cluster-admin credentials.
- Enforce private worker networking, encrypted storage, control-plane audit logging, mandatory ownership labels, budget limits, and sandbox TTL.
- Produce provider-neutral lifecycle and benchmark outputs while retaining provider-specific implementation modules.
- Prevent architecture documentation from being interpreted as authorization to deploy an unapproved cloud service.

## Considered Options

1. **One portable self-managed Kubernetes distribution on virtual machines** - maximizes infrastructure similarity but creates an agency-operated control plane, patching burden, and a larger security boundary.
2. **Provider-native managed Kubernetes with one common broker contract** - uses EKS, GKE Standard, and AKS while normalizing lifecycle, bindings, metrics, and benchmark artifacts.
3. **One provider only** - minimizes implementation effort but cannot answer the cross-provider portability and benchmarking question.
4. **Serverless Kubernetes variants** - reduces node operations but cannot satisfy the requirement for an explicit, comparable three-node deployment.

## Decision Outcome

Chosen option: **Provider-native managed Kubernetes with one common broker contract**, because it delegates control-plane operations to each cloud provider while retaining a comparable three-node workload substrate and one auditable OSBAPI lifecycle.

The project owner approved an explicit MVP/sandbox demonstration exception on
2026-10-05 for implementation and time-limited live testing of EKS, GKE
Standard, and AKS. This acceptance does not change the underlying service-review
records and does not authorize production, CUI, PII, or persistent workloads.
Every live cluster still requires a reviewed command transcript, synthetic data,
an enforced TTL, a benchmark budget, and verified teardown.

### Positive Consequences

- Workloads receive a consistent binding contract across three clouds.
- Cloud-native identity, logging, networking, upgrade, and repair capabilities remain available.
- Benchmark results can distinguish provider control-plane behavior from worker and workload behavior.
- GKE can be implemented first without coupling its module to future EKS or AKS approval timelines.
- The historical EKS brokerpak can be reused for OSB lifecycle patterns without inheriting obsolete versions, long-lived bearer tokens, or add-on sprawl.

### Negative Consequences

- The three implementations cannot be identical because provider network, identity, version, and availability models differ.
- A fixed three-node cluster is not highly available enough for production conclusions.
- Private cluster administration requires an approved management path into each cloud network.
- Control-plane and logging charges may dominate small-cluster cost.
- The demonstration exception must not be represented as general service approval.

### Compliance Consequences

- The service-approval gate must run before catalog exposure and before live provisioning.
- Broker resources and benchmark artifacts must use synthetic, non-sensitive data only.
- Each cluster requires audit logging, private worker nodes, encrypted storage, required ownership/expiry tags, vulnerability assessment, and explicit deprovision verification.
- Binding credentials must not contain durable cloud keys, static Kubernetes bearer tokens, raw administrator kubeconfigs, or client private keys.
- The ATO boundary and system security plan must be updated before an approved cluster service is deployed.
- Benchmark outputs must redact account, subscription, project, cluster endpoint, billing, and network identifiers before publication.

## Implementation Sequence

1. Implement and statically validate all three provider broker services.
2. Review expected cloud resources, permissions, quotas, and maximum spend.
3. Provision one provider at a time with synthetic workloads and an enforced TTL.
4. Capture benchmark evidence and verify complete teardown before proceeding to the next provider.
5. Record separate service-approval decisions before any use outside the approved demonstration.

## Links

- [Managed Kubernetes broker architecture](../kubernetes/managed-kubernetes-broker-architecture.md)
- [Managed Kubernetes benchmark protocol](../kubernetes/benchmark-protocol.md)
- [GCP approved service conditions](../gcp/approved-service-conditions.md#google-kubernetes-engine)
- [AWS service approval review](../aws/service-approval-review.md)
- [Azure service approval review](../azure/service-approval-review.md)
- [GSA-TTS EKS brokerpak reference](https://github.com/GSA-TTS/datagov-brokerpak-eks)
