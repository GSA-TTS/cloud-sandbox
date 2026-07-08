#!/usr/bin/env bash
set -euo pipefail

# IAM bootstrap for AWS broker service user
# Creates a least-privileged IAM user for broker provisioning and outputs access keys for CI
# Usage: bash scripts/iam-bootstrap-aws.sh <username> <aws_profile>

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <username> <aws_profile>" >&2
  exit 1
fi

USER_NAME="$1"
PROFILE="$2"

# Policy document for broker provisioning (Bedrock, S3, RDS, etc.)
POLICY_NAME="cloud-sandbox-broker-provisioning"
POLICY_DOC="/tmp/${POLICY_NAME}.json"

cat > "$POLICY_DOC" <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:ListFoundationModels",
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream",
        "iam:PassRole",
        "s3:CreateBucket",
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:DeleteBucket",
        "rds:CreateDBInstance",
        "rds:DeleteDBInstance",
        "rds:DescribeDBInstances",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource",
        "rds:ListTagsForResource",
        "sqs:CreateQueue",
        "sqs:DeleteQueue",
        "sqs:GetQueueAttributes",
        "sqs:SetQueueAttributes"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam create-user --user-name "$USER_NAME" --profile "$PROFILE" || true
aws iam put-user-policy --user-name "$USER_NAME" --policy-name "$POLICY_NAME" --policy-document "file://$POLICY_DOC" --profile "$PROFILE"

# Create access key (rotatable)
aws iam create-access-key --user-name "$USER_NAME" --profile "$PROFILE" > aws-access-key.json

cat <<EOM

AWS access key created and written to aws-access-key.json
To rotate, run:
  aws iam create-access-key --user-name $USER_NAME --profile $PROFILE

To configure for CI, copy these values to aws.env:
  AWS_ACCESS_KEY_ID=...
  AWS_SECRET_ACCESS_KEY=...
  AWS_REGION=...

EOM
