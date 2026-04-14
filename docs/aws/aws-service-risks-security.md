# AWS Service Risks & Security Considerations

Identified risks, caveats, and security recommendations per service.

## AWS API Gateway

**Source:** [API Gateway.md](API Gateway.md)
**FedRAMP Status:** FedRAMP Approved East / West Only

### Identified Risks

1. Interception of data in transit

### Use Caveats

1. The use of this service shall abide to GSA requirements for security of data in transit and at rest based on the classification of the data.
2. The use of this requires enablement of logging associated with this service.

## AWS CodeBuild

**Source:** [AWS CodeBuild.md](AWS CodeBuild.md)
**FedRAMP Status:** Not approved / Not reviewed

### Identified Risks

1. Its unknown where AWS keeps Job History

### Use Caveats

1. Third party integrations shall be limited to only those that are FedRAMP or GSA authorized to operate.
2. CodeBuild Artifacts must be stored on an encrypted S3 bucket
3. CodePipeline must be used in accordance with GSA’s [requirements](https://docs.google.com/document/d/13ppp4CaUEImm22TEemvh5ssOg9HrNPNXoXmLQ6Sg7ng/edit)

**Links to additional information:**  
User G

## AWS CodeCommit

**Source:** [AWS CodeCommit.md](AWS CodeCommit.md)
**FedRAMP Status:** Not approved / Not Reviewed

### Identified Risks

1. Any IAM user with the following policies set to “Deny” would experience issues with CodeCommit:
   1. "kms:Encrypt"
   2. "kms:Decrypt"
   3. "kms:ReEncrypt"
   4. kms:GenerateDataKey"
   5.

### Use Caveats

1. KMS must be in used in accordance with [KMS Use Caveats.](https://docs.google.com/document/d/1QLTi6EaQVE1pGqyq9lGmqCisWY9DiEmYa-w-NXIjZeE/edit)
2. CloudTrail must be enabled to capture log information.

**Links to additional information:**  
[https://aws.amazon.com/documentation/codecommit/](https://aws.amazon.com/documentation/codecommit/)

## AWS CodePipeline

**Source:** [AWS CodePipeline.md](AWS CodePipeline.md)
**FedRAMP Status:** Not approved / Not reviewed

### Identified Risks

1. CloudPipeline can integrate with several services not approved for GSA use.
2. Misconfigurations could negatively impact production.
3. Default S3 bucket holding source code is not encrypted by default

### Use Caveats

1. Third Party Providers shall be limited to SaaS that either GSA or FedRAMP authorized.
2. CodePipeline Sources:
   1. S3 (Must encrypt with [KMS](https://docs.google.com/document/d/1QLTi6EaQVE1pGqyq9lGmqCisWY9DiEmYa-w-NXIjZeE/edit))
   2. CodeCommit: Must adhere to service use [caveats
3. CodePipeline Build:
   1. Jenkins: If using Jenkins, ensure its configure to accept HTTPS/SSL connections only.
   2. CodeBuild: Must adhere to service use [caveats](https://docs.google.com/docum
4. Deploy
   1. Cannot use ECS, Elastic Beanstalk, or OpsWork as they are not approved services.
   2. CloudDeploy. Must adhere to service use [caveats](https://docs.google.com/document/d/1zhNqjREyq

## AWS CodeStar

**Source:** [AWS CodeStar.md](AWS CodeStar.md)
**FedRAMP Status:** Not approved / Not reviewed

### Identified Risks

1. Using the any EC2 template will result in a security group with 0.0.0.0/0 configurations for port 22 and 80\. Please follow the caveats below to mitigate this risk.
2. Default S3 buckets created to hold source code and ssh authorized keys are not encrypted by default.

### Use Caveats

1. Any related CodeStar Ec2 instance must have encrypted EBS volumes.
2. Security Groups: Encrypted data flows must be configured i.e. 443 https and 22 ssh. 0.0.0.0/0 configurations are not permissible and shall be updated to reflect minimum required flows. Security group
3. The S3 buckets in use need to be encrypted with KMS.
4. The other services used ([CodePipeline](https://docs.google.com/document/d/13ppp4CaUEImm22TEemvh5ssOg9HrNPNXoXmLQ6Sg7ng/edit), [CodeDeploy](https://docs.google.com/document/d/16gF_WC_dk1FINQJv7Vn8Sx-E
5. Cannot use with Cloud9 IDE.
6. Upon deletion of the project, almost all AWS assets are automatically removed and terminated. However the S3 buckets created are not deleted and must be manually removed.

\*\*Links to additional infor

## AWS ElasticSearch Service

**Source:** [AWS ElasticSearch.md](AWS ElasticSearch.md)
**FedRAMP Status:** Not approved / Not reviewed

### Identified Risks

1. T2, M3, and R3 instance types do not support encryption at rest.
2. All EC2 operations are masked behind the service and there is no end user access.

### Use Caveats

1. EBS encryption is not available to T2, M3, and R3 instances do not support encryption for data at rest and therefore cannot be used.
2. Ensure VPC, IAM, and Security Group access is least privileged when provisioning a domain.
3. All streaming data options must have HTTPS enforced

**Links to additional information:**  
User Guide: [https://docs.aws.amazon.com/elasticsearch-service/latest/developerguide/what-is-amazon-elasti

## AWS QuickSight

**Source:** [AWS QuickSight.md](AWS QuickSight.md)
**FedRAMP Status:** FedRAMP Approved Commercial East/West (Moderate) and GovCloud (High)

### Identified Risks

1. Large amounts of data can be stored within QuickSight SPICE with AWS managed keys; ~~ISE recommends SPICE usage be prohibited for this reason~~. UPDATE: Risk is reduced with new features that exist wi
2. Connectivity to data sources outside AWS can be unencrypted; connections can be forced over TLS.
3. Dashboards and analysis can be shared and are web accessible; access is controlled to authorized users and can be forced to use MFA.

### Use Caveats

1. AWS QuickSight is approved with Direct Query of databases in AWS only; SPICE (which stores data in QuickSight with AWS managed keys) is prohibited. \*\*UPDATE (enable this [feature](https://docs.aws.ama
2. QuickSight is NOT approved for connections to databases containing PII, PCI, or other sensitive information. **UPDATE**: This restriction has changed since QuickSight obtained FedRAMP Moderate (Comme
3. All transmission connections must be encrypted.
4. Sharing of dashboards and analysis is only permitted to users within your organization utilizing IAM user credentials with MFA enabled.
5. When authorizing connections from Amazon QuickSight to Amazon RDS DB Instances, you must create a new security group for that DB instance. This security group contains an inbound rule authorizing acce

## Simple Email Service (SES)

**Source:** [AWS Service - AWS SES Service.md](AWS Service - AWS SES Service.md)
**FedRAMP Status:** Not approved / Not reviewed

### Identified Risks

1. Email could fall back to plain text.

## AWS Aurora

**Source:** [AWS Service - Aurora.docx (1).md](AWS Service - Aurora.docx (1).md)
**FedRAMP Status:** FedRAMP Approved East / West, OCISO Approved GovCloud with Conditions

### Identified Risks

1. The risks associated with the use of this service are as followed:
   1. Misconfiguration of Network Isolation

   2. Misconfiguration of Resource-Level Permissions

   3. Unauthorized access of encr

### Use Caveats

1. The use of this service should be performed using IAM Roles and AWS Resource Policies.
2. Existing unencrypted data bases cannot be encrypted. A new encrypted enabled can be created and data can be migrated to the encrypted database.
3. Encryption must be enabled for data in transit and data at rest. Instructions for configure encryption in transit can be found [here](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Aurora.Overv

## AWS Aurora

**Source:** [AWS Service - Aurora.docx.md](AWS Service - Aurora.docx.md)
**FedRAMP Status:** FedRAMP Approved East / West, OCISO Approved GovCloud with Conditions

### Identified Risks

1. The risks associated with the use of this service are as followed:
   1. Misconfiguration of Network Isolation

   2. Misconfiguration of Resource-Level Permissions

   3. Unauthorized access of encr

### Use Caveats

1. The use of this service should be performed using IAM Roles and AWS Resource Policies.
2. Existing unencrypted data bases cannot be encrypted. A new encrypted enabled can be created and data can be migrated to the encrypted database.
3. Encryption must be enabled for data in transit and data at rest. Instructions for configure encryption in transit can be found [here](http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Aurora.Overv

## EC2 Systems Manager (SSM) Parameter Store Parameter Store

**Source:** [AWS Service - EC2 Systems Manager Parameter Store.md](AWS Service - EC2 Systems Manager Parameter Store.md)
**FedRAMP Status:** Not approved / Not reviewed

### Identified Risks

1. The risks associated with the use of this service are as followed:
   1. Misconfigured KMS keys
   2. Lost or missing KMS keys
   3. Misconfigured IAM policies.

### Use Caveats

1. The use of this service should be performed using IAM Roles and AWS Resource Policies.
2. EC2 Systems Manager (SSM) Parameter Store approval **is limited to Secure Strings only with KMS encryption and secure transmission of stored parameters over TLS 1.2.** Storage of parameter values in
3. The use of this service requires the implementation of KMS as [defined](https://docs.google.com/document/d/1QLTi6EaQVE1pGqyq9lGmqCisWY9DiEmYa-w-NXIjZeE/edit) by for use with GSA.
4. The use of the parameter store is limited to only application and system relevant information i.e. passwords, database strings, license codes, API keys, etc. Parameter store cannot be used to store PI

## Lambda

**Source:** [AWS Service - Lambda.md](AWS Service - Lambda.md)
**FedRAMP Status:** FedRAMP Approved East / West

### Identified Risks

1. Permits the invocation of code on behalf of a user or group.

### Use Caveats

1. The use of this service should be performed using IAM Roles and AWS Resource Policies instead of embedding Secret and Secret Access keys within the hosted code.
2. External calls to this service should be performed securely and the code or process that triggers its function should not contain Secret Keys or Secret Access Keys.

## Resource Access Manager

**Source:** [AWS Service - Resource Access Manager.md](AWS Service - Resource Access Manager.md)
**FedRAMP Status:** Not approved / Not reviewed

### Identified Risks

1. Misconfiguration \- Could accidentally expose a resource
2. Shared Resource Control \- Centrally shared resources settings are controlled by a central account and by design a consumer account inherits the setup of that resource. If the settings and permissions

### Use Caveats

1. This service’s sharing capabilities should be limited to AWS Services that have already been previously approved, which include the following as of 1-9-2020:
   1. Amazon Aurora
   2. Amazon EC2

## Secrets Manager

**Source:** [AWS Service - Secrets Manager.md](AWS Service - Secrets Manager.md)
**FedRAMP Status:** Not approved / Not reviewed

### Identified Risks

1. Any leak of administrator level access credentials will compromise access to all sensitive information stored within the AWS Secrets Manager. Such a leak could come from the following issues:
   1. M

### Use Caveats

1. Best practices should enforce that only security keys be stored within the AWS Secrets Manager and not any other confidential information for other services or entities
2. The use of this service should be performed using IAM Roles and AWS Resource Policies.
3. The use of this service requires the implementation of KMS as [defined](https://docs.google.com/document/d/1QLTi6EaQVE1pGqyq9lGmqCisWY9DiEmYa-w-NXIjZeE/edit) by for use with GSA.
4. Use of Third Party API keys is limited to approved application and services as listed on ea.gsa.gov.
5. The use of secrets manager is limited to only application and system relevant information i.e. passwords, database strings, license codes, API keys, etc. Secrets manager cannot be used to store PII, P

## AWS SnowBall Edge

**Source:** [AWS Service - SnowBall Edge.docx.md](AWS Service - SnowBall Edge.docx.md)
**FedRAMP Status:** FedRAMP Approved East / West & GovCloud

### Identified Risks

1. The risks associated with the use of this service are as followed:
   1. Large of amounts of data are stored on a single device; mitigated by AES-256 bit encryption. Keys are not on the device but i

### Use Caveats

1. The use of this service should be performed using IAM Roles and AWS Resource Policies.
2. As with AWS Snowball, Snowball Edge is dependent on the AWS Key Management Service and must be utilized.

## AWS Storage Gateway

**Source:** [AWS Service - Storage Gateway.docx.md](AWS Service - Storage Gateway.docx.md)
**FedRAMP Status:** Not approved / Not reviewed

### Identified Risks

1. The risks associated with the use of this service are as followed:
   1. Misconfiguration of network isolation, resource-level permissions, NFS/iSCI

2. The storage appliance, both physical or virtual, is relatively a “black box”. There is a limited shell to perform basic administrative functions.

### Use Caveats

1. AWS Storage Gateway requires the use of an unvetted appliance that communicates bidirectionally with AWS. This appliance would need to be included in the applicable ATO boundary and subject to securit
2. The use of this service should be performed using IAM Roles and AWS Resource Policies.
3. Data in scope must be encrypted everywhere, at rest, in transit and in S3. Data in transit between hosts and storage gateway should be encrypted using protocols such as SMB V3, FCS 4.1 etc or agents
4. Service is NOT approved for use cases involving pci/pii until service acquires FedRAMP ATO.
5. Service is NOT approved for use cases involving data transfer from GSA on-premise environment.

## XRAY

**Source:** [AWS Service - XRAY.md](AWS Service - XRAY.md)
**FedRAMP Status:** Not approved / Not reviewed

### Identified Risks

1. Misconfiguration \- While data at rest is encrypted by default it could be disabled in error if changing to CMK was performed incorrectly
2. Possible Sensitive Data Exposure \- Debug Data and Traces could expose sensitive data in logs depending on setup.
3. AWS XRAY Can integrate with AWS Services that are currently (11-5-20) not fedramp or GSA Approved

### Use Caveats

1. Ensure Encryption at Rest is enabled either by default or a valid CMK method
2. Ensure granular IAM permissions are in place preventing unauthorized access of viewing application traces and related data.
3. Only use AWS Service integrations that have been approved with XRAY

**Links to additional information:**  
[https://aws.amazon.com/ram/](https://aws.amazon.com/ram/)

[https://docs.aws.amazon

## Cloud9

**Source:** [Cloud9.md](Cloud9.md)
**FedRAMP Status:** Not approved / Not reviewed

### Identified Risks

1. The default setup of Cloud9 exposes the required underlying EC2 instance in a public subnet.
2. The more secure implementation inside of a private subnet disables AWS Temporary Managed Credentials and forces AWS Keys to be hard coded onto the underlying EC2 Server. All AWS Access/Secret Keys sto
3. The “ AWS Managed” underlying EC2 instance that is spun up is questionable. Patches are applied based on start/stop of the instance and timers. Root access is given as well.
4. Trend Micro has demonstrated cloud ide’s are at risk to browser based malware and can scrape input and outputs. [Trend Micro Article](https://www.trendmicro.com/en_us/research/20/c/security-risks-in-o
5. Currently Cloud9 is not in scope of FedRamp or any other compliance families.

### Use Caveats

1. Create the environment in a private subnet with an IAM Account and use the No Ingress style deployment.
2. Treat the instance as if it were not AWS managed.
3. Use AWS PrivateLink/VPC Endpoints to secure traffic
4. Encryption must be set on EBS Drives.
5. MFA needs to be enforced for cloud9 access. Authorization should be limited using IAM policy adopting least privilege principle for users who need access to cloud9. Use centralized enterprise authent

## AWS GuardDuty\*\*

**Source:** [GuardDuty.md](GuardDuty.md)
**FedRAMP Status:** Not approved / Not reviewed

### Identified Risks

1. Low: Subject to Amazon internal staff for developing and maintaining rule sets. New detections are continuously added based on customer feedback and research done by AWS Security and the GuardDuty tea
2. Low: The more advanced behavioral and machine learning detections take **between 7 and 14 days** to set a baseline of behavior in your account. After that time, the anomaly detections flip from a lear
3. Low: Detection responses work best with alerts management through automation. If those skill sets are unavailable then AWS GuardDuty console is the only tool available.
4. Low: Log data is processed in memory and then expunged once processed; findings/alerts are stored for 90 days. FIndings/alert info is not encrypted at rest. For storage longer than 90 days, findi
5. Medium: No visibility into GuardDuty itself. It doesn’t generate logs that we can consume, so until FedRAMP is achieved we’ll not have complete understanding of its operating infrastructure. This is

### Use Caveats

1. The correct IAM identity must have the correct permissions to enable GuardDuty.
2. If storing GuardDuty findings for longer than 90-days, use CloudWatch Events to push findings to an encrypted S3 bucket in your account.

**Links to additional information:**

[GuardDuty Overview:](

## AWS Amazon Managed Streaming for Apache Kafka (Amazon MSK)

**Source:** [ISE AWS Amazon Managed Streaming for Apache Kafka (Amazon MSK).md](ISE AWS Amazon Managed Streaming for Apache Kafka (Amazon MSK).md)
**FedRAMP Status:** Not approved / Not reviewed

### Identified Risks

1. Service enablement will allow a more robust queuing option for ingesting data into the ELP without data loss experienced with using AWS Kinesis. There are no known risks to using the service.
2. Users can enable data in transit to be either hybrid tls and plaintext or plaintext only.

### Use Caveats

1. Encryption in transit. Only the default settings, “Only allow TLS encrypted data” can be used. The options to allow plaintext are not to be used.

**Links to additional information:**  
Provide lin

## AWS Bedrock

**Source:** [ISE AWS Bedrock.md](ISE AWS Bedrock.md)
**FedRAMP Status:** FedRAMP Approved

### Use Caveats

1. **Complete safety board [review](https://feedback.gsa.gov/jfe/form/SV_5tgn61GaufYZOlg).**
2. \*\*Complete the [AI Security Review Checklist](https://docs.google.com/spreadsheets/d/1cekVRPvWjGEIW1IXISkdy01muwE5KskkECTn0BaPKw8/edit?usp=drive_link) and submit to [Seceng@gsa.gov](mailto:Seceng@gsa.
3. **VPC Configuration:**
   - Implement a **VPC** with **public and private subnets**.
   - Use a **NAT Gateway** to restrict and control internet access to Amazon Bedrock resources.
4. **Third-Party Integrations:**
   - Ensure all third-party integrations (e.g., vector stores or plugins) are **approved** for use in GSA environments.
5. **Container Security:**
   - Enable **inter-container traffic encryption** to secure communications between containers, if applicable.
6. **Endpoint Security:**
   - Ensure all endpoints are enabled with **HTTPS** to protect data in transit when invoking models or accessing Bedrock APIs.
7. **Encryption at Rest:**
   - Ensure all **data and model artifacts** at rest are encrypted using **AWS KMS** (Key Management Service) with Customer Managed Keys (CMKs) where required.

---

## AWS Elastic Container Registry

**Source:** [ISE AWS ECR Review .md](ISE AWS ECR Review .md)
**FedRAMP Status:** Not approved / Not reviewed

### Identified Risks

1. While ECR can provide granular control over who can access or pull from it, an authorized user could still inadvertently or maliciously upload a malicious image.
2. Without proper lifecycle policy, image sprawl could become an issue with both risk and cost.

### Use Caveats

1. Twistlock must be integrated for image vulnerability identification and security visibility per [GSA’s policy](https://docs.google.com/document/d/1zXpKoMd8qJx3ALULNRgnJL3GwLojAiqCXW8LxRbU5ZA/edit).
2. Ensure to use least privilege IAM policy per your organizations needs.

**Links to additional information:**  
[ECR Frequently Asked Questions](https://aws.amazon.com/ecr/faqs/)  
[Service Overview

## AWS Elastic Container Service (ECS)\*\*

**Source:** [ISE AWS ECS and Fargate Service Review.md](ISE AWS ECS and Fargate Service Review.md)
**FedRAMP Status:** Approve East/West/GovCloud

### Identified Risks

1. If you do not use a load balancer, a security group is created to allow all public traffic to your service ONLY on the container port specified. If you use an Application Load Balancer, two security g
2. Fargate does not support root volume encryption. (It's on the roadmap to implement).
3. The default deployment wizard does not encrypt the EBS volumes for ECS clusters.
4. Encryption at rest must be configured either using the ALB or container itself.

### Use Caveats

1. All ECS implementations must have TwistLock integrated as per [GSA’s policy](https://docs.google.com/document/d/1zXpKoMd8qJx3ALULNRgnJL3GwLojAiqCXW8LxRbU5ZA/edit).
2. If using the EC2 cluster option, ensure to encrypt the EBS root and data volumes.
3. If using EFS, ensure the security groups are configured to only allow access to the specific EC2 hosts.
4. Ensure security groups are configured to allow least privilege access.
5. If using ECR, ensure the S3 bucket is encrypted

**Links to additional information:**  
About Document: [https://aws.amazon.com/ecs/faqs/](https://aws.amazon.com/ecs/faqs/)  
User Guide: [https://do

## AWS Elastic Container Service for Kubernetes (EKS)

**Source:** [ISE AWS EKS.md](ISE AWS EKS.md)
**FedRAMP Status:** Approved in AWS East/West, under JAB review in GovCloud (as of 2020/12/01)Not approved / Not reviewed

### Identified Risks

1. The base AMI from AWS that is EKS ready does not have encrypted EBS volumes.
2. The customer has no visibility into the Master node hosted on the AWS control plane.

### Use Caveats

1. All worker nodes must use EBS encrypted volumes.
2. All worker nodes must have TwistLock integrated as per [GSA’s policy](https://docs.google.com/document/d/1zXpKoMd8qJx3ALULNRgnJL3GwLojAiqCXW8LxRbU5ZA/edit).
3. EKS is restricted to use with just Docker.

**Links to additional information:**  
[Amazon Elastic Container Service for Kubernetes](https://aws.amazon.com/eks/)  
[FAQ](https://aws.amazon.com/eks/f

## AWS Elastic File System (EFS)

**Source:** [ISE AWS Elastic File Service (EFS) v2.md](ISE AWS Elastic File Service (EFS) v2.md)
**FedRAMP Status:** Approved

### Identified Risks

1. EFS is billed by usage so its recommend to monitor and control storage use as to best manage cost. Unmonitored or mis-deployed applications could unnecessarily drive up cost.

### Use Caveats

1. Encryption for both in transit and at rest must be enabled.
2. Cannot use with Windows EC2 currently.
3. Ensure Security Groups are configured so only authorized hosts can mount to EFS.

**Links to additional information:**  
Product Overview:  
[https://aws.amazon.com/efs/](https://aws.amazon.com/efs

## AWS Firewall Manager

**Source:** [ISE AWS Firewall Manager.md](ISE AWS Firewall Manager.md)
**FedRAMP Status:** FedRAMP Approved East / West

### Identified Risks

1. Improper configuration can impact availability of service or unauthorized wider access on multiple application across multiple accounts. Firewall Administrator account must be assigned carefully based
2. Third party rules are considered proprietary and ​there are no mechanisms to review before automated deploys. Automated updates of third party rules could have operational impact on applications.
3. Third Party rules from marketplace are deployed in group and cannot be viewed or modified separately. Third party rules are not editable, however entire rule group can be enable or disabled as well a

### Use Caveats

1. AWS Firewall Manager needs aws organization and assigned Firewall administrator account. Any member account or master account from aws organization can be assigned as Firewall administrator account. F
2. The use of 3rd party AWS Managed Rules must be identified in the SSP as third party rules. Third party rules are considered proprietary and ​there are no mechanisms to review it. Also no mechanisms t

## AWS Kinesis Data FireHose

**Source:** [ISE AWS Kinesis Data FireHose Review.md](ISE AWS Kinesis Data FireHose Review.md)
**FedRAMP Status:** [Authorized](https://aws.amazon.com/compliance/services-in-scope/FedRAMP/)

### Identified Risks

1. Records are not encrypted in transit or rest by default.

### Use Caveats

1. Encryption in transit of the records must be [configured](https://docs.aws.amazon.com/streams/latest/dev/what-is-sse.html).
2. Records must be encrypted while at rest.
3. Least privileged IAM policies need to be enforced.
4. Cannot use use AWS IOT

## AWS SageMaker

**Source:** [ISE AWS SageMaker.md](ISE AWS SageMaker.md)
**FedRAMP Status:** FedRAMP Approved

### Identified Risks

1. Notebook Instance Security: By default, notebook instances are internet-enabled. A malicious user or code could access unauthorized data. Direct internet access can be disabled but SageMaker will not
2. SageMaker runs training jobs in an Amazon Virtual Private Cloud. However, training containers access AWS resources over the internet. This can be remedied by implementing a Private VPC and an Elastic

### Use Caveats

1. For use in GSA, please [implement](https://docs.aws.amazon.com/sagemaker/latest/dg/train-vpc.html) the [VPC with public and Private Subnets](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_
2. Ensure that all third party integrations are approved for use in GSA.
3. Ensure inter-container traffic encryption is enabled for containers.
4. Ensure all endpoints are enabled with HTTPS.
5. Ensure all data and models at rest are encrypted with KMS.

**Links to additional information:**  
FAQ: https://aws.amazon.com/fargate/faqs/  
Developer Guide: https://docs.aws.amazon.com/sagemaker

## AWS Certificate Manager (ACM)

**Source:** [ISE AWS Service Review - AWS Certificate Manager.md](ISE AWS Service Review - AWS Certificate Manager.md)
**FedRAMP Status:** Not reviewed/ Under Review

### Identified Risks

1. AWS stores private key in encrypted format using AWS managed KMS keys. We would be relying on the AWS processes to make sure AWS managed KMS keys are secured and not improperly used.
2. Revoking a certificate is not instantaneous. A CRL is typically updated approximately 30 minutes after a certificate is revoked.
3. ACM uses DNS and email based methods for domain name validation to issue certificates. Poorly maintained whois email records might send authorization requests to unauthorized email addresses.

### Use Caveats

1. Usage of the certificates must be consistent with the [GSA SSL / TLS Procedural Guide](https://insite.gsa.gov/portal/getMediaData?mediaId=536145)
2. End user is in charge of safely maintaining and rotating private keys for imported certificates.
3. DNS based domain name validation is preferred and recommended to be used.

**Links to additional information:**

ACM User Guide :  
https://docs.aws.amazon.com/acm/latest/userguide/acm-overview.htm

## Transfer Family

**Source:** [Transfer Family.md](Transfer Family.md)
**FedRAMP Status:** Not approved / Not reviewed

### Identified Risks

1. The Standard FTP Protocol is insecure and does not provide encryption.
2. Several Cipher Suites are available and could weaken security posture if used too excessively.
3. SFTP can be used without an Identity Provider/MFA Solution.
4. IAM Permission Misconfiguration can allow access to more data than necessary.
5. S3 and EFS Misconfiguration could expose data if not configured properly.
6. Malicious Files could be transmitted over these services.

### Use Caveats

1. The standard FTP protocol is not permitted to be enabled or used. This is a HARD requirement.
2. FIPS Mode is required to be enabled.
3. Use of the SFTP Protocol must be implemented in conjunction with a GSA Approved Identity Provider and MFA.
4. Key based authentication must be implemented for programmatic or automated file transfers.
5. IAM Permissions must be implemented with least privilege to stored files and folders. Use multiple IAM roles or scope down permissions.
6. S3 and EFS are required to have encryption at rest enabled. S3 Bucket policies should not allow public access.
7. Coordinate with your system's ISSM on malicious file scanning requirements.
