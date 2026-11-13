#!/usr/bin/env bash
set -euo pipefail

# Create an AWS broker access key and securely write scripts/envs/aws.env.
# The IAM user and its reviewed broker policy must already exist. This script never
# deploys a broker and never prints an access-key secret.
# Usage: bash scripts/iam-bootstrap-aws.sh <username> <aws-profile> <region> <vpc-id> <rds-subnet-group> <rds-security-group-ids> <elasticache-subnet-group> <elasticache-security-group-ids>

umask 077
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_WRITER="$ROOT_DIR/scripts/lib/write-broker-env.py"
TEMPLATE="$ROOT_DIR/scripts/envs/aws.env.example"
ENV_FILE="$ROOT_DIR/scripts/envs/aws.env"

if [[ $# != 8 ]]; then
  echo "Usage: $0 <username> <aws-profile> <region> <vpc-id> <rds-subnet-group> <rds-security-group-ids> <elasticache-subnet-group> <elasticache-security-group-ids>" >&2
  exit 1
fi

USER_NAME="$1"
PROFILE="$2"
AWS_DEFAULT_REGION="$3"
AWS_PAS_VPC_ID="$4"
RDS_SUBNET_GROUP="$5"
RDS_VPC_SECURITY_GROUP_IDS="$6"
ELASTICACHE_SUBNET_GROUP="$7"
ELASTICACHE_VPC_SECURITY_GROUP_IDS="$8"

aws sts get-caller-identity --profile "$PROFILE" --output json >/dev/null
aws ec2 describe-vpcs --region "$AWS_DEFAULT_REGION" --profile "$PROFILE" --vpc-ids "$AWS_PAS_VPC_ID" --output json >/dev/null

[[ $(aws rds describe-db-subnet-groups --region "$AWS_DEFAULT_REGION" --profile "$PROFILE" --db-subnet-group-name "$RDS_SUBNET_GROUP" --query 'DBSubnetGroups[0].VpcId' --output text) == "$AWS_PAS_VPC_ID" ]] || {
  echo "ERROR: RDS subnet group must belong to the approved VPC." >&2
  exit 1
}
[[ $(aws elasticache describe-cache-subnet-groups --region "$AWS_DEFAULT_REGION" --profile "$PROFILE" --cache-subnet-group-name "$ELASTICACHE_SUBNET_GROUP" --query 'CacheSubnetGroups[0].VpcId' --output text) == "$AWS_PAS_VPC_ID" ]] || {
  echo "ERROR: ElastiCache subnet group must belong to the approved VPC." >&2
  exit 1
}
for group_id in ${RDS_VPC_SECURITY_GROUP_IDS//,/ }; do
  [[ $(aws ec2 describe-security-groups --region "$AWS_DEFAULT_REGION" --profile "$PROFILE" --group-ids "$group_id" --query 'SecurityGroups[0].VpcId' --output text) == "$AWS_PAS_VPC_ID" ]] || {
    echo "ERROR: RDS security groups must belong to the approved VPC." >&2
    exit 1
  }
done
for group_id in ${ELASTICACHE_VPC_SECURITY_GROUP_IDS//,/ }; do
  [[ $(aws ec2 describe-security-groups --region "$AWS_DEFAULT_REGION" --profile "$PROFILE" --group-ids "$group_id" --query 'SecurityGroups[0].VpcId' --output text) == "$AWS_PAS_VPC_ID" ]] || {
    echo "ERROR: ElastiCache security groups must belong to the approved VPC." >&2
    exit 1
  }
done
aws iam get-user --user-name "$USER_NAME" --profile "$PROFILE" --output json >/dev/null

key_count=$(aws iam list-access-keys --user-name "$USER_NAME" --profile "$PROFILE" --query 'length(AccessKeyMetadata)' --output text)
if [[ "$key_count" -ge 2 ]]; then
  echo "ERROR: $USER_NAME already has two access keys; retire a verified old key before rotating." >&2
  exit 1
fi

key_json=$(aws iam create-access-key --user-name "$USER_NAME" --profile "$PROFILE" --output json)
AWS_ACCESS_KEY_ID=$(jq -er '.AccessKey.AccessKeyId' <<<"$key_json")
AWS_SECRET_ACCESS_KEY=$(jq -er '.AccessKey.SecretAccessKey' <<<"$key_json")
SECURITY_USER_PASSWORD=$(openssl rand -base64 48 | tr -d '\n/' | cut -c1-40)
GSB_PROVISION_DEFAULTS=$(printf '{"aws_vpc_id":"%s","rds_subnet_group":"%s","rds_vpc_security_group_ids":"%s","elasticache_subnet_group":"%s","elasticache_vpc_security_group_ids":"%s"}' "$AWS_PAS_VPC_ID" "$RDS_SUBNET_GROUP" "$RDS_VPC_SECURITY_GROUP_IDS" "$ELASTICACHE_SUBNET_GROUP" "$ELASTICACHE_VPC_SECURITY_GROUP_IDS")

export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION AWS_PAS_VPC_ID RDS_SUBNET_GROUP RDS_VPC_SECURITY_GROUP_IDS ELASTICACHE_SUBNET_GROUP ELASTICACHE_VPC_SECURITY_GROUP_IDS SECURITY_USER_PASSWORD GSB_PROVISION_DEFAULTS
python3 "$ENV_WRITER" "$TEMPLATE" "$ENV_FILE" \
  AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_DEFAULT_REGION AWS_PAS_VPC_ID RDS_SUBNET_GROUP RDS_VPC_SECURITY_GROUP_IDS ELASTICACHE_SUBNET_GROUP ELASTICACHE_VPC_SECURITY_GROUP_IDS SECURITY_USER_PASSWORD GSB_PROVISION_DEFAULTS

echo "Wrote $ENV_FILE with mode 0600. No broker was deployed."
