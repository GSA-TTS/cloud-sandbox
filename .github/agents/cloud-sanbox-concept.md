# Cloud Service Broker — Sandbox Lifecycle & Cost Governance Proposal

## Document Overview

| Field | Details |
|-------|---------|
| **Title** | Cloud Service Broker — Sandbox Lifecycle & Cost Governance Proposal |
| **Organization** | General Services Administration · Technology Transformation Services |
| **Document Type** | Draft Proposal |
| **Date** | April 2026 |
| **Classification** | DRAFT — Internal Use |
| **Purpose** | Automated multi-cloud sandbox provisioning with 8-hour deprovisioning, budget enforcement, and lifecycle observability for AWS · GCP · Azure on cloud.gov |

---

## Executive Summary

| Aspect | Description |
|--------|-------------|
| **Problem** | Sandbox sprawl creates budget overruns, compliance risk, and untagged orphan resources |
| **Solution** | Lifecycle management architecture built on Cloud Foundry Cloud Service Broker (CSB) |
| **Budget Ceiling** | $500/month per TTS Infrastructure policy |
| **Auto-Deprovision TTL** | 8 hours |
| **Design Philosophy** | Apply LLM Wiki v2 "lifecycle management" pattern — confidence decay, supersession, and automated consolidation — to cloud resources |

---

## Scope — Supported Cloud Providers

| Cloud Provider | Host Platform |
|----------------|---------------|
| AWS | cloud.gov / Cloud Foundry |
| Google Cloud Platform | cloud.gov / Cloud Foundry |
| Microsoft Azure | cloud.gov / Cloud Foundry |

---

## Key Outcomes

| Outcome | Description |
|---------|-------------|
| **Zero idle spend** | Sandbox instances auto-deprovision after 8 hours; no manual cleanup required |
| **Budget guardrails** | Hard $500/mo ceiling with 80%/100% alert thresholds and automated service suspension |
| **Audit-ready tagging** | All resources tagged with Project, Owner, TTL-expiry, and CostCenter at creation |
| **Self-service provisioning** | Engineers use standard cf CLI; no IAM access or cloud console required |
| **FedRAMP alignment** | Inherits cloud.gov FedRAMP Moderate controls; no new ATO surface for sandbox use |

---

## Current State Pain Points

| Pain Point | Description |
|------------|-------------|
| **Resource Accumulation** | Forgotten EC2 instances, Cloud SQL databases, and Azure VMs run indefinitely after experiments end |
| **Reactive Budget Discovery** | Budget burn is discovered reactively; by the time alerts fire, overages are already incurred |
| **No TTL Enforcement** | Orphan resources persist for days or weeks |
| **Manual Cleanup** | Error-prone and relies on developer memory, not process |
| **No Consolidated View** | No consolidated cost view across AWS, GCP, and Azure for a single team or sprint |

---

## Architecture Overview

| Layer | Component | Responsibility |
|-------|-----------|----------------|
| **Provisioning** | CSB + aws/gcp/azure-brokerpak cf CLI / OSBAPI | Create, bind, update, delete service instances via OpenTofu |
| **Governance** | TTL Controller (cron job) cf service metadata | Tag resources at creation; poll for expired instances; call cf delete-service |
| **Cost Observability** | AWS Budgets / GCP Budget API / Azure Cost Management | Per-project spending alerts at 50%, 80%, 100% thresholds; suspend on breach |
| **Secrets** | CredHub (cloud.gov native) | Encrypt and manage all per-binding cloud credentials |
| **Audit** | Cloud Foundry audit events CSB .csb.db / OpenTofu state | Log all lifecycle events with timestamp, actor, and resource state |

---

## Lifecycle State Machine

| State | Trigger | Action |
|-------|---------|--------|
| **ACTIVE** | Instance provisioned | TTL clock running; cost telemetry collecting |
| **WARNED** | T-1 hour before expiry | Email + Slack notification to owner. Owner may extend once (+4 hrs) |
| **DEPROVISIONING** | TTL reached | CSB issues cf delete-service; OpenTofu destroy runs |
| **ARCHIVED** | Audit record + cost snapshot retained in .csb.db | OpenTofu state exported to S3 bucket |

---

## Brokerpak Service Packs

### AWS Brokerpak

| Field | Details |
|-------|---------|
| **Repository** | cloudfoundry/aws-brokerpak |

| Service | Description |
|---------|-------------|
| csb-aws-s3-bucket | Object storage (no versioning in sandbox tier) |
| csb-aws-postgresql | RDS PostgreSQL db.t3.micro only |
| csb-aws-mysql | RDS MySQL db.t3.micro only |
| csb-aws-redis | ElastiCache t2.micro single-node |
| csb-aws-sqs-queue | Standard queues |

| Sandbox Constraint | Description |
|--------------------|-------------|
| Instance Size | Locked to micro/small tiers via plan defaults; plan parameters override blocked |
| Multi-AZ | Disabled in sandbox tier plans |
| Tagging | All resources tagged: Environment=sandbox, TTLExpiry=<ISO8601>, Project=<cf-space> |
| S3 Bucket ACL | Forced to private; public-read plans removed from catalog |

---

### Google Cloud Platform Brokerpak

| Field | Details |
|-------|---------|
| **Repository** | cloudfoundry/gcp-brokerpak |

| Service | Description |
|---------|-------------|
| csb-google-bigquery | Dataset provisioning (no data transfer jobs) |
| csb-google-cloudsql-postgres | db-f1-micro tier only |
| csb-google-pubsub | Topic + subscription pairs |
| csb-google-storage | GCS bucket, uniform bucket-level access enforced |
| csb-google-redis | 1 GB BASIC tier Memorystore |

| Sandbox Constraint | Description |
|--------------------|-------------|
| Project Scope | All resources created in dedicated sandbox GCP project; IAM constrained to project scope |
| BigQuery | Reserved slots disabled; on-demand pricing only |
| Cloud SQL | High-availability and point-in-time recovery disabled in sandbox plans |
| GCS Buckets | Enforce object lifecycle rules: auto-delete after 10 days |

---

### Microsoft Azure Brokerpak

| Field | Details |
|-------|---------|
| **Repository** | cloudfoundry/azure-brokerpak |

| Service | Description |
|---------|-------------|
| csb-azure-postgresql | Flexible Server B1ms tier only |
| csb-azure-mssql | Basic tier, 2 DTU |
| csb-azure-redis | C0 Basic cache |
| csb-azure-storage-account | LRS, no RA-GRS in sandbox |
| csb-azure-eventhubs | Basic namespace, 1 TU |

| Sandbox Constraint | Description |
|--------------------|-------------|
| Resource Group | All resources deployed into a dedicated sandbox resource group per CF space |
| Tagging | Resource group tagged with TTLExpiry; Azure Policy denies resources missing this tag |
| Azure Budgets | Alert set at $50 per resource group (approx. 10% of monthly cap) |
| Redundancy | Zone redundancy and geo-replication disabled on all sandbox-tier plans |

---

## 8-Hour Auto-Deprovisioning System

### TTL Controller Design

| Aspect | Details |
|--------|---------|
| **Type** | Lightweight Cloud Foundry task (or CF cron app) |
| **Frequency** | Runs every 15 minutes |
| **Query** | Service instances where ttl_expires_at <= NOW() |
| **Action** | Calls cf delete-service for each expired instance |
| **Retry Logic** | Exponential backoff (15m, 30m, 1h) before paging on-call |

### Provision Flow (with TTL injection)

| # | Step | Description | Command / Output | Actor |
|---|------|-------------|------------------|-------|
| 1 | cf create-service | Developer issues cf create-service with plan sandbox-8h | `cf create-service csb-aws-postgresql sandbox-8h my-db -c '{"ttl_hours":8}'` | CF / CSB |
| 2 | Plan validation | CSB plan enforces max ttl_hours=8; rejects > 8 | HTTP 400 if ttl_hours > 8 or plan != sandbox-* | CSB broker |
| 3 | OpenTofu provision | CSB calls OpenTofu apply; tags all resources with TTLExpiry | tag: TTLExpiry = ISO8601(now + 8h) | OpenTofu / AWS\|GCP\|AZ |
| 4 | Metadata write | CSB writes instance record to .csb.db with ttl_expires_at | INSERT INTO service_instances (id, expires_at, owner, cloud) | CSB DB |
| 5 | T-1h warning | TTL controller detects instances expiring within 60 min; notifies owner | POST to Slack webhook / send email via cf-notifications | TTL Controller |
| 6 | Deprovision | TTL controller calls cf delete-service; OpenTofu destroy runs | `cf delete-service my-db -f && csb delete-service-key` | TTL Controller |
| 7 | Archive | Cost snapshot + OpenTofu state exported to audit S3 bucket | `aws s3 cp terraform.tfstate s3://tts-sandbox-audit/...` | TTL Controller |

### Renewal Policy

| Aspect | Details |
|--------|---------|
| **Command** | `cf update-service my-db -c '{"extend_hours":4}'` |
| **Validation (a)** | Current TTL has not yet expired |
| **Validation (b)** | No prior extension has been granted for this instance |
| **Approved Action** | Updates ttl_expires_at and re-tags cloud resources |
| **Second Extension Request** | Returns HTTP 409 with message directing developer to re-provision |

---

## Cost & Budget Monitoring

### Budget Thresholds

| Threshold | Action | Cloud Implementation | Escalation |
|-----------|--------|----------------------|------------|
| **50% ($250)** | Email + Slack alert to space owner | AWS Budgets alert, GCP Budget notification, Azure Cost alert | None — awareness only |
| **80% ($400)** | Alert + new provisioning requires TechOps approval | CSB plan gate: checks tag budget:blocked before provision | Email tts-tech-operations@gsa.gov |
| **100% ($500)** | Immediately suspend all sandbox provisioning; existing instances still deprovision on TTL | CF org quota set to 0 memory; CSB returns HTTP 503 for create-service | Pager alert + GSA reporting per federal spend law |
| **Anomaly spike** | Auto-deprovision instances > 3× average hourly cost within same billing period | CloudWatch anomaly detection, GCP Budgets Pub/Sub trigger, Azure Cost anomaly alert | Immediate notify + optional auto-kill |

---

## Tagging Strategy

| Tag Key | Example Value | Purpose | Required |
|---------|---------------|---------|----------|
| **Project** | tts-sandbox-\<username\> | TTS billing and project tracking | YES |
| **Owner** | your.name@gsa.gov | Notification target for TTL warnings | YES |
| **TTLExpiry** | 2026-04-13T22:00:00Z | Deprovision timestamp for TTL controller | YES |
| **CostCenter** | sandbox-nonprod | Budget allocation category | YES |
| **Cloud** | aws \| gcp \| azure | Provider identifier for cross-cloud cost rollup | YES |
| **Environment** | sandbox | Prevents accidental prod confusion | YES |
| **Brokerpak** | csb-aws-postgresql-sandbox-8h | Traceable to plan for audit | RECOMMENDED |

---

## Implementation Outline

| Phase | Name | Duration | Activities | Outcome |
|-------|------|----------|------------|---------|
| **Phase 1** | Core CSB Deployment | 2 weeks | Deploy CSB on cloud.gov; load aws/gcp/azure brokerpaks; configure CredHub for CSP credentials; define sandbox-8h plan with size constraints; verify cf create-service → provision → cf delete-service flow | Manual deprovisioning; cost alerts via native cloud consoles only |
| **Phase 2** | TTL Controller | 1 week | Implement TTL controller as CF scheduled task; inject ttl_expires_at at provision time; implement T-1h Slack/email notification; implement auto-deprovision on expiry; test idempotent delete and retry logic | Adds 8-hour auto-deprovision. Renewal endpoint (+4h, once only) |
| **Phase 3** | Budget Integration | 1 week | Configure AWS Budgets, GCP Budget API, Azure Cost Management alerts at 50/80/100% thresholds; implement CSB provisioning gate that checks org-level budget tag before allowing create-service; configure CF org quota suspension at 100% threshold | Full automated cost enforcement. All three clouds covered |
| **Phase 4** | Audit & Observability | 1 week | Export OpenTofu state to audit S3 bucket on deprovision; emit structured CF audit events for every lifecycle transition; build Grafana or Kibana dashboard for sandbox cost-by-project and active instance count across AWS/GCP/Azure | Compliance-ready audit trail. Cost visibility dashboard |
| **Phase 5** | Self-Service Portal (Optional) | Ongoing | Lightweight web UI (FastAPI + React) that wraps cf CLI calls; shows active instances, TTL countdown, cost-to-date, and renewal button. Integrates with TTS Slack bot for conversational provisioning | Developer experience improvement. Not required for core function |