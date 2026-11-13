# Credential Provisioning Guide

Step-by-step instructions for provisioning the IAM credentials required by each
CSB brokerpak using the official CLI for each cloud provider.

When complete, each section ends with writing the generated credentials to
the appropriate `scripts/envs/<provider>.env` file. **Never commit `.env` files —
they are git-ignored.**

After the broker credentials are in place and the brokers are deployed, see
### 4. Approve the broker identity and private placement

The CF broker API user (`SECURITY_USER_NAME`) is separate from the AWS IAM
execution user. Create and review the provider-qualified IAM user and its
least-privilege policy through the approved IAM process; do not run the broad
example policy above unchanged. Before creating an access key, select existing
private placement resources in one region:

- VPC ID;
- RDS subnet group and security group IDs;
- ElastiCache subnet group and security group IDs.

Every selected subnet group and security group must belong to the selected VPC.
The bootstrap refuses missing or mismatched values so the upstream modules
cannot create subnet groups or security groups implicitly.

service instance, reads the resulting `VCAP_SERVICES` binding, and wires the
credentials into Zed, CLI agents, and VS Code.

Tool-specific follow-ups:

- `docs/zed-auth-configuration.md`
- `docs/opencode-auth-configuration.md`
- `docs/vscode-auth-configuration.md`

---
bash scripts/iam-bootstrap-aws.sh csb-aws-sandbox-broker <sso-profile> us-east-1 \
  <approved-vpc-id> <rds-subnet-group> <rds-security-group-ids> \
  <elasticache-subnet-group> <elasticache-security-group-ids>
## AWS — `aws-cli`

### 1. Install
### 3. Create the service principal

The Azure execution identity is separate from `SECURITY_USER_NAME`. The current
```bash
brew install awscli
aws --version   # aws-cli/2.x
```

### 2. Authenticate (admin session to bootstrap the IAM user)

Use an account with IAM write access (AdministratorAccess or equivalent).

```bash
bash scripts/iam-bootstrap-azure.sh <existing-approved-app-name> "$SUBSCRIPTION_ID" \
  <approved-resource-group>
aws sso login --profile <profile-name>
export AWS_PROFILE=<profile-name>
```

### 3. Create the IAM policy document

Save the minimum permissions required by `csb-brokerpak-aws` as a local file:

```bash
cat > /tmp/csb-aws-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RDS",
      "Effect": "Allow",
      "Action": [
        "rds:CreateDBInstance",
        "rds:DeleteDBInstance",
        "rds:DescribeDBInstances",
It does not create an application, change credentials, assign a role, or write
`azure.env`. A separate approved change must specify the final identity, allowed
roles, scope, expiration, and controlled secret delivery method.
        "rds:AddTagsToResource",
        "rds:ListTagsForResource",
        "rds:CreateDBSubnetGroup",
        "rds:DeleteDBSubnetGroup",
        "rds:DescribeDBSubnetGroups",
        "rds:CreateDBParameterGroup",
        "rds:DeleteDBParameterGroup",
        "rds:ModifyDBParameterGroup",
        "rds:DescribeDBParameterGroups",
        "rds:DescribeDBParameters",
        "rds:DescribeOrderableDBInstanceOptions",
        "rds:DescribeEngineDefaultParameters"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ElastiCache",
      "Effect": "Allow",
      "Action": [
        "elasticache:CreateCacheCluster",
        "elasticache:DeleteCacheCluster",
        "elasticache:DescribeCacheClusters",
        "elasticache:ModifyCacheCluster",
        "elasticache:AddTagsToResource",
        "elasticache:ListTagsForResource",
        "elasticache:DescribeCacheSubnetGroups",
        "elasticache:CreateCacheSubnetGroup",
        "elasticache:DeleteCacheSubnetGroup",
        "elasticache:DescribeCacheParameterGroups",
        "elasticache:DescribeCacheParameters"
      ],
      "Resource": "*"
    },
    {
      "Sid": "S3",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:GetBucketAcl",
        "s3:PutBucketAcl",
        "s3:GetBucketPolicy",
        "s3:PutBucketPolicy",
        "s3:DeleteBucketPolicy",
        "s3:GetEncryptionConfiguration",
        "s3:PutEncryptionConfiguration",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:GetBucketTagging",
        "s3:PutBucketTagging",
        "s3:GetBucketPublicAccessBlock",
        "s3:PutBucketPublicAccessBlock",
        "s3:ListBucket",
        "s3:ListAllMyBuckets"
      ],
      "Resource": "*"
    },
    {
      "Sid": "SQS",
      "Effect": "Allow",
      "Action": [
        "sqs:CreateQueue",
        "sqs:DeleteQueue",
        "sqs:GetQueueAttributes",
        "sqs:SetQueueAttributes",
        "sqs:ListQueues",
        "sqs:TagQueue",
        "sqs:ListQueueTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMPassRole",
      "Effect": "Allow",
      "Action": [
        "iam:CreateUser",
        "iam:DeleteUser",
        "iam:AttachUserPolicy",
        "iam:DetachUserPolicy",
        "iam:CreateAccessKey",
        "iam:DeleteAccessKey",
        "iam:ListAccessKeys",
        "iam:GetUser",
        "iam:ListAttachedUserPolicies",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:GetPolicy",
        "iam:GetPolicyVersion",
        "iam:ListPolicyVersions",
        "iam:TagUser",
        "iam:ListUserTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2VPC",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:DescribeNetworkInterfaces",
        "ec2:CreateTags",
        "ec2:DescribeAvailabilityZones"
      ],
      "Resource": "*"
    }
  ]
}
EOF
```

### 4. Approve the broker identity and private placement

`SECURITY_USER_NAME` is the Cloud Foundry broker API user; it is not the AWS
IAM execution user. Create and review a provider-qualified IAM user and a
least-privilege policy through the approved IAM process. Do not apply the broad
example policy above unchanged.

Before creating an access key, select existing private placement resources in
one region: VPC ID, RDS subnet group, RDS security-group IDs, ElastiCache subnet
group, and ElastiCache security-group IDs. Every selected resource must belong
to that VPC. The bootstrap rejects missing or mismatched inputs to prevent
upstream modules from creating network resources implicitly.

### 5. Create the environment file

For an existing, approved broker IAM user, use the secure writer. It creates a
new access key only when the user has fewer than two keys, writes the file
atomically with mode `0600`, generates the broker password, and does not print
or leave provider secrets in a temporary file. It does **not** deploy a broker.

```bash
bash scripts/iam-bootstrap-aws.sh csb-aws-sandbox-broker <sso-profile> us-east-1 \
  <approved-vpc-id> <rds-subnet-group> <rds-security-group-ids> \
  <elasticache-subnet-group> <elasticache-security-group-ids>
```

Validate the file's presence, permissions, and required variable names without
printing values:

```bash
test -f scripts/envs/aws.env && test "$(stat -c '%a' scripts/envs/aws.env)" = 600
```

---

## Azure — `azd` + `az`

When you copy `scripts/envs/azure.env.example` to `scripts/envs/azure.env`, keep
`GSB_PROVISION_DEFAULTS` limited to shared values like `location`. Do not set a
global `resource_group` there. Azure AI offerings now rely on per-instance
resource-group defaults and user overrides so `csb-azure-openai` and
`csb-azure-foundry` do not collide with a shared unmanaged resource group.

`azd` (Azure Developer CLI) is used to authenticate and set the target
subscription. The `az` CLI is used to create the service principal.

### 1. Install

```bash
brew tap azure/azd
brew install azd
brew install azure-cli

azd version    # azd version 1.x
az version     # azure-cli 2.x
```

### 2. Authenticate

```bash
# Authenticate azd (device-code flow)
azd auth login

# Authenticate az (aligned to the same account)
az login --use-device-code

# List subscriptions and note the sandbox subscription ID
az account list --output table

# Set the target sandbox subscription
SUBSCRIPTION_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
az account set --subscription "$SUBSCRIPTION_ID"
azd config set defaults.subscription "$SUBSCRIPTION_ID"
```

### 3. Azure approval gate

The Azure execution identity is separate from `SECURITY_USER_NAME`. The current
security-auditor implementation creates Entra applications and assigns Reader
at subscription scope, while the active catalog has additional provider
requirements. A catalog-specific role design and approved scope are therefore
required before credentials can be created. Do not grant subscription-wide
Contributor or User Access Administrator by default and do not rotate an
existing client secret implicitly.

The helper performs only read-only validation of a pre-existing approved
identity and its resource-group scope:

```bash
bash scripts/iam-bootstrap-azure.sh <existing-approved-app-name> "$SUBSCRIPTION_ID" \
  <approved-resource-group>
```

It does not create an application, change credentials, assign roles, or write
`azure.env`. A separate approved change must define the final identity, allowed
roles, scope, expiry, and controlled secret-delivery method.

### 6. Preflight Azure OpenAI model deployments before provisioning

Azure OpenAI model compatibility is not just `model + version`. In practice, the
control-plane acceptance path also depends on deployment SKU and region. Use the
preflight helper to emulate the same Azure deployment create call that OpenTofu
will make for `csb-azure-openai`.

Non-destructive metadata check:

```bash
pnpm run azure:openai:preflight -- \
  --location eastus \
  --deployments-json '[{"name":"gpt-5.5","model":"gpt-5.5","version":"2026-04-24","capacity":10}]'
```

If you already have a probe account in the target region, pass it explicitly and
ask the helper to probe the create call as well:

```bash
pnpm run azure:openai:preflight -- \
  --location eastus \
  --resource-group csb-openai-full-0505a \
  --account-name csb213089a5e4244179bbf59 \
  --deployments-json '[{"name":"gpt-5.5","model":"gpt-5.5","version":"2026-04-24","capacity":10}]' \
  --probe-create
```

What it checks:

- exact `name` / `version` matches from `az cognitiveservices account list-models`
- Azure capability keys returned for the model, including `priorityTierSkus`
- optional live `az cognitiveservices account deployment create` probe using the
  same `model-name`, `model-version`, `sku-name`, and `sku-capacity` shape that
  Terraform uses

Use this before changing Azure OpenAI defaults or plan overrides. It catches the
same `InvalidResourceProperties` failures earlier, with the exact Azure CLI
error payload.

To make the Azure broker deploy fail fast on the same check, set these in
`scripts/envs/azure.env` before running `pnpm run broker:deploy:azure`:

Keep `AZURE_OPENAI_PREFLIGHT_DEPLOYMENTS_JSON` shell-quoted in the env file.
If you omit the outer quotes, `source scripts/envs/azure.env` will strip the
JSON quoting and the preflight will reject it as malformed.

```bash
AZURE_OPENAI_PREFLIGHT=1
AZURE_OPENAI_PREFLIGHT_LOCATION=eastus
AZURE_OPENAI_PREFLIGHT_DEPLOYMENTS_JSON='[{"name":"gpt-5.5","model":"gpt-5.5","version":"2026-04-24","capacity":10}]'
AZURE_OPENAI_PREFLIGHT_SKU_NAME=Standard
AZURE_OPENAI_PREFLIGHT_PROBE_CREATE=1
```

If you already have a probe account you want to target instead of auto-discovery,
also set:

```bash
AZURE_OPENAI_PREFLIGHT_RESOURCE_GROUP=csb-openai-full-0505a
AZURE_OPENAI_PREFLIGHT_ACCOUNT_NAME=csb213089a5e4244179bbf59
```

---

## Databricks Model Serving

Databricks serving endpoints are not the same shape as Azure OpenAI or the
public OpenAI API.

- Raw Databricks invocation URL: `https://<workspace>/serving-endpoints/<endpoint>/invocations`
- OpenAI-compatible base URL for Codex-style clients: `https://<workspace>/serving-endpoints/<endpoint>/v1`

For Codex or other OpenAI-compatible clients, use the Databricks
`openai_base_url` returned by the broker binding, not the raw `invocation_url`
and not the OpenAI public API base URL.

The new Databricks brokerpak scaffold in this repo targets that contract: a
brokered model-serving instance returns a binding-scoped Databricks token plus
both URL shapes so clients can choose the correct transport.

Example OpenAI-compatible client shape:

```python
from openai import OpenAI

client = OpenAI(
  api_key="<databricks_pat>",
  base_url="https://<workspace>/serving-endpoints/<endpoint>/v1",
)
```

---

## GCP — `gcloud`

### 1. Install

```bash
brew install --cask google-cloud-sdk
# or (if already installed via the installer):
# brew install --cask gcloud-cli

gcloud version   # Google Cloud SDK 4xx.x.x
```

### 2. Authenticate

```bash
gcloud auth login --update-adc
# Opens browser — complete OAuth flow with your GSA Google account

# Set the sandbox project
GCP_PROJECT=your-gcp-sandbox-project-id
gcloud config set project "$GCP_PROJECT"
gcloud config list  # confirm project is set
```

### 3. Enable required APIs

```bash
gcloud services enable \
  sqladmin.googleapis.com \
  storage.googleapis.com \
  redis.googleapis.com \
  pubsub.googleapis.com \
  bigquery.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com
```

### 4. Approve the service account, roles, and private network

```bash
SA_NAME=csb-gcp-sandbox-broker
SA_EMAIL="${SA_NAME}@${GCP_PROJECT}.iam.gserviceaccount.com"
```

`SECURITY_USER_NAME` is the Cloud Foundry broker API user; it is not the GCP
execution identity. Create and review the provider-qualified service account and
the least-privilege roles required for the approved catalog. Do not grant the
upstream documented Project Owner role by default. Select a network in the same
project with active `servicenetworking.googleapis.com` peering; do not use the
Cloud SQL default-network fallback.

### 5. Create the environment file

```bash
bash scripts/iam-bootstrap-gcp.sh "$SA_NAME" "$GCP_PROJECT" \
  "https://www.googleapis.com/compute/v1/projects/$GCP_PROJECT/global/networks/<approved-private-network>"
```

The helper creates a temporary key file with restrictive permissions, removes it
on exit, writes `scripts/envs/gcp.env` atomically with mode `0600`, and never
prints the service-account key JSON. Verify only the file presence and mode:

```bash
test -f scripts/envs/gcp.env && test "$(stat -c '%a' scripts/envs/gcp.env)" = 600
```
```

## Refresh local AI model catalogs

Use the catalog refresh helper to enumerate the currently available model IDs and
the metadata exposed by each cloud CLI, then write that data into local JSON cache
files under `.cache/model-catalogs/`.

```bash
# Refresh all three CSP catalogs
pnpm run catalog:refresh

# Refresh one provider at a time
pnpm run catalog:refresh:aws -- --aws-region us-east-1
pnpm run catalog:refresh:azure -- --azure-location eastus2
pnpm run catalog:refresh:gcp -- --gcp-project "$GCP_PROJECT"
```

Files written by default:

- `.cache/model-catalogs/aws-bedrock-<region>.json`
- `.cache/model-catalogs/azure-openai-<location>.json`
- `.cache/model-catalogs/gcp-vertex-model-garden-<project>.json`
- `.cache/model-catalogs/gcp-gemini-api-<project>.json`

Auth behavior:

- AWS: uses the current `AWS_*` environment or profile first; if absent, it falls back to `scripts/envs/aws.env`.
- Azure: uses the active `az` session, or logs in with the `ARM_*` service-principal values from `scripts/envs/azure.env` when present.
- GCP: prefers `scripts/envs/gcp.env` and normalizes its `GOOGLE_CREDENTIALS` value into a temporary key file for `gcloud`; otherwise, use interactive auth:

```bash
gcloud auth login --update-adc
gcloud config set project "$GCP_PROJECT"
gcloud auth application-default set-quota-project "$GCP_PROJECT"
```

Cache contract notes:

- Each file includes a `provisioner_contract` block that lifts the model IDs or deployment objects most directly reusable by the broker plan inputs.
- Pricing and context-window fields are populated only when the cloud CLI exposes them. When the provider CLI does not return those fields, the cache stores `null` and preserves the raw provider payload alongside the normalized record.

---

## Deploy after credential setup

Do not populate all environment files or deploy all brokers as a batch. Proceed
with one provider only after its service approval, provider identity scope,
private-network/egress prerequisites, package validation, and cleanup plan have
been recorded. The Azure credential file remains blocked until its
catalog-specific role design is approved.

```bash
# Provision the shared backing database (creates csb-sql if absent)
pnpm run broker:db

# Deploy one approved broker only
pnpm run broker:deploy:aws

# Verify
pnpm run broker:status
cf marketplace -e csb-aws-sandbox
```

---

## Credential rotation

| Provider | Rotation approach | Action after rotation |
| -------- | ----------------- | --------------------- |
| AWS | Use the approved bootstrap workflow only after verifying the prior key and private-placement inputs. | Securely replace `aws.env`, then redeploy the approved broker. |
| Azure | Use an explicitly approved identity rotation change; never reset a secret implicitly. | Update controlled secret delivery and validate the approved scope. |
| GCP | Use the approved bootstrap workflow after verifying the service account, private network, and peering. | Securely replace `gcp.env`, then redeploy the approved broker. |

Rotate credentials whenever:

- A team member with access departs
- A credential is suspected of compromise
- Scheduled rotation interval (90 days per GSA CIO-IT Security-01-07) is reached

---

## Security notes

- `.env` files are git-ignored. Confirm with `git check-ignore scripts/envs/aws.env`.
- Pre-commit `gitleaks` hook blocks accidental credential commits.
- CSP credentials are injected at `cf push` time via manifest `env:` block and do not persist in the CF environment long-term. Migrate to CredHub variable bindings for production hardening (see the commented-out `CH_*` variables in each `.env.example`).
- AWS IAM user access keys expire after 90 days per GSA key rotation policy; set a calendar reminder.
