# AWS Service Dependencies & Integrations Reference

AWS and third-party service dependencies extracted from approval documentation.

## AWS CodeBuild

**Source:** [AWS CodeBuild.md](AWS CodeBuild.md)
**FedRAMP Status:** Not approved / Not reviewed

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| S3 | Yes | Yes |
| IAM | Yes | Yes |
| KMS | Yes | Yes |
| AWS CodePipeline | No | Not Reviewed |

### Third-Party Integrations

| Service Name | GSA Approved |
|------------|------------|
| Jenkins | Listed as exception on GEAR |
| GitHub | Yes |
| BitBucket | Not approved in favor of GitHub |

## AWS CodePipeline

**Source:** [AWS CodePipeline.md](AWS CodePipeline.md)
**FedRAMP Status:** Not approved / Not reviewed

### AWS Service Dependencies

| Service Name | [Fed Ramped?](https://aws.amazon.com/compliance/services-in-scope/) | GSA Approved |
|------------|-------------------------------------------------------------------|------------|
| S3 | Yes | Yes |
| CodeCommit | No | Yes |
| CodeBuild | No | In Progress |
| CodeDeploy | No | In Progress |
| CloudFormation | Yes | Yes |
| ECS | No | No |
| Elastic Beanstalk | No | Not Reviewed |
| OpsWorksStack | No | Not Reviewed |
| SNS | Yes | Yes |
| Lambda | In Progress | Yes |
| CloudTrail | Yes | Yes |
| CloudWatch | Yes | Yes |
| KMS | Yes | Yes |

### Third-Party Integrations

| Service Name | GSA Approved |
|------------|------------|
| GitHub | Yes |
| CloudBees | Not listed in GEAR |
| Jenkins | Yes |
| Solano CI | Not listed in GEAR |
| TeamCity | Not listed in GEAR |
| Apica | Not listed in GEAR |
| BlazeMeter | Not listed in GEAR |
| Ghost Inspector | Not listed in GEAR |
| HPE StormRunner Load | Not listed in GEAR |
| Nouvola | Not listed in GEAR |
| Runscope | Not listed in GEAR |
| XebiaLabs | Not listed in GEAR |

## AWS CodeStar

**Source:** [AWS CodeStar.md](AWS CodeStar.md)
**FedRAMP Status:** Not approved / Not reviewed

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| S3 | Yes | Yes |
| IAM | Yes | Yes |
| KMS | Yes | Yes |
| AWS CodePipeline | No | Not Reviewed |
| AWS CodeBuild | No | Not Reviewed |
| CloudWatch | Yes | Yes |
| AWS Elastic Beanstalk | No | Not Reviewed |
| Cloud9 | No | No |
| Lambda | In Progress | Yes |
| AutoScaling | Yes | Yes |

### Third-Party Integrations

| Service Name | GSA Approved |
|------------|------------|
| Eclipse | Unisys ClearPath is Approved |
| GitHub | Yes |
| Visual Studio | 2012 is Approved |
| Atlassian JIRA | Yes |

## AWS ElasticSearch Service

**Source:** [AWS ElasticSearch.md](AWS ElasticSearch.md)
**FedRAMP Status:** Not approved / Not reviewed

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| S3 | Yes | Yes |
| IAM | Yes | Yes |
| KMS | Yes | Yes |
| CloudWatch | Yes | Yes |
| Lambda | In Progress | Yes |
| Kineis Streams | Yes | Yes |
| DynamoDB | Yes | Yes |

### Third-Party Integrations

| Service Name | GSA Approved |
|------------|------------|
| LogStash Plugin | Yes with Exception |
| Other Elasticsearch Plugins | No |

## Resource Access Manager

**Source:** [AWS Service - Resource Access Manager.md](AWS Service - Resource Access Manager.md)
**FedRAMP Status:** Not approved / Not reviewed

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| Amazon Aurora | Yes | Yes |
| AWS Codebuild | Yes | Yes |
| Amazon EC2 | Yes | Yes |
| Amazon EC2 Image Builder | No | No |
| AWS License Manager | Yes | No |
| AWS Resource Group | No | No |

## Secrets Manager

**Source:** [AWS Service - Secrets Manager.md](AWS Service - Secrets Manager.md)
**FedRAMP Status:** Not approved / Not reviewed

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| AWS CloudTrail | Yes | Yes |
| Amazon RDS | Yes | Yes |
| KMS | Yes | Yes |
| Lambda | Yes | Yes |

## XRAY

**Source:** [AWS Service - XRAY.md](AWS Service - XRAY.md)
**FedRAMP Status:** Not approved / Not reviewed

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| API Gateway | Yes | Yes |
| APP Mesh | No | No |
| AWS AppSync | No | No |
| CloudTrail | Yes | Yes |
| CloudWatch | Yes | Yes |
| AWS Config | Yes | Yes |
| Amazon EC2 | Yes | Yes |
| Elastic Beanstalk | Yes | Yes |
| Elastic Load Balancing | Yes | Yes |
| Lambda | Yes | Yes |
| Amazon SNS | Yes | Yes |
| Step Functions | Yes | Yes |
| Amazon SQS | Yes | Yes |

## Cloud9

**Source:** [Cloud9.md](Cloud9.md)
**FedRAMP Status:** Not approved / Not reviewed

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| IAM | Yes | Yes |
| Cloudtrail | Yes | Yes |
| Cloudwatch | Yes | Yes |
| Lambda | Yes | Yes |
| AWS CLI (this expands integrations to all of AWS that is accessible through CLI) | Yes | Yes |

## AWS Amazon Managed Streaming for Apache Kafka (Amazon MSK)

**Source:** [ISE AWS Amazon Managed Streaming for Apache Kafka (Amazon MSK).md](ISE AWS Amazon Managed Streaming for Apache Kafka (Amazon MSK).md)
**FedRAMP Status:** Not approved / Not reviewed

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| AWS Identity & Access Management (IAM) | Yes | Yes |
| AWS EC2 | Yes | Yes |

## AWS Bedrock

**Source:** [ISE AWS Bedrock.md](ISE AWS Bedrock.md)
**FedRAMP Status:** FedRAMP Approved

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| CloudWatch | Yes | Yes |
| CloudTrail | Yes | Yes |
| S3 | Yes | Yes |
| EC2 | Yes | Yes |
| SageMaker |  |  |
| API Gateway |  |  |
| Lambda |  |  |
| DynamoDB |  |  |
| Comprehend |  |  |
| Kendra |  |  |
| Lex |  |  |
| Polly |  |  |
| Rekognition |  |  |

### Third-Party Integrations

| Service Name | GSA Approved In GEAR |
|------------|--------------------|
| TensorFlow | Approved for Pilot |
| Jupyter | [Yes](https://ea.gsa.gov/#!/itstandards/1876%20) |
| Apache Spark | Approved |
| Docker | Approved |
| MXNet | Not Yet |

## AWS Elastic Container Registry

**Source:** [ISE AWS ECR Review .md](ISE AWS ECR Review .md)
**FedRAMP Status:** Not approved / Not reviewed

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| Amazon ECS | No | Yes with Conditions |
| Amazon EKS | No | Yes with Conditions |

## AWS Elastic Container Service (ECS)**

**Source:** [ISE AWS ECS and Fargate Service Review.md](ISE AWS ECS and Fargate Service Review.md)
**FedRAMP Status:** Approve East/West/GovCloud

### AWS Service Dependencies

| Service Name | [FedRAMPed?](https://aws.amazon.com/compliance/services-in-scope/) | GSA Approved |
|------------|------------------------------------------------------------------|------------|
| IAM | Yes | Yes |
| EC2 Auto Scaling | Yes | Yes |
| Elastic Load Balancing | Yes | Yes |
| Elastic Container Registry | Yes | Yes |
| CloudFormation | Yes | Yes |
| Fargate | Yes (East/West) | Yes |
| EFS | Yes | Yes |

## AWS Elastic Container Service for Kubernetes (EKS)

**Source:** [ISE AWS EKS.md](ISE AWS EKS.md)
**FedRAMP Status:** Approved in AWS East/West, under JAB review in GovCloud (as of 2020/12/01)Not approved / Not reviewed

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| Elastic Load Balancing | Yes | Yes |
| IAM | Yes | Yes |
| PrivateLink | No | Pending Review |
| CloudTrail | Yes | Yes |

## AWS Firewall Manager

**Source:** [ISE AWS Firewall Manager.md](ISE AWS Firewall Manager.md)
**FedRAMP Status:** FedRAMP Approved East / West

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| AWS Organization | Not Reviewed | Yes |
| IAM | Yes | Yes |
| AWS Config | In Progress | Yes |
| AWS ELB | Yes | Yes |
| AWS CloudFront | Not Reviewed | Yes |
| AWS WAF | In Progress | Yes |
| AWS SNS | Yes | Yes |

### Third-Party Integrations

| Service Name | GSA Approved |
|------------|------------|
| Managed WAF rules available at AWS marketplace provided by vendors like F5, Alert Logic, Fortinet, Imperva etc | Not listed in GEAR but waf from similar vendor are in use in GSA (Eg: F5,Netscaler) |

## AWS Kinesis Data FireHose

**Source:** [ISE AWS Kinesis Data FireHose Review.md](ISE AWS Kinesis Data FireHose Review.md)
**FedRAMP Status:** [Authorized](https://aws.amazon.com/compliance/services-in-scope/FedRAMP/)

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| AWS Kinesis Datastream | Yes | Yes |
| AWS SQS | Yes | Yes |
| AWS S3 | Yes | Yes |
| AWS Lambda | Yes | Yes |
| AWS Redshift | Yes | Yes |
| AWS Elasticsearch Service | For GovCloud, not East/West Regions. Currently under Jab Review | Yes |
| AWS IOT | No | No |

## AWS SageMaker

**Source:** [ISE AWS SageMaker.md](ISE AWS SageMaker.md)
**FedRAMP Status:** FedRAMP Approved

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| CloudWatch | Yes | Yes |
| CloudTrail | Yes | Yes |
| S3 | Yes | Yes |
| EC2 | Yes | Yes |

### Third-Party Integrations

| Service Name | GSA Approved In GEAR |
|------------|--------------------|
| TensorFlow | Approved for Pilot |
| Jupyter | [Yes](https://ea.gsa.gov/#!/itstandards/1876%20) |
| Apache Spark | Approved |
| Docker | Approved |
| MXNet | Not Yet |

## AWS Certificate Manager (ACM)

**Source:** [ISE AWS Service Review - AWS Certificate Manager.md](ISE AWS Service Review - AWS Certificate Manager.md)
**FedRAMP Status:** Not reviewed/ Under Review

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| Elastic Load Balancing | Yes | Yes |
| Amazon CloudFront | Yes | Yes |
| AWS Elastic Beanstalk | Yes | Yes |
| Amazon API Gateway | Yes | Yes |
| AWS CloudFormation | Yes | Yes |
| AWS KMS | Yes | Yes |

## ISE AWS Service SSM Incident Manager

**Source:** [ISE AWS Service SSM Incident Manager.md](ISE AWS Service SSM Incident Manager.md)
**FedRAMP Status:** approved

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| System Manager | Yes | Yes |
| EventBridge | Yes | Yes |
| CloudWatch | Yes | Yes |
| Lambda | Yes | Yes |
| Simple Notification Service (SNS) | Yes | Yes |
| IAM | Yes | Yes |

### Third-Party Integrations

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| New Relic | Yes | Yes |
| Slack | Yes | Yes |
| MS Teams | Yes | Yes |
| AWS Chime | Yes | Yes |

## Transfer Family

**Source:** [Transfer Family.md](Transfer Family.md)
**FedRAMP Status:** Not approved / Not reviewed

### AWS Service Dependencies

| Service Name | Fed Ramped? | GSA Approved |
|------------|-----------|------------|
| IAM | Yes | Yes |
| Cloudtrail | Yes | Yes |
| Cloudwatch | Yes | Yes |
| Lambda | Yes | Yes |
| API Gateway | Yes | Yes |
| S3 | Yes | Yes |
| EFS | Yes | Yes |
| KMS | Yes | Yes |
| VPC | Yes | Yes |
| ACM | Yes | Yes |

