# Cloud Sandbox — Sandbox Lifecycle & Cost Governance

[![GSA](https://img.shields.io/badge/GSA-TTS-blue)](https://tts.gsa.gov)
[![FedRAMP](https://img.shields.io/badge/FedRAMP-Moderate-green)](https://cloud.gov)
[![OSCAL](https://img.shields.io/badge/OSCAL-Maintained-brightgreen)](content/)
[![License](https://img.shields.io/github/license/GSA-TTS/cloud-sandbox)](LICENSE.md)

> Automated multi-cloud sandbox provisioning with 8-hour deprovisioning, budget
> enforcement, and lifecycle observability for **AWS · GCP · Azure** on cloud.gov.
>
> **General Services Administration · Technology Transformation Services** — Draft · April 2026

---

## Executive Summary

TTS engineers require fast, self-service access to AWS, GCP, and Azure environments for
experimentation — but sandbox sprawl creates budget overruns, compliance risk, and untagged
orphan resources. This repository implements a lifecycle management architecture built on the
[Cloud Foundry Cloud Service Broker (CSB)](https://github.com/cloudfoundry/csb-brokerpak-aws)
that provisions multi-cloud service packs through brokerpaks, enforces an automatic
**8-hour deprovisioning TTL**, and integrates cost telemetry to stay within the **$500/month**
sandbox budget ceiling mandated by TTS Infrastructure policy.

### Key Outcomes

| Outcome | Detail |
|---------|--------|
| **Zero idle spend** | Sandbox instances auto-deprovision after 8 hours; one 4-hour renewal permitted |
| **Budget guardrails** | Hard $500/mo ceiling with 80%/100% alert thresholds and automated service suspension |
| **Audit-ready tagging** | All resources tagged: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment` |
| **Self-service provisioning** | Engineers use standard `cf` CLI; no IAM access or cloud console required |
| **FedRAMP alignment** | Inherits cloud.gov FedRAMP Moderate controls; OSCAL-maintained per service broker |
| **Security baseline** | Prowler continuous scanning of all three CSP accounts for CIS/FedRAMP hardening |

---

## Repository Structure

```
.
├── submodules/
│   ├── csb-brokerpak-aws/     # AWS brokerpak (OpenTofu modules + service definitions)
│   ├── csb-brokerpak-azure/   # Azure brokerpak
│   ├── csb-brokerpak-gcp/     # GCP brokerpak
│   └── prowler/               # Third-party CSP continuous assessment & scanning
├── content/
│   └── oscal_*.json           # OSCAL schemas: SSP, catalog, profile, component, assessment
├── src/
│   ├── oscal/                 # OSCAL TypeScript models and GraphQL schema
│   └── pages/                 # Gatsby pages including per-OSCAL-document views
└── .github/
    └── agents/
        ├── cloud-service-brokers.md  # Copilot agent: CSB lifecycle & governance
        ├── oscal.md                  # Copilot agent: OSCAL content maintenance
        └── opentofu.md               # Copilot agent: OpenTofu module authoring
```

---

## Architecture

| Layer | Component | Responsibility |
|-------|-----------|----------------|
| **Provisioning** | CSB + aws/gcp/azure-brokerpak | Create, bind, update, delete service instances via OpenTofu |
| **Governance** | TTL Controller (CF cron task) | Tag at creation; poll for expired instances; `cf delete-service` |
| **Cost Observability** | AWS Budgets / GCP Budget API / Azure Cost Management | Spending alerts at 50%, 80%, 100% thresholds |
| **Secrets** | CredHub (cloud.gov native) | Encrypt and manage all per-binding cloud credentials |
| **Audit** | CF audit events + `.csb.db` + OpenTofu state | Log all lifecycle events with timestamp, actor, and state |
| **Security Scanning** | Prowler (submodule) | Continuous CIS/FedRAMP baseline assessment across all CSPs |

### Lifecycle State Machine

```
ACTIVE  (TTL clock running, cost telemetry active)
  |
  |-- T-1h --> WARNED  (Slack + email; one renewal available: +4h)
  |
  +-- TTL expired --> DEPROVISIONING  (cf delete-service; OpenTofu destroy)
                          |
                          +--> ARCHIVED  (state exported to S3; snapshot in .csb.db)
```

---

## Brokerpak Service Packs

### AWS (`submodules/csb-brokerpak-aws`)

Broker: `csb-aws-sandbox` — deployed and registered in `gsa-tts-iae-lava-beds / dev`
App: `csb-aws` (route auto-assigned by cloud.gov, e.g. `csb-aws-<random>.app.cloud.gov`) · Memory: 1G · Buildpack: binary

| Service | Plan | CF Marketplace Status | Constraints |
|---------|------|-----------------------|-------------|
| `csb-aws-s3-bucket` | `sandbox-8h` | ✅ Available | Private ACL; no versioning |
| `csb-aws-postgresql` | `sandbox-8h` | ✅ Available | `db.t3.micro`; no multi-AZ |
| `csb-aws-mysql` | `sandbox-8h` | ✅ Available | `db.t3.micro`; no multi-AZ |
| `csb-aws-redis` | `sandbox-8h` | ✅ Available | `t2.micro`; single-node |
| `csb-aws-sqs` | `sandbox-8h` | ✅ Available | Standard queues only |
| `csb-aws-aurora-postgresql` | `not-available` | 🚫 Stub | Not approved for sandbox |
| `csb-aws-aurora-mysql` | `not-available` | 🚫 Stub | Not approved for sandbox |
| `csb-aws-mssql` | `not-available` | 🚫 Stub | Not approved for sandbox |
| `csb-aws-dynamodb-namespace` | `not-available` | 🚫 Stub | Not approved for sandbox |

> **Stub plans** are required by CSB v2.6.10 for brokerpak services that define no built-in plans.
> They appear in the marketplace but cannot be used to provision resources. To promote a stub
> service to the approved catalog, follow the [Service Approval Workflow](#service-approval-policy).

### GCP (`submodules/csb-brokerpak-gcp`)

Broker: `csb-gcp-sandbox` — deployed and registered in `gsa-tts-iae-lava-beds / dev`
App: `csb-gcp` (route auto-assigned by cloud.gov, e.g. `csb-gcp-<random>.app.cloud.gov`) · Memory: 1G · Buildpack: binary

| Service | Plan | CF Marketplace Status | Constraints |
|---------|------|-----------------------|-------------|
| `csb-google-storage-bucket` | `sandbox-8h` | ✅ Available | Uniform ACL; 10-day lifecycle delete |
| `csb-google-postgres` | `sandbox-8h` | ✅ Available | `db-f1-micro`; no HA/PITR |
| `csb-google-mysql` | `sandbox-8h` | ✅ Available | `db-f1-micro`; no HA/PITR |

### Azure (`submodules/csb-brokerpak-azure`)

Broker: `csb-azure-sandbox` — **pending deployment** (requires `scripts/envs/azure.env`)

| Service | Plan | CF Marketplace Status | Constraints |
|---------|------|-----------------------|-------------|
| `csb-azure-postgresql` | `sandbox-8h` | ⏳ Pending deploy | Flexible Server `B1ms`; no zone redundancy |
| `csb-azure-mssql` | `sandbox-8h` | ⏳ Pending deploy | Basic 2 DTU; no geo-replication |
| `csb-azure-redis` | `sandbox-8h` | ⏳ Pending deploy | `C0` Basic; no clustering |
| `csb-azure-storage-account` | `sandbox-8h` | ⏳ Pending deploy | LRS only |
| `csb-azure-eventhubs` | `sandbox-8h` | ⏳ Pending deploy | Basic namespace, 1 TU |

> **Service not on the approved list?**
> Provisioning returns `HTTP 503`. CI automatically opens a GitHub Issue tagged
> `service-approval-request`. TechOps reviews and either merges the catalog entry
> (approved) or closes with rationale (rejected). Conditionally-approved services
> are tagged `conditional: true` with documented usage restrictions.

---

## Service Approval Policy

All services exposed through CSB brokerpaks must be pre-approved against the authorized
service lists for each CSP sandbox account. The enforcement flow:

1. Operator proposes adding a service to a brokerpak catalog.
2. CI validates the service name against the approved list in this repository.
3. **Not approved** → CI opens a GitHub Issue tagged `service-approval-request` with the
   service name, cloud provider, and requestor.
4. TechOps reviews and either approves (merges catalog entry with `approved: true`) or
   rejects (closes issue with rationale).
5. Conditionally-approved services document restrictions (e.g., "sandbox tier only") inline.

The approved service list and conditional-use constraints are maintained in
[`.github/agents/cloud-service-brokers.md`](.github/agents/cloud-service-brokers.md).

---

## OSCAL Security Controls

OSCAL (Open Security Controls Assessment Language) content is maintained for every service
broker and every resource type provisioned, providing machine-readable control inheritance
mappings that stay current with the brokerpak catalog.

| OSCAL Document | Purpose |
|---------------|---------|
| `content/oscal_ssp_schema.json` | System Security Plan — control implementation statements per brokerpak |
| `content/oscal_catalog_schema.json` | Control catalog baseline (NIST SP 800-53 Rev 5) |
| `content/oscal_profile_schema.json` | FedRAMP Moderate profile overlay |
| `content/oscal_component_schema.json` | Per-service component definitions (RDS, GCS, Azure PG, etc.) |
| `content/oscal_assessment-plan_schema.json` | Assessment plan driven by Prowler scan findings |
| `content/oscal_assessment-results_schema.json` | SAR populated from Prowler scan results |
| `content/oscal_poam_schema.json` | Plan of Action & Milestones for open findings |

**Workflow:** When a new service is added to a brokerpak, a Copilot task (`.github/agents/oscal.md`)
opens a PR to add the corresponding OSCAL component definition and update the SSP
control implementation statements.

---

## Security Scanning — Prowler

[`submodules/prowler`](submodules/prowler) provides continuous third-party assessment
and scanning across all three CSP accounts.

**Scope:**
- CIS Benchmark assessments for AWS, GCP, and Azure
- FedRAMP Moderate control checks
- Continuous baseline hardening validation
- Findings ingested into `content/oscal_assessment-results_schema.json`
- HIGH/CRITICAL findings automatically create POA&M items

**Run a scan:**

```bash
# AWS
prowler aws --compliance fedramp_moderate_revision_4

# GCP
prowler gcp --compliance fedramp_moderate_revision_4

# Azure
prowler azure --compliance fedramp_moderate_revision_4
```

Scan results are exported to the audit S3 bucket on completion.

---

## Cost & Budget Monitoring

| Threshold | Action | Escalation |
|-----------|--------|------------|
| 50% ($250) | Email + Slack alert to space owner | Awareness only |
| 80% ($400) | Alert + new provisioning requires TechOps approval | Email `tts-tech-operations@gsa.gov` |
| 100% ($500) | Suspend all sandbox provisioning; TTL deprovision continues | Pager + GSA spend reporting |
| Anomaly spike | Auto-deprovision instances >3x average hourly cost | Immediate notify + optional auto-kill |

### Required Resource Tags

Every resource carries these tags, injected by OpenTofu at provision time:

| Tag | Example | Required |
|-----|---------|----------|
| `Project` | `tts-sandbox-<your-username>` | YES |
| `Owner` | `your.name@gsa.gov` | YES |
| `TTLExpiry` | `2026-04-14T22:00:00Z` | YES |
| `CostCenter` | `sandbox-nonprod` | YES |
| `Cloud` | `aws` / `gcp` / `azure` | YES |
| `Environment` | `sandbox` | YES |
| `Brokerpak` | `csb-aws-postgresql-sandbox-8h` | RECOMMENDED |

---

## Implementation Phases

| Phase | Description | Duration |
|-------|-------------|----------|
| **1** | Core CSB Deployment — load brokerpaks, CredHub credentials, verify provision/delete | 2 weeks |
| **2** | TTL Controller — `ttl_expires_at` injection, T-1h notification, auto-deprovision, retry | 1 week |
| **3** | Budget Integration — AWS/GCP/Azure alerts at 50/80/100%, provisioning gate, CF quota | 1 week |
| **4** | Audit & Observability — OpenTofu state to S3, CF audit events, cost dashboard | 1 week |
| **5** | Self-Service Portal *(optional)* — FastAPI + React UI; Slack bot | Ongoing |

---

## Getting Started

### Prerequisites

- [Cloud Foundry CLI (`cf`)](https://docs.cloudfoundry.org/cf-cli/)
- Access to a cloud.gov organization (`gsa-tts-iae-lava-beds`, `dev` space)
- Node.js 18+ and `pnpm` (Gatsby documentation site)
- AWS CLI, Azure Developer CLI (`azd`), and Google Cloud SDK for credential provisioning

### Provision CSP credentials

Before deploying a broker, obtain IAM credentials for each cloud provider and
write them to the corresponding `scripts/envs/<provider>.env` file.

See **[docs/credential-provisioning.md](docs/credential-provisioning.md)** for
the full step-by-step guide:

| Provider | CLI | Doc section |
|----------|-----|-------------|
| AWS | `aws-cli` | [AWS — brew install → IAM user → access key → aws.env](docs/credential-provisioning.md#aws----aws-cli) |
| Azure | `azd` + `az` | [Azure — brew install → service principal → azure.env](docs/credential-provisioning.md#azure----azd--az) |
| GCP | `gcloud` | [GCP — brew install → service account → gcp.env](docs/credential-provisioning.md#gcp----gcloud) |

```bash
# Quick-copy the example files, then fill in with values from the guide above
cp scripts/envs/aws.env.example   scripts/envs/aws.env
cp scripts/envs/gcp.env.example   scripts/envs/gcp.env
cp scripts/envs/azure.env.example scripts/envs/azure.env
```

### Clone with submodules

```bash
git clone --recurse-submodules https://github.com/GSA-TTS/cloud-sandbox.git
cd cloud-sandbox
```

If you already cloned without `--recurse-submodules`:

```bash
git submodule update --init --recursive
```

### Run the documentation site

```bash
pnpm install
pnpm dev        # http://localhost:8000
```

### Provision a sandbox service

```bash
# 1. Start the broker first (brokers are stopped when not in active use)
pnpm run broker:start:aws

# 2. Provision a service
cf create-service csb-aws-postgresql sandbox-8h my-db \
  -c '{"ttl_hours":8,"project":"my-sprint","owner":"you@gsa.gov"}'

# 3. Extend once (+4 hours; one extension per instance)
cf update-service my-db -c '{"extend_hours":4}'

# 4. Delete manually (TTL controller will handle it automatically on expiry)
cf delete-service my-db -f

# 5. Stop the broker when done to save resources
pnpm run broker:stop:aws
```

### Broker start / stop reference

The broker apps are **stopped** when not in active use. The service registration and all
existing service instance state persists — only the OSBAPI endpoint goes offline.
No re-registration is needed when restarting.

```bash
# Start individual brokers before provisioning
pnpm run broker:start:aws
pnpm run broker:start:gcp

# Start all registered brokers at once
pnpm run broker:start:all

# Stop individual brokers
pnpm run broker:stop:aws
pnpm run broker:stop:gcp

# Stop all running broker apps
pnpm run broker:stop:all

# Check app + broker + marketplace state
pnpm run broker:status

# Full redeploy (only needed when brokerpak code or env vars change)
pnpm run broker:deploy:aws
pnpm run broker:deploy:gcp
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). All contributions are released under the
CC0 1.0 public domain dedication.

## Public Domain

This project is in the worldwide [public domain](LICENSE.md). See
[CONTRIBUTING.md](CONTRIBUTING.md) for details.
