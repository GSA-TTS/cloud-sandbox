# AWS Approved Service Conditions

Generated from in-house AWS markdown review files on 2026-04-14.

For each approved service, the linked source markdown contains the authoritative use caveats, configuration requirements, protocols, and settings.

## API Gateway

- In-house FedRAMP status: `FedRAMP Approved East / West Only`
- Source conditions doc: [API Gateway.md](API%20Gateway.md)
- Approval rationale snapshot: Available per in-house source (FedRAMP Approved East / West Only). Conditions/caveats are documented in the linked service markdown.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## Import_Export

- In-house FedRAMP status: `AWS Import/Export \- FedRAMP Approved East / West & GovCloud`
- Source conditions doc: [AWS Import_Export.md](AWS%20Import_Export.md)
- Approval rationale snapshot: GSA CISO has conditionally approved the use of AWS Import/Export for GSA hosted systems leveraging the FedRAMP approved AWS East/West US Public Cloud (IaaS) or AWS Government Community Cloud (IaaS) environments.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## QuickSight

- In-house FedRAMP status: `FedRAMP Approved Commercial East/West (Moderate) and GovCloud (High)`
- Source conditions doc: [AWS QuickSight.md](AWS%20QuickSight.md)
- Approval rationale snapshot: ISE recommends approval of this service; limiting approval to Direct SQL Query (which does not store data in QuickSight); SPICE usage (which stores data in QuickSight) is prohibited.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## Aurora (1)

- In-house FedRAMP status: `FedRAMP Approved East / West, OCISO Approved GovCloud with Conditions`
- Source conditions doc: [AWS Service - Aurora.docx (1).md](<AWS%20Service%20-%20Aurora.docx%20(1).md>)
- Approval rationale snapshot: ISE recommends the approval of this service by the OCISO when enabled with encryption at rest and in transit (see caveats).
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## Aurora

- In-house FedRAMP status: `FedRAMP Approved East / West, OCISO Approved GovCloud with Conditions`
- Source conditions doc: [AWS Service - Aurora.docx.md](AWS%20Service%20-%20Aurora.docx.md)
- Approval rationale snapshot: ISE recommends the approval of this service by the OCISO when enabled with encryption at rest and in transit (see caveats).
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## Lambda

- In-house FedRAMP status: `FedRAMP Approved East / West`
- Source conditions doc: [AWS Service - Lambda.md](AWS%20Service%20-%20Lambda.md)
- Approval rationale snapshot: Available per in-house source (FedRAMP Approved East / West). Conditions/caveats are documented in the linked service markdown.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## SnowBall Edge

- In-house FedRAMP status: `FedRAMP Approved East / West & GovCloud`
- Source conditions doc: [AWS Service - SnowBall Edge.docx.md](AWS%20Service%20-%20SnowBall%20Edge.docx.md)
- Approval rationale snapshot: ISE recommends the approval of this service by the OCISO.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## ElastiCache

- In-house FedRAMP status: `AWS ElastiCache \- FedRAMP Approved East / West and GovCloud`
- Source conditions doc: [ElastiCache.md](ElastiCache.md)
- Approval rationale snapshot: Available per in-house source (AWS ElastiCache \- FedRAMP Approved East / West and GovCloud). Conditions/caveats are documented in the linked service markdown.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## Glacier

- In-house FedRAMP status: `Glacier \- FedRAMP East / West and GovCloud Approved`
- Source conditions doc: [Glacier.md](Glacier.md)
- Approval rationale snapshot: Available per in-house source (Glacier \- FedRAMP East / West and GovCloud Approved). Conditions/caveats are documented in the linked service markdown.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## Bedrock

- In-house FedRAMP status: `FedRAMP Approved`
- Source conditions doc: [ISE AWS Bedrock.md](ISE%20AWS%20Bedrock.md)
- Approval rationale snapshot: ISE recommends approval of this service provided adherence to the use caveats defined below.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## ECS and Fargate Service Review

- In-house FedRAMP status: `Approve East/West/GovCloud`
- Source conditions doc: [ISE AWS ECS and Fargate Service Review.md](ISE%20AWS%20ECS%20and%20Fargate%20Service%20Review.md)
- Approval rationale snapshot: ISE recommends approval of this service provided adherence to the use caveats defined below.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## Elastic File Service (EFS)

- In-house FedRAMP status: `Approved`
- Source conditions doc: [ISE AWS Elastic File Service (EFS) v2.md](<ISE%20AWS%20Elastic%20File%20Service%20(EFS)%20v2.md>)
- Approval rationale snapshot: ISE recommends approval of this service provided adherence to the use caveats defined below.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## Firewall Manager

- In-house FedRAMP status: `FedRAMP Approved East / West`
- Source conditions doc: [ISE AWS Firewall Manager.md](ISE%20AWS%20Firewall%20Manager.md)
- Approval rationale snapshot: ISE recommends approval of this service provided adherence to the use caveats defined below.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## Kinesis Data FireHose Review

- In-house FedRAMP status: `[Authorized](https://aws.amazon.com/compliance/services-in-scope/FedRAMP/)`
- Source conditions doc: [ISE AWS Kinesis Data FireHose Review.md](ISE%20AWS%20Kinesis%20Data%20FireHose%20Review.md)
- Approval rationale snapshot: ISE recommends approval of this service provided adherence to the use caveats defined below.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## SageMaker

- In-house FedRAMP status: `FedRAMP Approved`
- Source conditions doc: [ISE AWS SageMaker.md](ISE%20AWS%20SageMaker.md)
- Approval rationale snapshot: ISE recommends approval of this service provided adherence to the use caveats defined below.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## SSM Incident Manager

- In-house FedRAMP status: `approved`
- Source conditions doc: [ISE AWS Service SSM Incident Manager.md](ISE%20AWS%20Service%20SSM%20Incident%20Manager.md)
- Approval rationale snapshot: Available per in-house source (approved). Conditions/caveats are documented in the linked service markdown.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## KMS

- In-house FedRAMP status: `Key Management System (KMS) \- FedRAMP Approved East / West and GovCloud`
- Source conditions doc: [KMS.md](KMS.md)
- Approval rationale snapshot: Available per in-house source (Key Management System (KMS) \- FedRAMP Approved East / West and GovCloud). Conditions/caveats are documented in the linked service markdown.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.

## RDS

- In-house FedRAMP status: `The GSA CISO has conditionally approved the use of AWS RDS for GSA hosted systems leveraging the FedRAMP approved AWS East/West US Public Cloud (IaaS) or AWS Government Community Cloud (IaaS) environments.`
- Source conditions doc: [RDS.md](RDS.md)
- Approval rationale snapshot: GSA CISO has conditionally approved the use of AWS RDS for GSA hosted systems leveraging the FedRAMP approved AWS East/West US Public Cloud (IaaS) or AWS Government Community Cloud (IaaS) environments.
- Required baseline configuration/protocols/settings:
  - Encryption in transit and at rest where supported/required.
  - Least-privilege IAM policies; deny-by-default for sensitive actions.
  - Required sandbox tags: `Project`, `Owner`, `TTLExpiry`, `CostCenter`, `Cloud`, `Environment`.
  - Public exposure restricted unless explicitly approved with compensating controls.
