---
title: 'Managed Kubernetes Broker Architecture'
description: 'Provider-neutral OSBAPI architecture for minimal three-node EKS, GKE, and AKS sandbox clusters'
status: 'draft'
tier: 2
last_updated: '2026-10-05'
related_files:
  [
    'docs/adr/0002-managed-kubernetes-sandbox-brokers.md',
    'docs/kubernetes/benchmark-protocol.md',
    'docs/aws/service-approval-review.md',
    'docs/gcp/approved-service-conditions.md',
    'docs/azure/service-approval-review.md',
  ]
---

# Managed Kubernetes Broker Architecture

## Purpose

Define one lifecycle and binding contract for minimal, provider-native Kubernetes sandboxes on:

- Amazon Elastic Kubernetes Service (EKS)
- Google Kubernetes Engine Standard (GKE)
- Azure Kubernetes Service (AKS)

Each steady-state cluster has exactly three on-demand worker nodes near 2 vCPU and 8 GiB per node. The design is for non-production testing with synthetic data. It is not a production high-availability architecture.

## Authorization Gate

| Provider | Repository status                                             | Allowed action                                                                  |
| -------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| GKE      | FedRAMP Authorized High and Moderate, with sandbox conditions | Design, implement, review, and provision only after explicit live-test approval |
| EKS      | Denied/pending in current repository review                   | Design and static validation only                                               |
| AKS      | Not approved in current repository review                     | Design and static validation only                                               |

Broker plans must fail closed when the provider service is not approved. A service definition, module, or passing static test does not authorize provisioning.

## Design Principles

1. Use managed control planes and provider-native managed node pools.
2. Keep plan names, inputs, outputs, lifecycle states, labels, and benchmark metadata provider-neutral.
3. Keep cloud identity and network implementation provider-specific.
4. Do not return static cluster-admin credentials from bindings.
5. Create a namespace and least-privilege identity per binding.
6. Keep the baseline cluster small: no ingress controller, DNS automation, autoscaler, service mesh, scanner operator, or application-specific CRD.
7. Install optional capabilities through separate plans or post-provision profiles.
8. Verify deprovision by querying required ownership tags and failing when chargeable resources remain.

## Common Service Catalog

Each cloud brokerpak adds one service:

| Provider | Offering         | Provisioner family    |
| -------- | ---------------- | --------------------- |
| AWS      | `csb-aws-eks`    | `aws_eks_identity`    |
| GCP      | `csb-google-gke` | `google_gke_identity` |
| Azure    | `csb-azure-aks`  | `azure_aks_identity`  |

Initial plans:

| Plan                     | Purpose                                 | Nodes | Autoscaling                       | Add-ons                      |
| ------------------------ | --------------------------------------- | ----: | --------------------------------- | ---------------------------- |
| `sandbox-3-node`         | Minimal comparable cluster              |     3 | Disabled; min = desired = max = 3 | Provider system add-ons only |
| `sandbox-3-node-storage` | Adds comparable encrypted block storage |     3 | Disabled                          | CSI block-storage driver     |

Ingress, public load balancing, DNS, service mesh, GPU, spot nodes, and horizontal/vertical autoscaling are excluded from the initial plans.

## Common Provision Inputs

Operator-controlled fields are not exposed as tenant overrides unless explicitly approved.

| Field                | Type    | Default                                    | Policy                                 |
| -------------------- | ------- | ------------------------------------------ | -------------------------------------- |
| `location`           | string  | broker configuration                       | Operator allowlist only                |
| `kubernetes_version` | string  | validated release channel/version          | Operator controlled                    |
| `node_count`         | integer | `3`                                        | Fixed to 3 in initial plans            |
| `node_vcpu`          | integer | `2`                                        | Plan-defined                           |
| `node_memory_gib`    | integer | `8`                                        | Plan-defined                           |
| `ttl_hours`          | integer | `8`                                        | Maximum 12 without approval            |
| `api_access_cidrs`   | array   | broker configuration                       | Explicit allowlist; no `0.0.0.0/0`     |
| `private_endpoint`   | boolean | `true` when management connectivity exists | Fail closed if no approved access path |
| `storage_profile`    | string  | `none`                                     | `none` or `encrypted-block`            |
| `labels`             | object  | CF context plus required labels            | Broker controlled and merged           |

Required labels/tags:

- `Project`
- `Owner`
- `TTLExpiry`
- `CostCenter`
- `Cloud`
- `Environment`
- `Brokerpak`
- CF organization, space, service instance, and requesting identity identifiers where policy permits

## Common Provision Outputs

Provision returns metadata only:

```json
{
  "cluster_name": "string",
  "provider": "aws|gcp|azure",
  "location": "string",
  "kubernetes_version": "string",
  "node_count": 3,
  "node_shape": {
    "vcpu": 2,
    "memory_gib": 8,
    "provider_sku": "string"
  },
  "endpoint_mode": "private|allowlisted-public",
  "ttl_expires_at": "ISO-8601",
  "normalized_instance_json": "string"
}
```

Do not persist or return a reusable Kubernetes bearer token, cloud access key, client private key, or administrator kubeconfig.

## Common Bind Contract

Each bind creates:

- one DNS-safe namespace derived from the binding ID;
- Pod Security Admission labels at the restricted or approved baseline;
- ResourceQuota and LimitRange;
- default-deny ingress and egress NetworkPolicies with explicit DNS access;
- one provider-native identity grant scoped to that namespace where the provider supports it;
- namespace-scoped Kubernetes RBAC.

Normalized binding payload:

```json
{
  "version": "v1",
  "provider": "aws|gcp|azure",
  "provisioner_family": "aws_eks_identity|google_gke_identity|azure_aks_identity",
  "connection_type": "kubernetes",
  "cluster": {
    "name": "string",
    "location": "string",
    "endpoint_mode": "private|allowlisted-public",
    "server": "string|null",
    "certificate_authority_data": "string|null"
  },
  "access": {
    "mode": "aws_eks_exec|gcloud_exec|azure_kubelogin_exec",
    "namespace": "string",
    "expires_at": "ISO-8601|null"
  },
  "identity": {
    "principal": "provider identity reference",
    "role": "namespace-admin",
    "credential_inline": false
  },
  "commands": {
    "get_credentials": ["provider CLI command and arguments"],
    "verify": ["kubectl", "auth", "can-i", "--list", "--namespace", "namespace"]
  }
}
```

The command arrays are data, not shell strings. Consumers must execute them without string interpolation.

## Provider Profiles

### AWS EKS

Status: design-only pending service approval.

- One `aws_eks_cluster` using API-based access entries.
- One `aws_eks_node_group` with `min_size = desired_size = max_size = 3`.
- Candidate node class: a non-burstable general-purpose 2 vCPU / 8 GiB instance available in the approved region.
- Private nodes in at least two AZs; EKS requires multi-AZ cluster subnets.
- Private API endpoint when the broker and operators have VPC connectivity; otherwise enable private access and restrict public access to approved CIDRs.
- No SSH or remote-access block.
- Current managed EKS-optimized Bottlerocket or Amazon Linux image.
- Enable all control-plane log types with bounded retention.
- Use VPC CNI network policy; do not add Calico to the minimal plan.
- Use EKS Pod Identity for workloads and EKS access entries for human/CI access.
- Binding returns an IAM role/access-entry reference and an `aws eks get-token` exec-based kubeconfig recipe.
- EBS CSI is added only in the storage plan and uses a dedicated Pod Identity role.

Do not copy these historical EKS reference patterns:

- Kubernetes 1.21 or Terraform/OpenTofu 1.1 constraints;
- long-lived service-account token Secrets;
- shared `default` namespace bindings;
- broad AWS-managed full-access policies;
- caller IP discovery through external HTTP;
- old Calico, Starboard, Karpenter, in-tree EBS, or application-specific operators;
- fixed sleeps or ignored destroy failures.

### Google GKE

Status: first implementation candidate.

- GKE Standard, not Autopilot.
- One zonal `google_container_cluster` because the repository condition prohibits HA/multi-zone sandbox plans without separate approval.
- Remove the default node pool and create one `google_container_node_pool` with exactly three `e2-standard-2` nodes.
- Disable autoscaling and node auto-provisioning; keep auto-repair and auto-upgrade enabled.
- Use VPC-native networking and private nodes.
- Prefer the DNS endpoint with IAM or a private endpoint with an approved management path. If a public endpoint is necessary, restrict it with master authorized networks.
- Enable Workload Identity Federation for GKE.
- Use a dedicated node service account and least-privilege IAM.
- Enable Shielded Nodes and Dataplane V2/network policy when compatible with the selected release channel.
- Collect system and workload logs with bounded retention. Enable required Data Access audit logs at project or organization level.
- Use the Regular release channel with an explicit maintenance window.
- Binding returns project, location, cluster name, namespace, and a `gcloud container clusters get-credentials` recipe. It does not return a service-account key.

### Azure AKS

Status: design-only pending service approval.

- One `azurerm_kubernetes_cluster` with one three-node system pool.
- Candidate node class: `Standard_D2_v5` or an approved equivalent with 2 vCPU and 8 GiB.
- Disable autoscaling; disable node public IPs.
- Use managed identities for control plane and kubelet.
- Enable Microsoft Entra integration, OIDC issuer, and Workload Identity.
- Prefer private cluster access with an approved DNS and management path. Otherwise restrict the public API endpoint to authorized IP ranges.
- Use Azure CNI Overlay and Cilium when supported by the approved version/region.
- Use Standard Load Balancer, but do not create a public workload load balancer in the baseline plan.
- Enable control-plane diagnostics and Container Insights with bounded collection and retention.
- Use a supported GA Kubernetes minor, stable/patch upgrade channel, and NodeImage OS upgrades.
- Binding returns subscription/tenant references, resource group, cluster name, namespace, and an `az aks get-credentials` plus `kubelogin` recipe. It does not return `kube_config_raw` or local-account credentials.

## Network And Security Baseline

- TLS 1.2 or later for all endpoints.
- No public worker IPs.
- No unrestricted Kubernetes API CIDR.
- No default public `LoadBalancer` service.
- Default-deny namespace network policy.
- Restricted Pod Security Admission unless a documented benchmark exception requires baseline mode.
- `RuntimeDefault` seccomp, non-root containers, dropped capabilities, and no privilege escalation for benchmark workloads.
- Encrypted node disks and workload volumes.
- Provider-native audit logging and bounded retention.
- No durable cloud credentials in pod specifications, broker state outputs, or benchmark artifacts.

## Lifecycle And Failure Handling

Provision:

1. Validate service approval and provider location allowlists.
2. Validate quotas and budget.
3. Create network resources, identity, control plane, node pool, and required system add-ons.
4. Wait for exactly three Ready schedulable workers.
5. Capture inventory and health metadata.

Bind:

1. Create namespace and policy baseline.
2. Create provider identity and namespace RBAC.
3. Return metadata and exec-based authentication recipe.

Unbind:

1. Revoke provider identity/access entry.
2. Delete namespace workloads according to the persistent-volume policy.
3. Verify credentials can no longer authenticate.

Deprovision:

1. Reject while bindings remain.
2. Delete workload-created load balancers and volumes.
3. Delete optional add-ons, node pool, control plane, identity, network, logs, and keys in dependency order.
4. Query by instance tags and fail if chargeable resources remain.

Do not report success after a broker or provider timeout without verifying actual cloud state.

## Implementation Layout

Each brokerpak should follow its existing structure:

```text
<service-definition>.yml
terraform/<service>/provision/
  data.tf
  main.tf
  outputs.tf
  provider.tf
  variables.tf
terraform/<service>/bind/
  data.tf
  main.tf
  outputs.tf
  provider.tf
  variables.tf
```

The common contract is duplicated deliberately in provider-specific service definitions rather than introducing a shared runtime dependency between brokerpak repositories.

## Verification Gates

- Brokerpak build and `pak validate` pass with committed OpenTofu/provider versions.
- Temporary validation passes with the latest supported patch and next supported OpenTofu minor.
- Static policy rejects unapproved EKS/AKS plans.
- Provisioning tests verify exactly three Ready nodes.
- Bind tests verify namespace isolation and no cluster-wide privilege.
- Unbind tests verify access revocation.
- Deprovision tests verify zero tagged chargeable leftovers.
- Prowler/Kubernetes security checks produce no unaccepted critical or high findings.

## References

- [Proposed managed Kubernetes ADR](../adr/0002-managed-kubernetes-sandbox-brokers.md)
- [Benchmark protocol](benchmark-protocol.md)
- [EKS reference brokerpak](https://github.com/GSA-TTS/datagov-brokerpak-eks)
- [Amazon EKS documentation](https://docs.aws.amazon.com/eks/)
- [Google Kubernetes Engine documentation](https://cloud.google.com/kubernetes-engine/docs)
- [Azure Kubernetes Service documentation](https://learn.microsoft.com/azure/aks/)
