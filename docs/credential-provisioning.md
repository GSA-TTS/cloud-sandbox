# Credential Provisioning Guide

Step-by-step instructions for provisioning the IAM credentials required by each
CSB brokerpak using the official CLI for each cloud provider.

When complete, each section ends with writing the generated credentials to
the appropriate `scripts/envs/<provider>.env` file. **Never commit `.env` files —
they are git-ignored.**

---

## AWS — `aws-cli`

### 1. Install

```bash
brew install awscli
aws --version   # aws-cli/2.x
```

### 2. Authenticate (admin session to bootstrap the IAM user)

Use an account with IAM write access (AdministratorAccess or equivalent).

```bash
aws configure
# AWS Access Key ID:     <your admin key>
# AWS Secret Access Key: <your admin secret>
# Default region name:   us-east-1
# Default output format: json
```

Or via SSO (recommended for GSA):

```bash
aws configure sso
# SSO start URL:  https://gsa.awsapps.com/start
# SSO region:     us-east-1
# (follow browser prompt)
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
        "rds:ModifyDBInstance",
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

### 4. Create the policy and IAM user, attach the policy

```bash
POLICY_ARN=$(aws iam create-policy \
  --policy-name csb-sandbox-broker \
  --description "Min permissions for TTS Cloud Sandbox CSB AWS broker" \
  --policy-document file:///tmp/csb-aws-policy.json \
  --query 'Policy.Arn' --output text)
echo "Policy ARN: $POLICY_ARN"

aws iam create-user --user-name csb-sandbox-broker \
  --tags Key=Project,Value=tts-sandbox Key=Owner,Value=tts-techops@gsa.gov

aws iam attach-user-policy \
  --user-name csb-sandbox-broker \
  --policy-arn "$POLICY_ARN"
```

### 5. Generate access key credentials

```bash
aws iam create-access-key \
  --user-name csb-sandbox-broker \
  --query 'AccessKey.[AccessKeyId,SecretAccessKey]' \
  --output text
# Output (two tab-separated values):
# AKIAIOSFODNN7EXAMPLE    wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

Get your sandbox VPC ID:

```bash
aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=sandbox*" \
  --query 'Vpcs[0].VpcId' --output text
# vpc-XXXXXXXX
```

### 6. Save credentials to `.env`

```bash
cp scripts/envs/aws.env.example scripts/envs/aws.env

# Fill in the three values from steps 5 above (replace the EXAMPLE placeholders):
sed -i '' \
  -e 's/AWS_ACCESS_KEY_ID=.*/AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE/' \
  -e 's/AWS_SECRET_ACCESS_KEY=.*/AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI\/K7MDENG\/bPxRfiCYEXAMPLEKEY/' \
  -e 's/AWS_PAS_VPC_ID=.*/AWS_PAS_VPC_ID=vpc-XXXXXXXX/' \
  -e 's/GSB_PROVISION_DEFAULTS=.*/GSB_PROVISION_DEFAULTS='"'"'{"aws_vpc_id":"vpc-XXXXXXXX"}'"'"'/' \
  scripts/envs/aws.env

# Also set a strong random broker password:
PASS=$(openssl rand -base64 32 | tr -d '\n/')
sed -i '' "s/SECURITY_USER_PASSWORD=.*/SECURITY_USER_PASSWORD=${PASS}/" scripts/envs/aws.env
```

Verify the file looks correct before deploying:

```bash
grep -E '^(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_PAS_VPC_ID|SECURITY_USER_PASSWORD)=' \
  scripts/envs/aws.env
```

---

## Azure — `azd` + `az`

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

### 3. Create the service principal

```bash
TENANT_ID=$(az account show --query tenantId --output tsv)
echo "Tenant ID: $TENANT_ID"

# Create SP with Contributor on the subscription
SP_JSON=$(az ad sp create-for-rbac \
  --name csb-sandbox-broker \
  --role Contributor \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  --output json)

CLIENT_ID=$(echo "$SP_JSON"     | python3 -c "import sys,json; print(json.load(sys.stdin)['appId'])")
CLIENT_SECRET=$(echo "$SP_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")
echo "Client ID:     $CLIENT_ID"
echo "Client Secret: $CLIENT_SECRET"
```

### 4. Assign the User Access Administrator role (required for role assignments in brokerpak)

```bash
OBJECT_ID=$(az ad sp show --id "$CLIENT_ID" --query id --output tsv)

az role assignment create \
  --assignee-object-id "$OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID"
```

### 5. Save credentials to `.env`

```bash
cp scripts/envs/azure.env.example scripts/envs/azure.env

sed -i '' \
  -e "s|ARM_TENANT_ID=.*|ARM_TENANT_ID=${TENANT_ID}|" \
  -e "s|ARM_SUBSCRIPTION_ID=.*|ARM_SUBSCRIPTION_ID=${SUBSCRIPTION_ID}|" \
  -e "s|ARM_CLIENT_ID=.*|ARM_CLIENT_ID=${CLIENT_ID}|" \
  -e "s|ARM_CLIENT_SECRET=.*|ARM_CLIENT_SECRET=${CLIENT_SECRET}|" \
  scripts/envs/azure.env

PASS=$(openssl rand -base64 32 | tr -d '\n/')
sed -i '' "s/SECURITY_USER_PASSWORD=.*/SECURITY_USER_PASSWORD=${PASS}/" scripts/envs/azure.env
```

Verify:

```bash
grep -E '^ARM_(TENANT_ID|SUBSCRIPTION_ID|CLIENT_ID|CLIENT_SECRET)=' \
  scripts/envs/azure.env
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

### 4. Create the service account and assign IAM roles

```bash
SA_NAME=csb-sandbox-broker
SA_EMAIL="${SA_NAME}@${GCP_PROJECT}.iam.gserviceaccount.com"

# Create the service account
gcloud iam service-accounts create "$SA_NAME" \
  --display-name "TTS Cloud Sandbox CSB GCP Broker" \
  --description "Min permissions for csb-brokerpak-gcp"

# Assign minimum required roles
for ROLE in \
  roles/cloudsql.admin \
  roles/storage.admin \
  roles/redis.admin \
  roles/pubsub.admin \
  roles/bigquery.dataEditor \
  roles/bigquery.jobUser \
  roles/iam.serviceAccountAdmin \
  roles/iam.roleAdmin \
  roles/resourcemanager.projectIamAdmin; do
  gcloud projects add-iam-policy-binding "$GCP_PROJECT" \
    --member "serviceAccount:${SA_EMAIL}" \
    --role "$ROLE" \
    --quiet
done
```

### 5. Generate and download key

```bash
KEY_FILE=/tmp/csb-gcp-sa-key.json

gcloud iam service-accounts keys create "$KEY_FILE" \
  --iam-account="$SA_EMAIL"

echo "Key written to $KEY_FILE"
cat "$KEY_FILE"   # inspect before storing
```

### 6. Save credentials to `.env`

The brokerpak requires the entire service account JSON as a single-line value
for `GOOGLE_CREDENTIALS`. The helper below compacts it and escapes it for the
shell assignment:

```bash
cp scripts/envs/gcp.env.example scripts/envs/gcp.env

# Compact JSON to single line
CREDS=$(python3 -c "import json,sys; print(json.dumps(json.load(open('$KEY_FILE'))))")

# Write into the .env file — use Python to safely handle the nested quotes
python3 - "$GCP_PROJECT" "$CREDS" << 'PYEOF'
import sys, re

project = sys.argv[1]
creds   = sys.argv[2]
path    = 'scripts/envs/gcp.env'

with open(path) as f:
    content = f.read()

content = re.sub(r"^GOOGLE_CREDENTIALS=.*$", f"GOOGLE_CREDENTIALS='{creds}'",
                 content, flags=re.MULTILINE)
content = re.sub(r"^GOOGLE_PROJECT=.*$", f"GOOGLE_PROJECT={project}",
                 content, flags=re.MULTILINE)

with open(path, 'w') as f:
    f.write(content)

print("gcp.env updated")
PYEOF

# Set a strong random broker password
PASS=$(openssl rand -base64 32 | tr -d '\n/')
sed -i '' "s/SECURITY_USER_PASSWORD=.*/SECURITY_USER_PASSWORD=${PASS}/" scripts/envs/gcp.env
```

Clean up the key file from disk once it is in the `.env`:

```bash
rm "$KEY_FILE"
```

Verify:

```bash
grep -E '^(GOOGLE_PROJECT|GOOGLE_CREDENTIALS)=' scripts/envs/gcp.env | \
  sed 's/\(GOOGLE_CREDENTIALS=\).\{0,80\}.*/\1<redacted>/'
```

---

## Deploy after credential setup

With all three `.env` files populated, deploy the brokers:

```bash
# Provision the shared backing database (creates csb-sql if absent)
pnpm run broker:db

# Deploy individual brokers
pnpm run broker:deploy:aws
pnpm run broker:deploy:gcp
pnpm run broker:deploy:azure

# Or all at once
pnpm run broker:deploy:all

# Verify
pnpm run broker:status
cf marketplace -e csb-aws-sandbox
```

---

## Credential rotation

| Provider | Rotation command                                                                            | Action after rotation                                       |
| -------- | ------------------------------------------------------------------------------------------- | ----------------------------------------------------------- |
| AWS      | `aws iam create-access-key --user-name csb-sandbox-broker` then `aws iam delete-access-key` | Update `aws.env`, redeploy via `pnpm run broker:deploy:aws` |
| Azure    | `az ad sp credential reset --id <CLIENT_ID>`                                                | Update `azure.env`, redeploy                                |
| GCP      | `gcloud iam service-accounts keys create` then delete old key                               | Update `gcp.env`, redeploy                                  |

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
