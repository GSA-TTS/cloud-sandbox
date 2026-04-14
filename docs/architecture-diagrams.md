# TTS Cloud Sandbox — Architecture Diagrams (SSP)

All diagrams required by the Supplementary Service Broker (SSB) System Security Plan,
following FedRAMP SSP template sections 9–10 and the C4 model. Diagrams are cross-referenced
to SSP sections and NIST SP 800-53 Rev 5 control families where applicable.

| Diagram                                                                    | SSP Section    | Controls           |
| -------------------------------------------------------------------------- | -------------- | ------------------ |
| [1. System Context](#1-system-context-diagram-c4-l1)                       | 9.2, 9.5       | SA-9, SC-7         |
| [2. Authorization Boundary](#2-authorization-boundary-diagram)             | 9.2, 9.5       | SC-7, CA-3         |
| [3. Network Architecture](#3-network-architecture-diagram--ssp-figure-9-1) | 9.5 Fig 9-1    | SC-7, SC-8, SC-22  |
| [4. Container Architecture](#4-container-diagram-c4-l2)                    | 9.2, 10        | CM-7, CM-8         |
| [5. CSB Component Architecture](#5-csb-component-diagram-c4-l3)            | 9.2, 10        | CM-7, SA-4, SC-2   |
| [6. Deployment Architecture](#6-deployment-diagram-c4-deployment)          | 10, 10.9       | CM-8, SA-9         |
| [7. Data Flow](#7-data-flow-diagram--ssp-figure-10-1)                      | 10.4 Fig 10-1  | SC-8, AU-2, AC-3   |
| [8. Authentication Flow](#8-authentication-flow--ssp-section-94)           | 9.4            | IA-2, AC-17        |
| [9. TTL Lifecycle](#9-ttl-sandbox-lifecycle-sequence)                      | custom         | CP-10, CM-8        |
| [10. CI/CD Pipeline](#10-cicd-pipeline--ssp-sections-1073--1079)           | 10.7.3, 10.7.9 | CM-3, SA-10, SA-11 |
| [11. RBAC & Access Control](#11-rbac--access-control)                      | 9.4, 10        | AC-2, AC-3, AC-6   |
| [12. Logging & Monitoring Data Flow](#12-logging--monitoring-data-flow)    | 10.8.10        | AU-2, AU-12, SI-4  |

---

## 1. System Context Diagram (C4 L1)

> **SSP Reference:** Section 9.2 General System Description, Section 9.5 Network Architecture  
> **Controls:** SA-9 (External Information System Services), SC-7 (Boundary Protection)

The TTS Cloud Sandbox SSB manages the full lifecycle of multi-cloud sandbox service instances
on behalf of GSA TTS engineers. It inherits FedRAMP Moderate P-ATO controls from cloud.gov
(FR1920000001) and brokers to three external CSPs.

```mermaid
C4Context
    title System Context — TTS Cloud Sandbox Multi-Cloud SSB

    Person(ttsEng, "TTS Engineer", "GSA SpaceDeveloper with CF role in gsa-tts-iae-lava-beds/dev. Provisions and manages sandbox cloud resources via cf CLI.")
    Person(ttsOps, "TTS TechOps / Ops Admin", "GSA CF org admin. Manages broker registration, service catalog approvals, and quota governance.")
    Person(auditor, "ISSO / Security Auditor", "Reviews OSCAL compliance documents, Prowler findings, and CF audit logs.")

    System_Boundary(ssb, "TTS Cloud Sandbox SSB (Authorization Boundary)") {
        System(csb, "Cloud Service Broker Platform", "3 × CSB v2.6.10 CF apps (csb-aws, csb-gcp, csb-azure) + csb-sql MySQL backing DB. Implements OSBAPI. Brokers sandbox-tier cloud resources via OpenTofu brokerpaks. Deployed on cloud.gov org: gsa-tts-iae-lava-beds, space: dev.")
    }

    System_Ext(cloudgov, "cloud.gov (FedRAMP P-ATO FR1920000001)", "GSA TTS PaaS — Cloud Foundry. Provides container hosting, network boundary, UAA/SecureAuth authentication, CF RBAC, Loggregator, RDS-backed database services. All PE/CP/MA controls fully inherited.")
    System_Ext(secureauth, "GSA SecureAuth", "GSA enterprise IdP (sAML 2.0). Provides ENT Domain ID + MFA (email/phone/TOTP) + password authentication for all CF CLI access and cloud.gov dashboard access.")
    System_Ext(aws, "AWS (us-east-1 / us-gov-west-1)", "External CSP — S3, RDS PostgreSQL/MySQL, ElastiCache Redis, SQS. Resources provisioned in VPC vpc-61e8f005 with private subnets.")
    System_Ext(gcp, "GCP (Sandbox Project)", "External CSP — Cloud SQL, GCS, Pub/Sub, Memorystore Redis, BigQuery. Pending deployment.")
    System_Ext(azure, "Azure (Sandbox Resource Group)", "External CSP — PostgreSQL Flexible Server, SQL, Cache for Redis, Storage Account, Event Hubs. Pending deployment.")
    System_Ext(github, "GitHub.com (GSA-TTS/cloud-sandbox)", "Source control, CI/CD (GitHub Actions), Dependabot vulnerability scanning. Branch-based PR workflow with required reviews.")
    System_Ext(prowler, "Prowler v3.x", "Multi-cloud security assessment. Runs CIS Benchmark + FedRAMP Moderate checks against all three CSP accounts. Outputs feed OSCAL assessment-results and POA&M.")

    Rel(ttsEng, csb, "Provisions / deprovisions sandbox services", "cf CLI / OSBAPI HTTPS")
    Rel(ttsOps, csb, "Registers brokers, manages catalog, sets quotas", "cf CLI + CF Admin API")
    Rel(auditor, prowler, "Reviews scan findings, manages POA&M", "GitHub / OSCAL docs")

    Rel(csb, cloudgov, "Hosted on; inherits FedRAMP controls", "Cloud Foundry runtime")
    Rel(cloudgov, secureauth, "Delegates user authentication", "SAML 2.0")
    Rel(ttsEng, secureauth, "Authenticates with ENT ID + MFA", "SAML / browser redirect")

    Rel(csb, aws, "Provisions sandbox resources via OpenTofu", "AWS SDK / HTTPS TLS 1.2+")
    Rel(csb, gcp, "Provisions sandbox resources via OpenTofu [planned]", "GCP SDK / HTTPS")
    Rel(csb, azure, "Provisions sandbox resources via OpenTofu [planned]", "Azure SDK / HTTPS")

    Rel(prowler, aws, "Reads resource configs, evaluates compliance", "AWS API read-only")
    Rel(prowler, gcp, "Reads resource configs [planned]", "GCP API read-only")
    Rel(prowler, azure, "Reads resource configs [planned]", "Azure API read-only")

    Rel(github, csb, "Deploys updated broker apps", "GitHub Actions → cf push")
    Rel(ttsEng, github, "Commits code, reviews PRs, triggers CI/CD", "git / HTTPS")
```

---

## 2. Authorization Boundary Diagram

> **SSP Reference:** Section 9.2 Information System Components and Boundaries  
> **Controls:** SC-7 (Boundary Protection), CA-3 (System Interconnections), CA-9 (Internal Connections)

```mermaid
flowchart TB
    subgraph BOUNDARY["🔐  TTS CLOUD SANDBOX SSB — AUTHORIZATION BOUNDARY"]
        direction TB
        subgraph CG["cloud.gov FedRAMP P-ATO FR1920000001 (Inherited)"]
            direction LR
            subgraph SPACE["CF Org: gsa-tts-iae-lava-beds / Space: dev"]
                CSB_AWS["csb-aws\n(CF App, 1G)"]
                CSB_GCP["csb-gcp\n(CF App, planned)"]
                CSB_AZR["csb-azure\n(CF App, planned)"]
                CSBSQL[("csb-sql\nMySQL\naws-rds micro-mysql")]
            end
            UAA["CF UAA\n(OAuth2 / SAML SP)"]
            ROUTER["CF GoRouter\n(TLS termination)"]
            LOGG["Loggregator\nlogs.fr.cloud.gov"]
            DIAG["Diego\n(Container Scheduler)"]
        end
    end

    subgraph EXTERNAL["EXTERNAL — OUTSIDE AUTHORIZATION BOUNDARY"]
        direction LR
        subgraph GSANET["GSA Network"]
            SA["GSA SecureAuth\n(ENT ID + MFA)"]
            DEV["TTS Engineer\n(CF CLI / Browser)"]
        end
        subgraph CSPS["Cloud Service Provider Backends"]
            subgraph AWSB["AWS (CSB-managed)"]
                AWS_VPC["VPC vpc-61e8f005\nPrivate Subnets"]
                RDS["RDS PostgreSQL/MySQL"]
                REDIS["ElastiCache Redis"]
                S3["S3 Buckets"]
                SQS["SQS Queues"]
            end
            subgraph GCPB["GCP (planned)"]
                CLOUDSQL["Cloud SQL"]
                GCS["Cloud Storage"]
                PUBSUB["Pub/Sub"]
                GREDIS["Memorystore"]
            end
            subgraph AZRB["Azure (planned)"]
                AZPG["PostgreSQL Flex"]
                AZSQL["Azure SQL"]
                AZREDIS["Azure Cache Redis"]
                AZSTORE["Storage Account"]
            end
        end
        GH["GitHub.com\n(CI/CD)"]
        PROWLER["Prowler\n(Security Scanner)"]
    end

    DEV -- "HTTPS / cf CLI SSO\n(TLS 1.2+)" --> ROUTER
    ROUTER -- "OAuth2 + JWT" --> UAA
    UAA -- "SAML 2.0" --> SA
    ROUTER --> CSB_AWS
    ROUTER --> CSB_GCP
    ROUTER --> CSB_AZR
    CSB_AWS -- "MySQL 3306\n(private CF network)" --> CSBSQL
    CSB_GCP -- "MySQL 3306" --> CSBSQL
    CSB_AZR -- "MySQL 3306" --> CSBSQL
    CSB_AWS -- "stdout" --> LOGG
    CSB_AWS -- "AWS SDK HTTPS" --> AWSB
    CSB_GCP -- "GCP SDK HTTPS" --> GCPB
    CSB_AZR -- "Azure SDK HTTPS" --> AZRB
    GH -- "cf push (GitHub Actions)" --> ROUTER
    PROWLER -- "AWS API (read)" --> AWSB
    PROWLER -- "GCP API (read)" --> GCPB
    PROWLER -- "Azure API (read)" --> AZRB

    style BOUNDARY fill:#e8f4fd,stroke:#1a6fa3,stroke-width:3px
    style CG fill:#dff0d8,stroke:#3c763d,stroke-width:2px
    style SPACE fill:#f0f8ff,stroke:#337ab7,stroke-width:1px,stroke-dasharray:4
    style EXTERNAL fill:#fdf5e6,stroke:#8a6d3b,stroke-width:2px,stroke-dasharray:6
    style AWSB fill:#fff3cd,stroke:#ff9900
    style GCPB fill:#d9edf7,stroke:#4285f4
    style AZRB fill:#f2dede,stroke:#0089d6
```

---

## 3. Network Architecture Diagram — SSP Figure 9-1

> **SSP Reference:** Section 9.5 Network Architecture (Figure 9-1)  
> **Controls:** SC-7 (Boundary Protection), SC-8 (Transmission Confidentiality), SC-22 (DNS Architecture)

```mermaid
flowchart LR
    subgraph INTERNET["Public Internet"]
        CLI["CF CLI / Browser\n(TTS Engineer)"]
        GH_CI["GitHub Actions\n(CI/CD runner)"]
    end

    subgraph GSA_NET["GSA Network / VPN"]
        SA2["GSA SecureAuth\nlogin.fr.cloud.gov → secureauth.gsa.gov\nSAML 2.0 + MFA"]
    end

    subgraph CLOUD_GOV["cloud.gov — AWS GovCloud us-gov-west-1 (FedRAMP P-ATO)"]
        ALB["AWS ALB\n(cloud.gov-managed)\nPublic TLS Termination"]
        subgraph CF_ROUTING["CF Routing Layer"]
            GORTR["GoRouter\n(HTTP/HTTPS)\nTLS 1.2+ between routers and cells"]
        end
        subgraph CF_AUTH["CF Auth Layer"]
            UAA2["UAA OAuth2 Server\napi.fr.cloud.gov/uaa\nIssues JWT tokens"]
            PASSCODE["login.fr.cloud.gov/passcode\nSSO Passcode endpoint"]
        end
        subgraph CF_CELLS["Diego Cell — Garden Containers"]
            direction TB
            APP_AWS["csb-aws Container\n0.0.0.0:8080\n1G RAM, binary buildpack"]
            APP_GCP["csb-gcp Container\n[planned]"]
            APP_AZR["csb-azure Container\n[planned]"]
        end
        subgraph CF_SVCS["Cloud Foundry Managed Services (Internal)"]
            MYSQL[("csb-sql\naws-rds micro-mysql\nus-gov-west-1 RDS\nPort 3306 (private)")]
            LOGG2["Loggregator\n(STDOUT/STDERR aggregation)\nlogs.fr.cloud.gov"]
        end
    end

    subgraph AWS_BACKEND["AWS Backend — us-east-1 (CSB-managed boundary)"]
        subgraph VPC["VPC: vpc-61e8f005"]
            subgraph PRIV_SUBNET["Private Subnets (no IGW route)"]
                RDS2["RDS PostgreSQL/MySQL\nPort 5432 / 3306"]
                ELASTI["ElastiCache Redis\nPort 6379\nTLS + at-rest encryption"]
            end
            subgraph PUBLIC_EP["AWS Public Endpoints (private ACL enforced)"]
                S3_EP["S3 Service Endpoint\nHTTPS only\nPrivate ACL + SSE-S3"]
                SQS_EP["SQS Service Endpoint\nHTTPS only"]
            end
            SG["Security Groups:\nAllow inbound from CF cell egress CIDRs only"]
        end
        AWSAPI["AWS Control Plane API\nec2, rds, elasticache,\ns3, sqs — HTTPS 443"]
    end

    subgraph GCP_BACKEND["GCP Backend — Sandbox Project (planned)"]
        GCPAPI["GCP Control Plane API\nHTTPS 443"]
        CLOUDSQL2["Cloud SQL PostgreSQL\nPrivate IP (no public endpoint)"]
        GCS2["Cloud Storage\nHTTPS, uniform ACL"]
    end

    subgraph AZR_BACKEND["Azure Backend — Sandbox Resource Group (planned)"]
        AZAPI["Azure Resource Manager API\nHTTPS 443"]
        AZPG2["PostgreSQL Flexible Server\nPrivate Access (VNet integration)"]
        AZREDIS2["Azure Cache for Redis\nTLS only, non-SSL port disabled"]
    end

    CLI -- "HTTPS 443 (TLS 1.2+)" --> ALB
    GH_CI -- "HTTPS 443 (TLS 1.2+)" --> ALB
    ALB -- "HTTPS internal" --> GORTR
    GORTR -- "TLS container-to-container" --> APP_AWS
    GORTR -- "TLS container-to-container" --> APP_GCP
    GORTR -- "TLS container-to-container" --> APP_AZR
    CLI -- "SAML redirect" --> SA2
    SA2 -- "SAML assertion" --> UAA2
    UAA2 --> PASSCODE
    APP_AWS -- "TCP 3306 (CF internal overlay)" --> MYSQL
    APP_GCP -- "TCP 3306 (CF internal overlay)" --> MYSQL
    APP_AZR -- "TCP 3306 (CF internal overlay)" --> MYSQL
    APP_AWS -- "stdout" --> LOGG2
    APP_AWS -- "AWS SDK HTTPS 443" --> AWSAPI
    AWSAPI --> VPC
    APP_GCP -- "GCP SDK HTTPS 443" --> GCPAPI
    GCPAPI --> CLOUDSQL2
    GCPAPI --> GCS2
    APP_AZR -- "Azure SDK HTTPS 443" --> AZAPI
    AZAPI --> AZPG2
    AZAPI --> AZREDIS2
```

---

## 4. Container Diagram (C4 L2)

> **SSP Reference:** Section 9.2 System Assets, Section 10 System Environment  
> **Controls:** CM-7 (Least Functionality), CM-8 (Component Inventory)

```mermaid
C4Container
    title Container Diagram — TTS Cloud Sandbox SSB Authorization Boundary

    Person(eng, "TTS Engineer", "GSA SpaceDeveloper. Uses cf CLI to provision sandbox resources.")
    Person(ops, "TTS TechOps Admin", "CF Org Admin. Manages brokers and service catalog.")

    System_Ext(secureauth, "GSA SecureAuth", "GSA enterprise IdP. SAML 2.0 + ENT Domain ID + MFA.")
    System_Ext(awsCSP, "AWS (us-east-1)", "External CSP. Hosts sandbox S3, RDS, ElastiCache, SQS instances.")
    System_Ext(gcpCSP, "GCP (Sandbox Project)", "External CSP [planned]. Hosts sandbox Cloud SQL, GCS, Pub/Sub, Memorystore.")
    System_Ext(azrCSP, "Azure (Sandbox RG)", "External CSP [planned]. Hosts sandbox PostgreSQL, SQL, Redis, Storage, Event Hubs.")
    System_Ext(github, "GitHub.com", "Source control and CI/CD. GitHub Actions deploys updated broker apps.")

    Container_Boundary(cg, "cloud.gov — CF Org: gsa-tts-iae-lava-beds / Space: dev") {

        Container(csbAWS, "csb-aws", "Go binary + AWS brokerpak (.brokerpak)", "Cloud Service Broker for AWS. Exposes OSBAPI v2 endpoint authenticated via HTTP Basic Auth. Loaded with csb-brokerpak-aws providing sandbox-8h plans for S3, RDS, ElastiCache, SQS. Registers as space-scoped CF service broker 'csb-aws-sandbox'. Running at csb-aws-*.app.cloud.gov.")

        Container(csbGCP, "csb-gcp [planned]", "Go binary + GCP brokerpak (.brokerpak)", "Cloud Service Broker for GCP. Provides sandbox-8h plans for Cloud SQL, GCS, Pub/Sub, Memorystore Redis, BigQuery. Registers as 'csb-gcp-sandbox'.")

        Container(csbAZR, "csb-azure [planned]", "Go binary + Azure brokerpak (.brokerpak)", "Cloud Service Broker for Azure. Provides sandbox-8h plans for PostgreSQL Flex, SQL, Redis, Storage Account, Event Hubs. Registers as 'csb-azure-sandbox'.")

        ContainerDb(csbSQL, "csb-sql", "MySQL (aws-rds micro-mysql)", "Shared backing database for all three broker instances. Stores OpenTofu state per service instance, binding credentials, provision parameters. Encrypted at rest. Accessible on CF internal overlay network only.")

        Container(cfRouter, "CF GoRouter", "Cloud Foundry GoRouter (cloud.gov-managed)", "Terminates public TLS, routes HTTPS traffic to CSB app containers. Enforces HTTPS-only (redirects HTTP). Manages TLS certificates via Let's Encrypt (cloud.gov-managed).")

        Container(uaa, "CF UAA", "OAuth2 / SAML SP (cloud.gov-managed)", "Issues JWT access tokens after SAML exchange with GSA SecureAuth. Tokens are used by cf CLI for all CF API calls. Manages org/space/role assignments.")

        Container(logg, "Loggregator / logs.fr.cloud.gov", "ELK + Firehose (cloud.gov-managed)", "Aggregates STDOUT/STDERR from all CF app containers. Provides searchable audit log at logs.fr.cloud.gov. Retains logs per cloud.gov P-ATO retention policy.")

        Container(cfAPI, "CF API (CAPI)", "Cloud Controller REST API (cloud.gov-managed)", "Manages CF resource lifecycle: orgs, spaces, apps, service instances, service brokers. All SpaceDeveloper actions (cf create-service, cf bind-service) are recorded here. Enforces CF RBAC.")
    }

    Rel(eng, cfRouter, "HTTPS requests: cf marketplace, cf create-service", "HTTPS TLS 1.2+")
    Rel(ops, cfAPI, "Registers brokers, manages quotas, assigns roles", "CF Admin API HTTPS")
    Rel(eng, uaa, "Authenticates via SSO passcode exchange", "OAuth2 PKCE + SAML redirect")
    Rel(uaa, secureauth, "Delegates to GSA IdP", "SAML 2.0")

    Rel(cfRouter, csbAWS, "Routes OSBAPI requests", "HTTPS internal CF overlay")
    Rel(cfRouter, csbGCP, "Routes OSBAPI requests [planned]", "HTTPS internal CF overlay")
    Rel(cfRouter, csbAZR, "Routes OSBAPI requests [planned]", "HTTPS internal CF overlay")

    Rel(csbAWS, csbSQL, "Reads/writes OpenTofu state and service records", "MySQL TCP 3306 (CF internal overlay)")
    Rel(csbGCP, csbSQL, "Reads/writes state [planned]", "MySQL TCP 3306")
    Rel(csbAZR, csbSQL, "Reads/writes state [planned]", "MySQL TCP 3306")

    Rel(csbAWS, logg, "Emits broker and OpenTofu logs", "CF Loggregator STDOUT")
    Rel(csbGCP, logg, "Emits broker logs [planned]", "CF Loggregator STDOUT")
    Rel(csbAZR, logg, "Emits broker logs [planned]", "CF Loggregator STDOUT")

    Rel(csbAWS, awsCSP, "Provisions: S3, RDS, ElastiCache, SQS via OpenTofu", "AWS SDK HTTPS 443")
    Rel(csbGCP, gcpCSP, "Provisions: Cloud SQL, GCS, Pub/Sub, Memorystore via OpenTofu [planned]", "GCP SDK HTTPS 443")
    Rel(csbAZR, azrCSP, "Provisions: PostgreSQL, SQL, Redis, Storage, EventHubs via OpenTofu [planned]", "Azure SDK HTTPS 443")

    Rel(github, cfRouter, "Deploys updated broker apps via cf push", "GitHub Actions HTTPS")
```

---

## 5. CSB Component Diagram (C4 L3)

> **SSP Reference:** Section 9.2 (API service written in Go and Terraform), 10.7.2 (IAC Implementation)  
> **Controls:** CM-7, SA-4, SC-2 (Application Partitioning)

Internals of the Cloud Service Broker application — all three broker instances (csb-aws, csb-gcp, csb-azure)
share the same architecture; only the loaded brokerpak differs.

```mermaid
C4Component
    title Component Diagram — CSB Broker Application: csb-aws pattern, csb-gcp and csb-azure share same structure

    Person(eng, "TTS Engineer", "Invokes OSBAPI operations via cf CLI")

    Container_Boundary(csbApp, "csb-aws — Cloud Service Broker App (cloud.gov CF Container)") {

        Component(osbapiHandler, "OSBAPI HTTP Handler", "Go net/http + gorilla/mux", "Implements OSBAPI v2 specification endpoints: GET /v2/catalog, PUT /v2/service_instances/:id (provision), DELETE (deprovision), PUT /v2/service_instances/:id/service_bindings/:id (bind), DELETE (unbind). Validates HTTP Basic Auth credentials (SECURITY_USER_NAME / SECURITY_USER_PASSWORD) on every request.")

        Component(planCatalog, "Plan Catalog Resolver", "Go, loaded from brokerpak YAML", "Reads service and plan definitions from loaded .brokerpak files. Exposes only plans with approved=true. Suppresses non-sandbox plans via GSB_SERVICE_*_PLANS environment variable overrides. Returns catalog JSON for GET /v2/catalog. Enforces ttl_hours ≤ 8 constraint on all plans.")

        Component(tfRunner, "OpenTofu Runner", "OpenTofu v1.11.6 (linux/amd64) subprocess", "Executes OpenTofu (Terraform fork) CLI as a subprocess for provision/deprovision/bind/unbind. Passes input variables mapped from OSBAPI request parameters. Captures stdout/stderr and streams to CF Loggregator. Manages working directory per service instance GUID.")

        Component(pakLoader, "Brokerpak Loader", "Go, reads .brokerpak ZIP archives", "Reads .brokerpak archives from the app container filesystem at startup. For csb-aws: loads csb-brokerpak-aws containing OpenTofu .tf modules + terraform-provider-aws 6.40.0 + OpenTofu v1.11.6 binary. Validates manifest.yml against runtime platform (linux/amd64).")

        Component(stateDB, "State DB Client", "Go database/sql → MySQL driver", "Reads and writes service instance state to csb-sql (MySQL). Per-instance records: service type, plan ID, provision parameters, OpenTofu state blob, binding credentials, TTLExpiry timestamp, Owner/Project tags. Used to reconstruct OpenTofu state for deprovision and unbind operations.")

        Component(credStore, "Credential Manager", "Go, environment variables + future CredHub", "Sources CSP authentication credentials from CF environment at startup: AWS_ACCESS_KEY_ID/SECRET, GOOGLE_CREDENTIALS (JSON), ARM_CLIENT_ID/SECRET. Sources broker auth credentials: SECURITY_USER_NAME, SECURITY_USER_PASSWORD. Sources DB credentials: DB_HOST, DB_USER, DB_PASS injected via cf set-env from VCAP_SERVICES. CredHub migration planned.")

        Component(tagEnforcer, "Resource Tagger", "Go, maps to OpenTofu variables", "Enforces mandatory resource tags on all provisioned CSP resources: Project=tts-sandbox-<owner>, Owner=<owner>@gsa.gov, TTLExpiry=<ISO8601>, CostCenter=sandbox-nonprod, Cloud=aws|gcp|azure, Environment=sandbox. Tags are passed as OpenTofu input variables and cannot be overridden by user parameters.")
    }

    Container_Ext(csbSQL, "csb-sql (MySQL)", "Backing State Database")
    Container_Ext(cfLogg, "CF Loggregator", "Log Aggregation")
    Container_Ext(awsAPI, "AWS Control Plane APIs", "ec2, rds, s3, elasticache, sqs")

    Rel(eng, osbapiHandler, "OSBAPI requests (Basic Auth)", "HTTPS POST/PUT/DELETE")
    Rel(osbapiHandler, planCatalog, "Validate plan, resolve TF entrypoint")
    Rel(osbapiHandler, credStore, "Retrieve broker auth credentials for validation")
    Rel(osbapiHandler, tfRunner, "Invoke OpenTofu with resolved parameters")
    Rel(osbapiHandler, stateDB, "Read/write service instance records")
    Rel(tfRunner, pakLoader, "Load .tf modules and provider binaries")
    Rel(tfRunner, credStore, "Inject CSP credentials as TF provider config")
    Rel(tfRunner, tagEnforcer, "Inject required resource tags as TF variables")
    Rel(tfRunner, awsAPI, "Execute AWS resource CRUD via terraform-provider-aws")
    Rel(tfRunner, cfLogg, "Stream OpenTofu plan/apply/destroy logs", "STDOUT pipe")
    Rel(stateDB, csbSQL, "SQL queries: INSERT/UPDATE/SELECT/DELETE", "MySQL TCP 3306")
```

---

## 6. Deployment Diagram (C4 Deployment)

> **SSP Reference:** Section 10 System Environment, Section 10.9 AWS Services, Section 9.1 System Locations  
> **Controls:** CM-8 (Component Inventory), SA-9 (External Information System Services)

```mermaid
C4Deployment
    title Deployment Diagram — TTS Cloud Sandbox SSB Multi-Cloud

    Deployment_Node(gsa, "GSA Network", "US Government") {
        Deployment_Node(devWS, "TTS Engineer Workstation", "macOS / Linux") {
            Container(cfCLI, "cf CLI v8", "Cloud Foundry CLI binary", "Issues OSBAPI-proxied commands: cf create-service, cf bind-service, cf delete-service. Authenticates via login.fr.cloud.gov SSO passcode (GSA SecureAuth MFA required).")
            Container(prowlerCLI, "Prowler v3.x", "Python CLI tool", "Runs compliance scans: prowler aws --compliance fedramp_moderate_revision_4. Requires read-only IAM credentials injected from scripts/envs/aws.env.")
        }
        Deployment_Node(secureAuthInfra, "GSA SecureAuth", "secureauth.gsa.gov") {
            Container(saml, "SAML 2.0 IdP", "GSA enterprise IdP", "ENT Domain ID + 2FA (email/phone/TOTP) + password. Issues signed SAML assertions consumed by cloud.gov UAA.")
        }
    }

    Deployment_Node(github_infra, "GitHub.com", "SaaS — github.com/GSA-TTS/cloud-sandbox") {
        Container(ghActions, "GitHub Actions Runner", "Ephemeral Ubuntu container", "Runs CI/CD pipeline: gitleaks secret scan, cf push to cloud.gov, pnpm run broker:deploy:aws|gcp|azure.")
        Container(ghRepo, "Git Repository", "Brokerpak submodules + deploy scripts", "Hosts submodules: csb-brokerpak-aws, csb-brokerpak-gcp, csb-brokerpak-azure, prowler.")
    }

    Deployment_Node(cloudgov, "cloud.gov — AWS GovCloud us-gov-west-1", "FedRAMP Moderate P-ATO FR1920000001") {
        Deployment_Node(cgInfra, "cloud.gov Platform Infrastructure", "CF v3 + Diego + BOSH") {
            Container(cgALB, "AWS ALB (cloud.gov-managed)", "AWS Elastic Load Balancer", "Public TLS termination. Routes to CF GoRouter. cloud.gov manages certificates via Let's Encrypt.")
            Container(cgGR, "CF GoRouter", "Cloud Foundry GoRouter v0.290+", "HTTP(S) routing to Garden containers. Enforces HTTPS redirect. Assigns routes: csb-aws-*.app.cloud.gov")
            Container(cgUAA, "CF UAA", "OAuth2 + SAML SP", "Authenticates CF CLI sessions. Proxies to GSA SecureAuth via SAML 2.0. Issues OAuth2 JWT tokens with CF RBAC scopes.")
            Container(cgCAPI, "CF Cloud Controller API", "REST API", "Manages orgs/spaces/apps/services. Records all CF events in audit log. Enforces SpaceDeveloper role requirement for broker registration.")
            Container(cgLogg, "Loggregator + ELK", "CF Doppler + logs.fr.cloud.gov", "Aggregates all app STDOUT/STDERR. Searchable at logs.fr.cloud.gov. Retains logs per cloud.gov P-ATO data retention policy.")
        }
        Deployment_Node(cgOrg, "CF Org: gsa-tts-iae-lava-beds / Space: dev", "Isolated CF Space") {
            Deployment_Node(diegoAWS, "Diego Cell (Garden Container)", "linux/amd64 container, 1G RAM") {
                Container(csbAWSApp, "csb-aws", "CSB v2.6.10 + brokerpak-aws v0.1.0", "Space-scoped OSBAPI broker 'csb-aws-sandbox'. Binary buildpack. Env: AWS_*, DB_*, GSB_SERVICE_* vars. Route: csb-aws-<random>.app.cloud.gov (auto-assigned by cloud.gov)")
            }
            Deployment_Node(diegoGCP, "Diego Cell [planned]", "linux/amd64 container") {
                Container(csbGCPApp, "csb-gcp [planned]", "CSB v2.6.10 + brokerpak-gcp", "Space-scoped broker 'csb-gcp-sandbox'. Requires GOOGLE_CREDENTIALS + GOOGLE_PROJECT.")
            }
            Deployment_Node(diegoAZR, "Diego Cell [planned]", "linux/amd64 container") {
                Container(csbAZRApp, "csb-azure [planned]", "CSB v2.6.10 + brokerpak-azure", "Space-scoped broker 'csb-azure-sandbox'. Requires ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET.")
            }
            Deployment_Node(rdsNode, "AWS RDS (cloud.gov-managed)", "us-gov-west-1, multi-AZ") {
                ContainerDb(csbSQLNode, "csb-sql", "MySQL 8 (aws-rds micro-mysql)", "Shared state DB for all three CSB instances. GUID: 1b10021b-aa8f-4f60-b982-0232311617fa. Host: cg-aws-broker-prodv13tvle2qaefz7l.ci7nkegdizyy.us-gov-west-1.rds.amazonaws.com. Encrypted at rest.")
            }
        }
    }

    Deployment_Node(awsBackend, "AWS us-east-1 (CSB-managed boundary)", "External CSP") {
        Deployment_Node(awsVPC, "VPC: vpc-61e8f005", "CSB sandbox VPC") {
            Container(awsRDS, "RDS PostgreSQL / MySQL", "db.t3.micro, no multi-AZ", "Provisioned per cf create-service csb-aws-postgresql|mysql sandbox-8h. Private subnets only.")
            Container(awsElasti, "ElastiCache Redis cluster", "t2.micro, single-node", "transit_encryption_enabled=true, at_rest_encryption_enabled=true.")
            Container(awsS3, "S3 Buckets", "Standard, private ACL + SSE-S3", "Provisioned in us-east-1. Public access blocked. Bucket policy enforces HTTPS only.")
            Container(awsSQS, "SQS Queues", "Standard queues only", "Encrypted at rest (SSE-SQS). HTTPS-only access.")
        }
    }

    Deployment_Node(gcpBackend, "GCP Sandbox Project (planned)", "External CSP") {
        Container(gcpSQL, "Cloud SQL PostgreSQL", "db-f1-micro, no HA/PITR", "Private IP, no public endpoint.")
        Container(gcpGCS, "Cloud Storage Buckets", "Uniform ACL, 10-day lifecycle", "Google-managed AES-256 encryption.")
    }

    Deployment_Node(azrBackend, "Azure Sandbox Resource Group (planned)", "External CSP") {
        Container(azrPG, "PostgreSQL Flexible Server", "B1ms, no zone redundancy", "Private Access (VNet integration). Azure-managed encryption (AES-256).")
        Container(azrRedis, "Azure Cache for Redis", "C0 Basic, no clustering", "TLS-only access. Non-SSL port disabled.")
    }
```

---

## 7. Data Flow Diagram — SSP Figure 10-1

> **SSP Reference:** Section 10.4 Data Flow (Figure 10-1)  
> **Controls:** SC-8 (Transmission Confidentiality), AU-2 (Audit Events), AC-3 (Access Enforcement)

This diagram documents all data exchanges between actors, boundary components, and service back-ends.
The broker does not act as a gateway between client and the provisioned service instance: it only
sets up the instance and returns credentials.

```mermaid
flowchart TD
    subgraph ACTORS["External Actors"]
        ENG["TTS Engineer\n(cf CLI)"]
        APP["Bound CF Application\n(consumes service creds)"]
        TTLC["TTL Controller\n(planned)"]
        PROW["Prowler Scanner\n(read-only)"]
    end

    subgraph CFPLATFORM["cloud.gov CF Platform"]
        CFAPI2["CF Cloud Controller API\nRecords: actor, timestamp,\naction, outcome"]
        CSBBROKER["CSB Broker App\n(csb-aws | csb-gcp | csb-azure)"]
        STATEDB[("csb-sql\nMySQL\nOpenTofu state +\nservice records")]
        LOGG3["Loggregator\nlogs.fr.cloud.gov"]
        UAA3["CF UAA\nOAuth2 token validation"]
    end

    subgraph CSP_APIS["CSP Control Plane APIs (external)"]
        AWSAPI2["AWS APIs\n(HTTPS 443 + TLS 1.2+)"]
        GCPAPI2["GCP APIs\n[planned]"]
        AZRAPI2["Azure APIs\n[planned]"]
    end

    subgraph CSP_RESOURCES["Provisioned CSP Resources (outside authorization boundary)"]
        AWSRES["AWS Resources\nRDS / S3 / ElastiCache / SQS"]
        GCPRES["GCP Resources [planned]\nCloud SQL / GCS / Pub/Sub"]
        AZRRES["Azure Resources [planned]\nPostgreSQL / Redis / Storage"]
    end

    %% Provision flow
    ENG -- "1. cf create-service csb-aws-postgresql sandbox-8h my-db\n   -c '{owner, project}'\n   [OAuth2 JWT, TLS 1.2+]" --> CFAPI2
    CFAPI2 -- "2. OSBAPI PUT /v2/service_instances/:id\n   [Basic Auth, HTTPS]" --> CSBBROKER
    CSBBROKER -- "3a. tofu apply with RDS module\n   (provider creds from CF env)\n   [HTTPS 443]" --> AWSAPI2
    AWSAPI2 -- "3b. Creates RDS instance\n   + Security Groups + Tags" --> AWSRES
    CSBBROKER -- "4. Write state record\n   (instance GUID, resource ARN,\n   TTLExpiry, Owner tags)\n   [MySQL TCP 3306, CF overlay]" --> STATEDB
    CSBBROKER -- "5. Emit provision logs\n   (tofu plan/apply output)" --> LOGG3

    %% Bind flow
    ENG -- "6. cf bind-service my-app my-db\n   [OAuth2 JWT, TLS 1.2+]" --> CFAPI2
    CFAPI2 -- "7. OSBAPI PUT /v2/service_instances/:id\n   /service_bindings/:bid\n   [Basic Auth, HTTPS]" --> CSBBROKER
    CSBBROKER -- "8. Read resource state\n   (host, port from TF outputs)" --> STATEDB
    CSBBROKER -- "9. Generate binding credentials\n   (random DB user + password)" --> AWSAPI2
    CSBBROKER -- "10. Return credentials JSON\n    {host, port, username,\n     password, uri}" --> CFAPI2
    CFAPI2 -- "11. Inject as VCAP_SERVICES\n    into APP container (restart)" --> APP
    APP -- "12. Connect to provisioned service\n    using VCAP_SERVICES creds\n    [direct to CSP resource,\n     OUTSIDE broker boundary]" --> AWSRES

    %% TTL / Deprovision flow
    TTLC -- "13. Reads TTLExpiry from DB\n    Sends Slack/email at T-1h\n    Calls: cf delete-service\n    at TTL=0" --> CFAPI2
    CFAPI2 -- "14. OSBAPI DELETE /v2/service_instances/:id\n    [Basic Auth, HTTPS]" --> CSBBROKER
    CSBBROKER -- "15. tofu destroy\n    Removes all CSP resources\n    [HTTPS 443]" --> AWSAPI2
    AWSAPI2 --> AWSRES
    CSBBROKER -- "16. Delete state record\n    from csb-sql" --> STATEDB

    %% Monitoring flow
    PROW -- "17. Read CSP resource configs\n    Check encryption, IAM,\n    network settings\n    [read-only API access]" --> AWSAPI2
    PROW -- "17b. GCP checks [planned]" --> GCPAPI2
    PROW -- "17c. Azure checks [planned]" --> AZRAPI2

    style ACTORS fill:#e8eaf6,stroke:#3949ab
    style CFPLATFORM fill:#e8f5e9,stroke:#2e7d32
    style CSP_APIS fill:#fff8e1,stroke:#f9a825
    style CSP_RESOURCES fill:#fce4ec,stroke:#c62828,stroke-dasharray:5
```

---

## 8. Authentication Flow — SSP Section 9.4

> **SSP Reference:** Section 9.4 Types of Users (Privileged User Access workflow)  
> **Controls:** IA-2 (Identification and Authentication), AC-17 (Remote Access), AC-3 (Access Enforcement)

### 8a. CF CLI Authentication (SSP Section 9.4)

```mermaid
sequenceDiagram
    actor Dev as TTS Engineer
    participant CLI as cf CLI (local)
    participant CFAPI3 as CF API<br/>api.fr.cloud.gov
    participant UAA4 as CF UAA<br/>login.fr.cloud.gov
    participant SA3 as GSA SecureAuth<br/>secureauth.gsa.gov/idp

    Dev->>CLI: cf login -a api.fr.cloud.gov --sso
    CLI->>CFAPI3: GET /v2/info (discover UAA endpoint)
    CFAPI3-->>CLI: {authorization_endpoint: login.fr.cloud.gov}
    CLI-->>Dev: Open browser: login.fr.cloud.gov/passcode
    Dev->>UAA4: GET /passcode (browser)
    note over Dev,UAA4: AC-8 — System Use Notification banner displayed
    UAA4-->>Dev: Prompt: Select Identity Provider
    Dev->>UAA4: Select "GSA" (SAML redirect)
    UAA4->>SA3: SAML AuthnRequest (redirect)
    SA3-->>Dev: Prompt: ENT Domain ID
    Dev->>SA3: Enter ENT Domain ID
    SA3-->>Dev: Prompt: Select 2FA method (email/phone/TOTP)
    Dev->>SA3: Submit 2FA code
    SA3-->>Dev: Prompt: Password
    Dev->>SA3: Enter ENT Domain password
    SA3-->>UAA4: SAML Response (signed assertion)
    UAA4-->>Dev: Display Temporary Authentication Code (OTP)
    Dev->>CLI: Paste Temporary Authentication Code
    CLI->>UAA4: POST /oauth/token (grant_type=password, code=<OTP>)
    UAA4-->>CLI: OAuth2 access_token + refresh_token (JWT)
    CLI-->>Dev: Authenticated. Select org/space.
    Dev->>CLI: Target org: gsa-tts-iae-lava-beds, space: dev
    CLI->>CFAPI3: All subsequent API calls use Bearer <access_token>
    note over CLI,CFAPI3: IA-2(1) — MFA enforced for all network access to privileged CF commands
```

### 8b. CF RBAC Authorization for Service Broker Operations

```mermaid
flowchart LR
    subgraph AUTHN["Authentication Layer"]
        UAA5["CF UAA\nValidates JWT\nChecks scope + expiry"]
    end
    subgraph AUTHZ["Authorization Layer (CF RBAC)"]
        CAPI2["CF Cloud Controller\nRole-based access checks"]
        direction TB
        ORG_ADMIN["OrgAdmin\nCan manage all spaces\n+ register org-scoped brokers"]
        SPACE_DEV["SpaceDeveloper\nCan: cf create-service,\ncf bind-service,\ncf delete-service,\nregister space-scoped brokers"]
        SPACE_MGR["SpaceManager\nCan: add/remove users,\nmanage space settings"]
        SPACE_AUD["SpaceAuditor\nRead-only: cf services,\ncf service-brokers\n(audit/ISSO role)"]
    end
    subgraph BROKER_AUTH["CSB Broker API Auth (HTTP Basic)"]
        BASIC["SECURITY_USER_NAME\nSECURITY_USER_PASSWORD\n(CF env, targeting CredHub migration)"]
    end

    UAA5 --> CAPI2
    CAPI2 --> ORG_ADMIN
    CAPI2 --> SPACE_DEV
    CAPI2 --> SPACE_MGR
    CAPI2 --> SPACE_AUD
    CAPI2 -- "OSBAPI forwarded with Basic Auth" --> BROKER_AUTH
    SPACE_DEV -- "Can invoke provision/bind/unbind/deprovision" --> BROKER_AUTH

    style AUTHN fill:#e3f2fd,stroke:#1565c0
    style AUTHZ fill:#e8f5e9,stroke:#2e7d32
    style BROKER_AUTH fill:#fff3e0,stroke:#e65100
```

---

## 9. TTL Sandbox Lifecycle Sequence

> **SSP Reference:** Custom governance — TTL policy (8h default, one 4h renewal)  
> **Controls:** CP-10 (Recovery & Reconstitution), CM-8 (Component Inventory), SI-7 (Software Integrity)

```mermaid
sequenceDiagram
    actor Dev as TTS Engineer
    participant CLI2 as cf CLI
    participant CFAPI4 as CF Cloud Controller API
    participant CSB as CSB Broker (csb-aws)
    participant TF as OpenTofu Runner
    participant AWS3 as AWS (CSP Backend)
    participant TTLCTRL as TTL Controller [planned]
    participant DB as csb-sql (State DB)
    participant NOTIFY as Notification Channel<br/>(Slack / Email / SMS)

    Note over Dev,AWS3: === PROVISION ===
    Dev->>CLI2: cf create-service csb-aws-postgresql sandbox-8h my-db<br/>-c '{"owner":"dev@gsa.gov","project":"sprint-42"}'
    CLI2->>CFAPI4: PUT /v2/service_instances/my-db
    CFAPI4->>CSB: OSBAPI PUT /v2/service_instances/:id<br/>(Basic Auth, HTTPS)
    CSB->>TF: tofu apply rds-postgres.tf<br/>{instance_class: db.t3.micro, multi_az: false, storage_encrypted: true}
    TF->>AWS3: CreateDBInstance + tag: TTLExpiry=T+8h,<br/>Owner=dev@gsa.gov, Project=tts-sandbox-sprint-42,<br/>CostCenter=sandbox-nonprod, Environment=sandbox
    AWS3-->>TF: DB endpoint + ARN
    TF-->>CSB: TF outputs: {host, port}
    CSB->>DB: INSERT service_instance<br/>{guid, type, plan, ttl_expires_at=T+8h, owner, project, arn}
    CSB-->>CFAPI4: 201 Created {dashboard_url}
    CFAPI4-->>CLI2: Service instance created
    CLI2-->>Dev: OK

    Note over TTLCTRL,NOTIFY: === T-1h WARNING ===
    TTLCTRL->>DB: SELECT * FROM service_instances<br/>WHERE ttl_expires_at BETWEEN NOW() AND NOW()+1h
    DB-->>TTLCTRL: [{my-db, owner=dev@gsa.gov, expires=T}]
    TTLCTRL->>NOTIFY: Send: "⚠️ my-db expires in 60 min.<br/>Renew: cf update-service my-db -c '{\"extend_hours\":4}'"

    Note over Dev,DB: === OPTIONAL RENEWAL (once only) ===
    Dev->>CLI2: cf update-service my-db -c '{"extend_hours":4}'
    CLI2->>CFAPI4: PATCH /v2/service_instances/my-db
    CFAPI4->>CSB: OSBAPI PATCH /v2/service_instances/:id
    CSB->>DB: UPDATE service_instance<br/>SET ttl_expires_at=T+4h, renewal_count=1<br/>WHERE guid=my-db AND renewal_count < 1
    CSB-->>CFAPI4: 200 OK
    Note over CSB,DB: Second renewal attempt → HTTP 409 Conflict

    Note over TTLCTRL,AWS3: === TTL EXPIRY — AUTO DEPROVISION ===
    TTLCTRL->>DB: SELECT WHERE ttl_expires_at <= NOW()
    DB-->>TTLCTRL: [{my-db, expired}]
    TTLCTRL->>CLI2: cf delete-service my-db -f
    CLI2->>CFAPI4: DELETE /v2/service_instances/my-db
    CFAPI4->>CSB: OSBAPI DELETE /v2/service_instances/:id
    CSB->>TF: tofu destroy rds-postgres.tf
    TF->>AWS3: DeleteDBInstance (skip final snapshot)
    AWS3-->>TF: DB deleted
    TF-->>CSB: destroy complete
    CSB->>DB: DELETE FROM service_instances WHERE guid=my-db
    CSB-->>CFAPI4: 200 OK
    CFAPI4-->>CLI2: Deleted
    TTLCTRL->>NOTIFY: "✅ my-db (dev@gsa.gov) deprovisioned after TTL expiry"
```

---

## 10. CI/CD Pipeline — SSP Sections 10.7.3 & 10.7.9

> **SSP Reference:** Section 10.7.3 Pipeline Design, 10.7.9 Code Change and Release Management  
> **Controls:** CM-3 (Configuration Change Control), SA-10 (Developer Configuration Management), SA-11 (Security Testing)

```mermaid
flowchart TD
    subgraph DEV_FLOW["Developer Workflow"]
        DE["TTS Engineer\npushes feature branch"]
        PR["GitHub Pull Request\n(refs issue, security impact analysis)"]
    end

    subgraph CI_CHECKS["CI Checks (parallel — GitHub Actions)"]
        GITLEAKS["gitleaks protect --staged\n(pre-commit hook)\n+ gitleaks detect (full scan)\nFails on: real credentials,\nAPI keys, tokens"]
        LINT["pnpm lint\n(node/gatsby linting)\n+ cf CLI validation"]
        TESTS["Unit + integration tests\n(pnpm test)"]
        SEC_SCAN["Security scan\n(Prowler submodule integrity check +\nOpenTofu validate in brokerpak submodules)"]
    end

    subgraph REVIEW["Code Review (required)"]
        PEER["Peer reviewer:\n- Checks security impact analysis\n- Reviews brokerpak plan changes\n- Verifies no hardcoded secrets\n- Approves PR"]
    end

    subgraph DEPLOY_DEV["Deploy to cloud.gov dev space"]
        BUILD_ENV["Load env file:\nscripts/envs/aws.env (git-ignored)\n(real credentials from CredHub/TechOps)"]
        DB_CHECK["pnpm run broker:db\n(ensure csb-sql exists)"]
        CF_PUSH["pnpm run broker:deploy:aws\n→ scripts/deploy-aws.sh\n→ scripts/lib/cf-push-broker.sh\n  1. cf push --no-start\n  2. cf bind-service csb-aws csb-sql\n  3. Extract DB creds from VCAP_SERVICES\n  4. cf set-env (DB_HOST, DB_USER, etc.)\n  5. cf start csb-aws\n  6. cf create-service-broker csb-aws-sandbox"]
        SMOKE["Smoke tests:\ncf marketplace -e csb\n(verify sandbox-8h plans visible)"]
    end

    subgraph POST_DEPLOY["Post-Deploy Verification"]
        PROWLER_SCAN["pnpm run prowler:scan:aws\n(Prowler FedRAMP Moderate scan)\nOutputs → oscal_assessment-results_schema.json"]
        STATUS["pnpm run broker:status\n(cf apps + cf service-brokers\n+ cf marketplace output)"]
    end

    DE --> PR
    PR --> CI_CHECKS
    GITLEAKS --> PEER
    LINT --> PEER
    TESTS --> PEER
    SEC_SCAN --> PEER
    PEER -- "Approves PR\n(all checks green)" --> REVIEW
    REVIEW -- "Merge to main" --> BUILD_ENV
    BUILD_ENV --> DB_CHECK
    DB_CHECK --> CF_PUSH
    CF_PUSH --> SMOKE
    SMOKE --> POST_DEPLOY
    PROWLER_SCAN --> STATUS

    style CI_CHECKS fill:#e8f5e9,stroke:#2e7d32
    style REVIEW fill:#e3f2fd,stroke:#1565c0
    style DEPLOY_DEV fill:#fff3e0,stroke:#e65100
    style POST_DEPLOY fill:#f3e5f5,stroke:#6a1b9a
```

---

## 11. RBAC & Access Control

> **SSP Reference:** Section 9.4 Types of Users, Section 10.8.7 Privilege Management  
> **Controls:** AC-2 (Account Management), AC-3 (Access Enforcement), AC-6 (Least Privilege)

```mermaid
flowchart TB
    subgraph USERS["User Categories (SSP Section 9.4)"]
        direction LR
        GSA_ENG["TTS Engineer\n(Internal, Privileged)\nSpaceDeveloper role"]
        GSA_OPS["TTS TechOps / Org Admin\n(Internal, Privileged)\nOrgAdmin + OrgManager roles"]
        ISSO_ROLE["ISSO / Security Auditor\n(Internal, Read-only)\nSpaceAuditor role"]
        CI_SA["CI/CD Service Account\n(Automation)\nSpaceDeveloper via GitHub Actions"]
    end

    subgraph AUTHN_LAYER["Authentication (IA-2, IA-5)"]
        direction LR
        MFA_ENG["GSA SecureAuth SSO\nENT Domain ID + 2FA + Password\n→ CF UAA OAuth2 JWT\n(IA-2, IA-2(1), IA-2(12) PIV)"]
        SA_CI["GitHub Secrets\n(Rotated service account creds)\n→ CF UAA OAuth2 JWT"]
    end

    subgraph AUTHZ_CF["CF RBAC Roles (AC-2, AC-3)"]
        ORG_MAN["OrgManager\nManage org users and quotas"]
        ORG_ADM["OrgAdmin\nAll org operations incl.\nbilling and quotas"]
        SP_DEV["SpaceDeveloper\n✅ cf create-service\n✅ cf bind-service\n✅ cf delete-service\n✅ cf push (broker apps)\n✅ cf create-service-broker\n   (space-scoped)\n❌ cf delete-org\n❌ cf set-quota"]
        SP_MGR["SpaceManager\n✅ Manage space members\n✅ View apps/services\n❌ Push apps\n❌ Provision services"]
        SP_AUD["SpaceAuditor\n✅ View apps + services\n✅ View logs (read-only)\n❌ Modify anything"]
    end

    subgraph CSP_IAM["CSP IAM Least Privilege (AC-6, SA-9)"]
        AWS_IAM["AWS IAM Key\n(csb-aws app only)\nActions scoped to:\n- rds:Create/Delete/Describe\n- s3:Create/Delete/GetPolicy\n- elasticache:Create/Delete\n- sqs:Create/Delete/GetAttr\nNo: IAM, EC2, VPC write perms"]
        GCP_SA["GCP Service Account\n(csb-gcp app — planned)\nRoles: cloudsql.admin,\nstorage.admin,\nredis.admin, pubsub.admin\nScoped to sandbox project only\nNo: project-level IAM admin"]
        AZR_SP["Azure Service Principal\n(csb-azure app — planned)\nRole: Contributor\nScoped to sandbox resource group\nNo: subscription-level Owner\nNo: Azure AD assignments"]
    end

    GSA_ENG --> MFA_ENG
    GSA_OPS --> MFA_ENG
    ISSO_ROLE --> MFA_ENG
    CI_SA --> SA_CI

    MFA_ENG --> SP_DEV
    MFA_ENG --> SP_MGR
    MFA_ENG --> SP_AUD
    MFA_ENG --> ORG_MAN
    MFA_ENG --> ORG_ADM
    SA_CI --> SP_DEV

    SP_DEV --> AWS_IAM
    SP_DEV --> GCP_SA
    SP_DEV --> AZR_SP

    style USERS fill:#e8eaf6,stroke:#3949ab
    style AUTHN_LAYER fill:#e8f5e9,stroke:#2e7d32
    style AUTHZ_CF fill:#e3f2fd,stroke:#1565c0
    style CSP_IAM fill:#fff3e0,stroke:#e65100
```

---

## 12. Logging & Monitoring Data Flow

> **SSP Reference:** Section 10.8.5 Logs and Log Integration, Section 10.8.10 Monitoring and Alerting  
> **Controls:** AU-2 (Audit Events), AU-12 (Audit Generation), SI-4 (Information System Monitoring)

```mermaid
flowchart LR
    subgraph SOURCES["Log & Event Sources"]
        direction TB
        CSB_LOG["CSB Broker App\n(csb-aws, csb-gcp, csb-azure)\nSTDOUT/STDERR\n- OSBAPI request logs\n- OpenTofu plan/apply/destroy output\n- Binding credential generation events"]
        CF_AUDIT["CF Cloud Controller API\n(CF Audit Events)\n- cf create-service / delete-service\n- cf push / cf start / cf stop\n- cf bind-service / unbind-service\n- cf create-service-broker\nActor + timestamp + outcome"]
        DB_LOG["csb-sql (MySQL)\n- Query logs (planned)\n- Slow query log"]
        CSP_CLOUD_TRAIL["AWS CloudTrail\nAll AWS API calls:\n- CreateDBInstance, DeleteDBInstance\n- CreateBucket, DeleteBucket\n- CreateReplicationGroup\n- CreateQueue\nSource IP, caller identity, timestamp"]
        PROWLER_LOG["Prowler Findings\n- PASS / FAIL per control\n- Severity: CRITICAL/HIGH/MEDIUM/LOW\n- FedRAMP Moderate compliance %"]
    end

    subgraph AGGREGATION["Log Aggregation & Storage"]
        LOGG_CF["CF Loggregator\n(cloud.gov Doppler firehose)\nStreams: CSB app logs + CF events\nRetention: cloud.gov P-ATO policy"]
        ELK["logs.fr.cloud.gov\n(ELK stack, cloud.gov-managed)\nSearchable by: app GUID, timestamp,\nspace, org, actor\nAccess: SpaceDeveloper + SpaceAuditor"]
        S3_TRAIL["AWS CloudTrail S3 Bucket\n(CSB-managed boundary)\nImmutable audit trail\nat-rest encrypted (SSE-S3)\nRetention: 365 days (planned)"]
        OSCAL_AR["OSCAL Assessment Results\ncontent/oscal_assessment-results_schema.json\nStructured compliance findings\nfrom Prowler scans"]
        OSCAL_POAM["OSCAL POA&M\ncontent/oscal_poam_schema.json\nHIGH: remediate ≤30 days\nCRITICAL: remediate ≤15 days"]
    end

    subgraph CONSUMERS["Log Consumers & Alerting"]
        direction TB
        ISSO_C["ISSO / Security Auditor\nReviews logs.fr.cloud.gov\nReviews OSCAL assessment results\nManages POA&M"]
        OPS_C["TTS TechOps\nMonitors CF app health\nResponds to CF audit events\nManages CredHub rotation"]
        TTL_C["TTL Controller [planned]\nConsumes csb-sql TTLExpiry\nTriggers cf delete-service\nSends Slack/email/SMS alerts"]
        ALERT["Alerting [planned]\nGitHub Issues (CRITICAL Prowler finds)\nSlack Webhook (TTL expiry)\nAWS Security Hub (AWS findings)"]
    end

    CSB_LOG --> LOGG_CF
    CF_AUDIT --> LOGG_CF
    LOGG_CF --> ELK
    CSP_CLOUD_TRAIL --> S3_TRAIL
    PROWLER_LOG --> OSCAL_AR
    PROWLER_LOG --> OSCAL_POAM
    DB_LOG --> ELK

    ELK --> ISSO_C
    ELK --> OPS_C
    S3_TRAIL --> ISSO_C
    OSCAL_AR --> ISSO_C
    OSCAL_POAM --> ISSO_C
    OSCAL_POAM --> OPS_C
    PROWLER_LOG --> ALERT
    ALERT --> OPS_C
    ALERT --> TTL_C

    style SOURCES fill:#e8f5e9,stroke:#2e7d32
    style AGGREGATION fill:#e3f2fd,stroke:#1565c0
    style CONSUMERS fill:#fce4ec,stroke:#c62828
```

---

## Appendix: Component Summary Table

> **SSP Reference:** Table 9-2 System Assets, Table 10-1 Asset Physical and Virtual Components

| Component                | Type                        | Hosts                                  | Status            | Key Controls                 |
| ------------------------ | --------------------------- | -------------------------------------- | ----------------- | ---------------------------- |
| `csb-aws`                | CF App (Go binary)          | cloud.gov dev space                    | ✅ Running        | AC-2, AC-3, AU-2, CM-7, IA-2 |
| `csb-gcp`                | CF App (Go binary)          | cloud.gov dev space                    | ⏳ Pending        | SA-9, SC-7, SC-28            |
| `csb-azure`              | CF App (Go binary)          | cloud.gov dev space                    | ⏳ Pending        | SA-9, SC-7, SC-28            |
| `csb-sql`                | MySQL (aws-rds micro-mysql) | cloud.gov (AWS GovCloud)               | ✅ Running        | SC-28, AU-12                 |
| csb-brokerpak-aws v0.1.0 | Brokerpak (.brokerpak ZIP)  | loaded into csb-aws                    | ✅ Active         | SA-9, SC-7, SC-13, SI-2      |
| csb-brokerpak-gcp        | Brokerpak (.brokerpak ZIP)  | loaded into csb-gcp                    | ⏳ Pending        | SA-9, SC-7, SC-28            |
| csb-brokerpak-azure      | Brokerpak (.brokerpak ZIP)  | loaded into csb-azure                  | ⏳ Pending        | SA-9, SC-7, SC-28            |
| `cloud.gov`              | PaaS (FedRAMP P-ATO)        | AWS GovCloud us-gov-west-1             | ✅ Inherited      | AC-2, AU-8, IA-2, SC-7, SC-8 |
| GSA SecureAuth           | IdP (SAML 2.0)              | GSA enterprise                         | ✅ Inherited      | IA-2, IA-2(1), IA-2(12)      |
| `Prowler v3.x`           | Security scanner            | Developer workstation / GitHub Actions | ⏳ Config pending | CA-2, CA-7, RA-5, SI-4       |
| TTL Controller           | Lifecycle enforcer          | TBD (CF app / GH Actions)              | 🔲 Planned        | CP-10, CM-8, SI-7            |
| `logs.fr.cloud.gov`      | ELK log aggregation         | cloud.gov (inherited)                  | ✅ Inherited      | AU-2, AU-12, AU-9            |
| GitHub.com CI/CD         | SaaS (GitHub Actions)       | GitHub.com                             | ✅ Active         | CM-3, SA-10, SA-11           |
| OpenTofu v1.11.6         | IaC runtime                 | embedded in brokerpak                  | ✅ Active         | CM-3, SA-4, SA-10            |

---

_Generated: 2026-04-14 | System: TTS Cloud Sandbox SSB v0.1.0-draft | OSCAL version: 1.0.4_  
_Cross-reference: [oscal_component_schema.json](../content/oscal_component_schema.json) | [oscal_ssp_schema.json](../content/oscal_ssp_schema.json)_
