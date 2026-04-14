# Open Questions — Cloud Sandbox Platform

> Working document for scoping decisions, policy gaps, and technical unknowns.
> Answer each question to drive backlog items and architecture decisions.
> Last updated: April 2026

---

## 1. Identity & Access Management

1. **IAM credential lifecycle** — The current AWS environment uses long-lived IAM access keys (static `AKIA*` keys). Should these be rotated to short-lived IAM role credentials via IAM Identity Center (SSO) or instance profiles? What is the key rotation policy and who owns rotation?

Critical question: the ideal workflow would be having this repo as a synced clone to our internal Gitlab where the persistent role credentials can be stored in Gitlab CI variables and injected at build time, rather than having long-lived credentials in a local `.env` file.

2. **CSB broker identity per CSP** — Should each CSP broker app use its own dedicated IAM service account / service principal with minimum-privilege policies, or is a shared sandbox iam role acceptable? What are the permission boundaries for each?

Yes least privilege service accounts per broker. The IAM profile/policy should be a 1:1 match of the provisioning services brokerable

3. **CredHub adoption** — CSB credentials are currently injected as CF env vars at deploy time. When will we migrate to CredHub variable bindings (`cf set-credential`)? Who owns the CredHub namespace and access policy?

Would need to work out the ideal boundary, a priviledged set of engineers should be responsible to managing and deploying. But Service Brokered Services should be mountable in other cf spaces so the credentials should be stored in a way that they can be easily injected into other spaces (e.g. prod) if we want to use the same broker for prod provisioning. This is another reason to prefer CredHub over env vars in the manifest.

4. **User-level provisioning permissions** — Can any developer in the `gsa-tts-iae-lava-beds` org provision sandbox services, or is provisioning gated to specific SpaceDeveloper roles? Should we add a CF quota to limit concurrent instances per user?

Yes we should implement all of the CF qouta and role-base access controls at our dispol as `configurable` using groups to allow for provisioning sets of resources, cost should have budget limits ideally informing the user before provisioning. Default Time-to-live (TTL) should be configurable with a 59minute/~1hr default and a max of 8hrs. We should also have a renewal policy that allows for one 4hr extension.

1. **Broker credentials exposure** — `SECURITY_USER_NAME` / `SECURITY_USER_PASSWORD` for the broker are stored in `scripts/envs/aws.env`. Should these be generated per-deployment and rotated, or are static broker credentials acceptable for the sandbox tier?

All provisioned and brokered services should return the credentials for those services via VCAP_SERVICES on the CF app.

---

## 2. TTL Controller

6. **Controller implementation** — The TTL controller is referenced in the architecture but not yet built. What is the implementation target: CF cron task, a standalone CF app, a GitHub Actions scheduled workflow, or an external scheduler (e.g., AWS EventBridge)? Who owns the build?

TBD we should have an alternatives analysis with criteria for grading and selection

7. **TTL tag injection** — The `TTLExpiry` tag should be set at provision time by the OpenTofu module. Is this tag injection already in the brokerpak modules, or does each submodule need a PR to add it? Which OpenTofu root module `locals` block owns the tag?

TBD list all available tagging points and configuration options to override or amend while running.

1. **Renewal enforcement** — The policy allows one 4-hour renewal per instance. Where is renewal state tracked — in the CSB backing database, a separate table, or CF service instance metadata? What prevents a second `cf update-service -c '{"extend_hours":4}'` call?

List all available options for tracking renewal state and enforcing the one-renewal policy.

1.  **Notification channels** — T-1h warnings should go to the `Owner` tag value. Does `Owner` contain a GSA email address that Cloud Notify / Slack can reach? Is there an existing Slack webhook or do we need to stand one up?

Slack, email, SMS, JS alerts should all be supported

2.  **Orphan resource detection** — What happens if a CF app or service is deleted directly (e.g., `cf delete-service -f`) before the TTL controller runs? Will the CSB's OpenTofu destroy still execute? Is there a reconciliation loop?

All orphaned resources should be destroyed with no persistent or ephemeral resources left behind. If the option to persist state over sessions should be documented in exterme cases using static storage like S3 or GCS buckets to track state and ensure orphaned resources are cleaned up.

---

## 3. Budget & Cost Governance

11. **Budget ceiling enforcement** — The $500/month ceiling is policy, but the current CSB deployment has no budget API integration. What is the target implementation: AWS Budgets Actions (auto-stop EC2/RDS), GCP Budget API + Pub/Sub trigger, Azure Cost Management alerts? One per CSP, or a unified cost layer?

Yes individuals should have a budget, and if they run out they will need to budget useage off a project tag

12. **Cost attribution** — The `CostCenter=sandbox-nonprod` tag is set on all resources, but cost roll-up to the sandbox org requires tag-based billing filters. Are AWS Cost Explorer, GCP Billing export, and Azure Cost Analysis configured for this tag? Who owns the billing dashboards?

13. **80% provisioning gate** — At 80% spend the architecture calls for TechOps approval of new provisions. What is the approval mechanism — a GitHub issue, a Slack approval bot, a CF quota reduction? How is the gate lifted when the next billing cycle starts?

TBD

1.  **Per-user cost tracking** — Should the `Owner` tag be used to break down spending per engineer? Is there a target dashboard (Grafana, spend transparency, internal tool)?

Yes all resources provisioned should 100% be tagged with the `Owner` tag and that should be used to break down spending per engineer. This should be visible in the billing dashboards. 'Project' tags should be more important to break down spending by project or team. but both deminisions should be available in the billing dashboards.

1.  **Anomaly spike threshold** — "3x average hourly cost" is the anomaly trigger. What is the baseline measurement window (rolling 7-day average? billing-period average?)? Who defines and tunes this threshold?

Yes we should have some form of anomaly detection and alerting for cost spikes, the threshold and tuning should be owned by the team responsible for monitoring and responding to incidents.

---

## 4. Service Catalog & Approval Workflow

16. **Approval enforcement in CI** — The approval workflow is documented but not implemented in CI. Should the check live in a GitHub Actions workflow that blocks brokerpak PRs unless the service is in an approved list file? What is the authoritative list format (YAML, JSON, inline in the workflow)?

17. **Service naming drift** — The README uses `csb-aws-sqs-queue` but the brokerpak service is named `csb-aws-sqs`. Are the GCP and Azure service names in this README validated against the actual brokerpak YAML service IDs, or are they draft names that need reconciliation?

18. **Conditional approvals** — Some services may be approved only for specific use cases (e.g., "BigQuery on-demand only, no reserved slots"). Where do conditional approval constraints live — in the service definition YAML, in a separate policy file, or in the GitHub issue description?

19. **Non-approved service stubs** — Four AWS services (`aurora-postgresql`, `aurora-mysql`, `mssql`, `dynamodb-namespace`) appear as `not-available` in the marketplace. Should these be hidden entirely (requires upstream CSB `DISABLE_SERVICES` support), or is the stub plan approach acceptable long-term?

20. **Cross-CSP parity** — Do GCP and Azure brokerpaks have analogous "plan-less" services that will also require stubs? Should we audit the full service list in each brokerpak before deploying GCP/Azure brokers?

---

## 5. Deployment & Operations

21. **CF org memory quota** — At session start the org had ~2.5 GB free out of 8 GB. Each broker app uses 1 GB. With three brokers deployed that is 3 GB consumed by CSB alone. Is the 8 GB org quota sufficient long-term, or does TechOps need to raise it before GCP/Azure deploy?

22. **Broker app HA** — All three CSB broker apps are deployed with `instances: 1`. Should they be scaled to 2 for availability, or is single-instance acceptable for a sandbox-tier internal tool?

23. **Backing database shared state** — All three brokers share one `csb-sql` MySQL instance. If csb-sql becomes unavailable all three brokers fail simultaneously. Should each broker have its own MySQL instance, or is a shared instance with database-level isolation (separate schemas/DBs) acceptable?

24. **Brokerpak versioning** — All three submodules are pinned to their current commits. What is the process for updating a brokerpak version: PR + submodule pointer bump + test + redeploy? Who reviews brokerpak updates for security regressions?

25. **Deploy script idempotency** — `deploy-aws.sh` re-uploads the full 263 MB brokerpak on every run even if the brokerpak content has not changed. Should we add a content hash check to skip re-upload and skip `cf push` if unchanged?

26. **GCP and Azure env files** — `scripts/envs/gcp.env` and `scripts/envs/azure.env` do not exist yet. Who holds the GCP service account JSON key and the Azure service principal credentials? What is the handoff process from TechOps to the engineer running the deploy?

27. **Secrets rotation runbook** — When AWS access keys, GCP SA keys, or Azure SP secrets are rotated, what is the procedure to update the CF app without downtime? Should we document a `cf set-env` + `cf restart` runbook or move to CredHub to simplify rotation?

---

## 6. Security & Compliance

28. **Prowler integration status** — The Prowler submodule is present but no scan has been run. What AWS/GCP/Azure permissions does the Prowler scanner need? Should scans run on a schedule (GitHub Actions cron) or on-demand only?

29. **Prowler findings workflow** — Where do Prowler findings land: a GitHub issue, an S3 HTML report, an OSCAL assessment-results file, or all three? Who triages HIGH/CRITICAL findings and opens POA&M items?

30. **OSCAL content state** — The `content/oscal_*.json` files contain JSON Schema definitions, not populated OSCAL documents. Is there a target date for populating the SSP and component definitions? Who (person or team) is the ISSO responsible for OSCAL accuracy?

31. **Data residency** — Sandbox resources are currently deployed to `us-east-1` (AWS default). Does TTS policy require all sandbox data to stay in US regions? Are there controls preventing provisioning in non-US regions through the sandbox plans?

32. **Shared VPC** — The AWS broker uses `vpc-61e8f005` for all sandbox resources. Is this a shared VPC with other TTS workloads, or a dedicated sandbox VPC? What network security group baseline applies to sandbox RDS/ElastiCache instances?

33. **CF security groups** — cloud.gov FedRAMP security groups restrict egress from CF apps. Does the CSB broker app have the network access it needs to reach the AWS/GCP/Azure control planes? Have the required CF security group bindings been verified?

---

## 7. OSCAL & Documentation

34. **OSCAL schema vs. content** — The `content/` directory holds JSON Schema files (`oscal_*_schema.json`) rather than populated OSCAL documents. Should the repo contain both the schemas and instance documents (SSP, component definitions), or should instance documents live in a separate OSCAL repository?

35. **Per-service component definitions** — The OSCAL workflow calls for a component definition per service broker service (e.g., one for `csb-aws-postgresql`). How granular should these be — one component per service, per plan, or per brokerpak?

36. **Gatsby site scope** — The Gatsby site currently renders OSCAL document pages. Should the site also serve as the sandbox service catalog UI (showing available plans, current instances, cost dashboards), or is it purely a documentation and compliance artifact viewer?

37. **Audience** — Who is the primary audience for the README and Gatsby site: TTS engineers provisioning sandboxes, TTS leadership reviewing cost compliance, FedRAMP auditors reviewing control inheritance, or all three? The answer changes the information architecture significantly.

---

## 8. Team & Process

38. **Ownership model** — Who is the primary maintainer of this repository? Is it a single platform team (TTS IAE), a rotation across teams, or community-maintained?

39. **On-call and incident response** — If the TTL controller fails and instances are not deprovisioned, who receives the alert? Is there an incident response runbook for sandbox cost overruns?

40. **Contribution process** — CONTRIBUTING.md exists but is generic. Should there be a more specific process for engineers requesting new sandbox service types (beyond the service approval issue template)?

41. **Submodule update cadence** — The csb-brokerpak-aws/gcp/azure and prowler submodules will receive upstream updates. Is there a Dependabot or Renovate configuration to surface those updates automatically?

42. **Sandbox-to-production path** — Is the intent for some sandbox workloads to eventually graduate to production CF spaces? If so, should the CSB plan structure distinguish `sandbox-*` plans from `prod-*` plans, and is the same CSB deployment used for production provisioning?
