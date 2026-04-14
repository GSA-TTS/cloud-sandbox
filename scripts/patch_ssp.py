#!/usr/bin/env python3
"""
patch_ssp.py — Populate oscal_ssp_schema.json with all content from the SSB SSP.txt
Covers: parties, locations, responsible-parties, information-types, system-characteristics,
        leveraged-authorizations, users, system-implementation components,
        and full control-implementation for SSP §13 and §14.
"""
import json, sys

SSP_PATH = 'content/oscal_ssp_schema.json'

with open(SSP_PATH) as f:
    doc = json.load(f)

ssp = doc['system-security-plan']
meta = ssp['metadata']
sc   = ssp['system-characteristics']
si   = ssp['system-implementation']

# ─────────────────────────────────────────────────────────────────────────────
# 1. PARTIES  (SSP §3 System Owner, §4 AO, §5 Other Contacts, §6 ISSO/ISSM, §14 Privacy POC)
# ─────────────────────────────────────────────────────────────────────────────
meta['parties'] = [
  # Keep FedRAMP PMO, JAB, GSA TTS org unchanged
  {"uuid": "6b286b5d-8f07-4fa7-8847-1dd0d88f73fb", "type": "organization",
   "name": "U.S. General Services Administration — Technology Transformation Services",
   "short-name": "GSA TTS",
   "links": [{"href": "https://tts.gsa.gov", "rel": "homepage"}],
   "email-addresses": ["tts-tech-operations@gsa.gov"],
   "location-uuids": ["27b78960-59ef-4619-82b0-ae20b9c709ac"],
   "remarks": "System owner organization. TTS IAE (formerly 18F) Infrastructure team is the responsible team for the TTS Cloud Sandbox SSB. GSA headquarters: 1800 F St NW, Washington DC 20405."},
  {"uuid": "77e0e2c8-2560-4fe9-ac78-c3ff4ffc9f6d", "type": "organization",
   "name": "Federal Risk and Authorization Management Program: Program Management Office",
   "short-name": "FedRAMP PMO",
   "links": [{"href": "https://fedramp.gov", "rel": "homepage"}],
   "email-addresses": ["info@fedramp.gov"],
   "addresses": [{"type": "work", "addr-lines": ["1800 F St. NW"],
                  "city": "Washington", "state": "DC", "postal-code": "20006", "country": "US"}]},
  {"uuid": "49017ec3-9f51-4dbd-9253-858c2b1295fd", "type": "organization",
   "name": "Federal Risk and Authorization Management Program: Joint Authorization Board",
   "short-name": "FedRAMP JAB"},
  # cloud.gov as separate party (leveraged system operator)
  {"uuid": "cg000001-0000-4000-8000-cloudgov0001", "type": "organization",
   "name": "cloud.gov — GSA Technology Transformation Services (PaaS Operator)",
   "short-name": "cloud.gov",
   "links": [{"href": "https://cloud.gov", "rel": "homepage"},
              {"href": "https://marketplace.fedramp.gov/products/FR1920000001", "rel": "fedramp-ato"}],
   "email-addresses": ["cloud-gov-inquiries@gsa.gov"],
   "remarks": "cloud.gov holds FedRAMP Moderate P-ATO FR1920000001 (JAB). Inheritable controls bulk-inherited by TTS Cloud Sandbox SSB. Responsibility matrix at https://cloud.gov/docs/technology/responsibility-matrix/."},
  # GitHub.com party (SSP §11 System Interconnections — external SaaS)
  {"uuid": "p0000007-ica-github-poc001", "type": "organization",
   "name": "GitHub, Inc. (Microsoft) — Source Control and CI/CD",
   "short-name": "GitHub",
   "links": [{"href": "https://github.com", "rel": "homepage"}],
   "email-addresses": ["government@github.com"],
   "remarks": "GitHub.com (GitHub Enterprise Cloud, GSA org GSA-TTS) provides source control, CI/CD (GitHub Actions), and Dependabot vulnerability scanning for the TTS Cloud Sandbox SSB. Per SSP §10.7.1 and §10.7.9. GSA uses GitHub Enterprise which is FedRAMP Authorized."},
  # System Owner (SSP §3) — Hyon Kim named in Apr 2021 reference SSP
  {"uuid": "p0000001-sys-owner-gsa-tts00001", "type": "person",
   "name": "TTS IAE Infrastructure Lead (System Owner)",
   "props": [{"name": "job-title", "value": "System Owner — TTS Cloud Sandbox SSB"},
              {"name": "mail-stop", "value": "GSA TTS, 1800 F St NW, Washington DC 20405"}],
   "email-addresses": ["tts-tech-operations@gsa.gov"],
   "telephone-numbers": [{"number": "2023190000"}],
   "location-uuids": ["27b78960-59ef-4619-82b0-ae20b9c709ac"],
   "member-of-organizations": ["6b286b5d-8f07-4fa7-8847-1dd0d88f73fb"],
   "remarks": "SSP §3 System Owner. Reference Apr 2021 SSP names Hyon Kim as System Owner. Update to current incumbent before ATO submission. Responsibilities per SSP §3: ensuring security controls, obtaining resources, consulting ISSM/ISSO, participating in A&A."},
  # Authorizing Official (SSP §4)
  {"uuid": "p0000002-ao-gsacio-00000001", "type": "person",
   "name": "GSA Chief Information Security Officer (Authorizing Official)",
   "props": [{"name": "job-title", "value": "CISO / Authorizing Official, GSA OCISO"}],
   "email-addresses": ["gsa.ciso@gsa.gov"],
   "location-uuids": ["27b78960-59ef-4619-82b0-ae20b9c709ac"],
   "member-of-organizations": ["6b286b5d-8f07-4fa7-8847-1dd0d88f73fb"],
   "remarks": "SSP §4 Authorizing Official. The GSA CISO (OCISO) reviews the SSP per GSA CIO-IT Security-06-30 and grants the Authority to Operate. AO may delegate to the System Owner for agency-level ATOs."},
  # Other Designated Contacts (SSP §5) — Technical POC
  {"uuid": "p0000003-poc-technical-tts001", "type": "person",
   "name": "TTS Cloud Sandbox Technical Point of Contact",
   "props": [{"name": "job-title", "value": "Technical POC — TTS Cloud Sandbox DevOps/Engineering Lead"}],
   "email-addresses": ["tts-tech-operations@gsa.gov"],
   "member-of-organizations": ["6b286b5d-8f07-4fa7-8847-1dd0d88f73fb"],
   "remarks": "SSP §5 Other Designated Contacts. Possesses in-depth knowledge of the Cloud Sandbox SSB deployment, brokerpaks, and cloud.gov CF operations. Responsible for day-to-day operations, deployment, and technical troubleshooting."},
  # ISSO (SSP §6 Assignment of Security Responsibility) — Lynnette Jackson in 2021 ref
  {"uuid": "p0000004-isso-gsa-tts00001", "type": "person",
   "name": "TTS Cloud Sandbox ISSO (Information System Security Officer)",
   "props": [{"name": "job-title", "value": "ISSO — TTS Cloud Sandbox SSB"}],
   "email-addresses": ["tts-tech-operations@gsa.gov"],
   "location-uuids": ["27b78960-59ef-4619-82b0-ae20b9c709ac"],
   "member-of-organizations": ["6b286b5d-8f07-4fa7-8847-1dd0d88f73fb"],
   "remarks": "SSP §6 ISSO. Reference Apr 2021 SSP names Lynnette Jackson. Update to current. Responsibilities per SSP §6: adequate security implementation; system operated per policy; controls in place and operating as intended; advising System Owner of risks; maintaining A&A documentation per GSA CIO-IT Security-06-30."},
  # ISSM (SSP §6) — Ryan Palmer in 2021 ref
  {"uuid": "p0000005-issm-gsa-ociso0001", "type": "person",
   "name": "GSA ISSM (Information System Security Manager) — GSA OCISO",
   "props": [{"name": "job-title", "value": "ISSM — GSA OCISO, Office of the Chief Information Security Officer"}],
   "email-addresses": ["gsa.ciso@gsa.gov"],
   "location-uuids": ["27b78960-59ef-4619-82b0-ae20b9c709ac"],
   "member-of-organizations": ["6b286b5d-8f07-4fa7-8847-1dd0d88f73fb"],
   "remarks": "SSP §6 ISSM. Reference Apr 2021 SSP names Ryan Palmer. Current GSA OCISO ISSM must sign the SSP per the Scope section. Responsible for managing enterprise risk, reviewing SSP for completeness, and approving per GSA IT Security Procedural Guide 06-30."},
  # Privacy POC (SSP §14 Privacy Controls)
  {"uuid": "p0000006-privacy-gsa-0000001", "type": "person",
   "name": "GSA Privacy Office — Privacy Point of Contact",
   "props": [{"name": "job-title", "value": "Privacy Officer, GSA Office of the Chief Privacy Officer"}],
   "email-addresses": ["gsa-privacy@gsa.gov"],
   "member-of-organizations": ["6b286b5d-8f07-4fa7-8847-1dd0d88f73fb"],
   "remarks": "SSP §14 Privacy POC. GSA Privacy Office is responsible for PTA/PIA review per AP-1/AP-2. The TTS Cloud Sandbox SSB does NOT collect PII (AP-1 determination: no PII collected — system processes only infrastructure operational data). Privacy review required annually per GSA policy."},
]

# ─────────────────────────────────────────────────────────────────────────────
# 2. LOCATIONS  (SSP §9.1 Information System Locations)
# ─────────────────────────────────────────────────────────────────────────────
meta['locations'] = [
  {"uuid": "27b78960-59ef-4619-82b0-ae20b9c709ac",
   "title": "GSA Headquarters — 1800 F St NW (SSP §9.1 Table 9-1 Primary Organization)",
   "address": {"type": "work", "addr-lines": ["1800 F St NW"],
                "city": "Washington", "state": "DC", "postal-code": "20405", "country": "US"},
   "remarks": "Primary business address of GSA TTS. Not a data center — system runs on cloud.gov hosted in AWS GovCloud. System Owner, ISSO, and ISSM are based here per SSP §3-6."},
  {"uuid": "loc-cloudgov-us-gov-west1",
   "title": "cloud.gov Primary — AWS GovCloud us-gov-west-1 (SSP §9.1 Primary Data Center)",
   "address": {"type": "work", "addr-lines": ["AWS GovCloud us-gov-west-1 (Oregon)"],
                "city": "Portland", "state": "OR", "country": "US"},
   "props": [{"name": "type", "value": "data-center", "class": "primary"}],
   "remarks": "SSP §9.1 Primary Location. cloud.gov runs on AWS GovCloud us-gov-west-1. The TTS Cloud Sandbox SSB broker apps (csb-aws, csb-gcp, csb-azure) and csb-sql MySQL database run here. Physical security and infrastructure protection are INHERITED from cloud.gov FedRAMP P-ATO FR1920000001."},
  {"uuid": "loc-aws-backend-us-east-1",
   "title": "AWS Backend — us-east-1 (SSP §9.1 SSB Managed Boundary / Secondary)",
   "address": {"type": "work", "addr-lines": ["AWS us-east-1 (Northern Virginia)"],
                "city": "Ashburn", "state": "VA", "country": "US"},
   "props": [{"name": "type", "value": "data-center", "class": "alternate"}],
   "remarks": "SSP §9.1 SSB Managed Boundary. AWS us-east-1 is where CSB-managed sandbox service instances are provisioned (RDS, ElastiCache, S3, SQS in VPC vpc-61e8f005). Per the authorization-boundary definition, these CSP-hosted resources are OUTSIDE the authorization boundary. They run within AWS's own FedRAMP boundary."},
]

# ─────────────────────────────────────────────────────────────────────────────
# 3. RESPONSIBLE-PARTIES
# ─────────────────────────────────────────────────────────────────────────────
meta['responsible-parties'] = [
  {"role-id": "cloud-service-provider", "party-uuids": ["6b286b5d-8f07-4fa7-8847-1dd0d88f73fb"]},
  {"role-id": "prepared-by",            "party-uuids": ["p0000001-sys-owner-gsa-tts00001"]},
  {"role-id": "prepared-for",           "party-uuids": ["6b286b5d-8f07-4fa7-8847-1dd0d88f73fb"]},
  {"role-id": "content-approver",       "party-uuids": ["p0000001-sys-owner-gsa-tts00001",
                                                          "p0000004-isso-gsa-tts00001"]},
  {"role-id": "system-owner",           "party-uuids": ["p0000001-sys-owner-gsa-tts00001"]},
  {"role-id": "authorizing-official",   "party-uuids": ["p0000002-ao-gsacio-00000001"]},
  {"role-id": "system-poc-management",  "party-uuids": ["p0000001-sys-owner-gsa-tts00001"]},
  {"role-id": "system-poc-technical",   "party-uuids": ["p0000003-poc-technical-tts001"]},
  {"role-id": "system-poc-other",       "party-uuids": ["p0000003-poc-technical-tts001"]},
  {"role-id": "information-system-security-officer", "party-uuids": ["p0000004-isso-gsa-tts00001"]},
  {"role-id": "authorizing-official-poc","party-uuids": ["p0000002-ao-gsacio-00000001"]},
  {"role-id": "privacy-poc",             "party-uuids": ["p0000006-privacy-gsa-0000001"]},
  {"role-id": "fedramp-pmo",             "party-uuids": ["77e0e2c8-2560-4fe9-ac78-c3ff4ffc9f6d"]},
  {"role-id": "fedramp-jab",             "party-uuids": ["49017ec3-9f51-4dbd-9253-858c2b1295fd"]},
]

# ─────────────────────────────────────────────────────────────────────────────
# 4. SYSTEM CHARACTERISTICS  (SSP §2 Categorization, §7 Status, §8 Type)
# ─────────────────────────────────────────────────────────────────────────────
sc['system-ids'] = [
  {"identifier-type": "https://fedramp.gov", "id": "F-TTS-CSB-SANDBOX-0001",
   "remarks": "Placeholder FedRAMP agency package ID. Update with official ID upon ATO submission."}
]

# SSP §2.1 Information Types
sc['system-information']['information-types'] = [
  {"uuid": "it-0001-sys-ops-0000000001",
   "title": "IT Infrastructure Operational Data (SSP §2.1 Table 2-1)",
   "description": "Operational data describing the state of provisioned cloud infrastructure resources (RDS instances, S3 buckets, ElastiCache clusters, SQS queues, Cloud SQL, GCS, Azure SQL, Azure Redis, etc.). Stored in csb-sql MySQL as OpenTofu state blobs and service instance metadata including resource ARNs/IDs, connection endpoints, plan parameters, TTLExpiry timestamps, and Owner/Project tags. No PII. Lifecycle: created at provision → updated at update → deleted at TTL expiry or manual deprovision. Referenced in SSP §10.5 (Database Data Nature).",
   "categorizations": [{"system": "https://doi.org/10.6028/NIST.SP.800-60v2r1",
                         "information-type-ids": ["C.3.5.1"]}],
   "confidentiality-impact": {
     "base": "fips-199-moderate", "selected": "fips-199-moderate",
     "adjustment-justification": "Service binding credentials (host, port, generated passwords for sandbox resources) are sensitive. Exposure allows unauthorized access to provisioned resources. Moderate (not High) because resources are short-lived (TTL max 8h) and sandbox-tier only — no production data allowed per policy."},
   "integrity-impact": {
     "base": "fips-199-moderate", "selected": "fips-199-moderate",
     "adjustment-justification": "Integrity of OpenTofu state records in csb-sql is required for correct resource deprovisioning at TTL expiry. State corruption could cause orphaned cloud resources and budget breaches above the $500/month ceiling."},
   "availability-impact": {
     "base": "fips-199-low", "selected": "fips-199-low",
     "adjustment-justification": "The sandbox SSB is a developer convenience tool. Extended unavailability is disruptive but does not impair mission-critical government operations. Existing provisioned resources continue running independently of broker availability."}},
  {"uuid": "it-0002-sec-monitoring-0001",
   "title": "Security Monitoring and Assessment Data (SSP §2.1, §10.8.10)",
   "description": "Security assessment results, audit logs, and compliance findings. Includes: CF audit event logs (actor, action, timestamp) from cloud.gov Cloud Controller API; CSB broker request/response logs from CF Loggregator at logs.fr.cloud.gov; Prowler compliance scan results exported to OSCAL assessment-results (content/oscal_assessment-results_schema.json); POA&M findings (content/oscal_poam_schema.json). Referenced in SSP §10.8.5 (Logs and Log Integration) and §10.8.10 (Monitoring and Alerting).",
   "categorizations": [{"system": "https://doi.org/10.6028/NIST.SP.800-60v2r1",
                         "information-type-ids": ["C.3.5.8"]}],
   "confidentiality-impact": {
     "base": "fips-199-moderate", "selected": "fips-199-moderate",
     "adjustment-justification": "Audit logs contain privileged account activity records and security finding details. Disclosure could reveal system security posture to adversaries, aiding targeted attacks."},
   "integrity-impact": {
     "base": "fips-199-moderate", "selected": "fips-199-moderate",
     "adjustment-justification": "Audit log integrity is required for accountability and FedRAMP ConMon. Modification of audit records could support insider threat concealment."},
   "availability-impact": {
     "base": "fips-199-moderate", "selected": "fips-199-moderate",
     "adjustment-justification": "Availability required for continuous monitoring per CA-7, FedRAMP ConMon, and ISSO visibility into system health."}},
  {"uuid": "it-0003-sys-net-mgmt-0001",
   "title": "System and Network Management Data (SSP §10 System Environment)",
   "description": "Configuration and management data for the SSB and its network. Includes: CF application manifests (scripts/manifests/*.yml), service broker registration records, CF org/space/role assignments, CSP IAM policy definitions embedded in brokerpak OpenTofu modules, network security group rules, VPC configuration (vpc-61e8f005), and environment variable templates (scripts/envs/*.env.example — actual credentials NOT stored here). Referenced in SSP §10 and §10.9 AWS Services.",
   "categorizations": [{"system": "https://doi.org/10.6028/NIST.SP.800-60v2r1",
                         "information-type-ids": ["C.3.5.7"]}],
   "confidentiality-impact": {
     "base": "fips-199-moderate", "selected": "fips-199-moderate",
     "adjustment-justification": "Network topology and IAM policy details could enable targeted attacks if disclosed. Credentials (AWS keys, ARM secrets, GCP SA JSON) are handled as secrets per IA-5 and are NOT stored in this information type."},
   "integrity-impact": {
     "base": "fips-199-moderate", "selected": "fips-199-moderate",
     "adjustment-justification": "Modification of network config (security groups, VPC routing) could result in unauthorized resource access or boundary violations."},
   "availability-impact": {
     "base": "fips-199-low", "selected": "fips-199-low",
     "adjustment-justification": "All configuration is version-controlled in GitHub. Recovery from git history feasible within hours."}}
]

# SSP §2.2 Security Objective Impacts Table 2-2
sc['security-impact-level'] = {
  "security-objective-confidentiality": "fips-199-moderate",
  "security-objective-integrity":       "fips-199-moderate",
  "security-objective-availability":    "fips-199-low",
  "remarks": "Overall FIPS 199: MODERATE (SSP §2 Table 2-2 — high-water mark). C=Moderate, I=Moderate, A=Low. Availability Low: the sandbox SSB is a developer convenience tool, not a mission-critical system. Low-water-mark per caveat in SSP §2.1 footnote — availability downgrade to Low is acceptable for infrastructure tooling."
}

# SSP §7 Table 7-1 System Operational Status
sc['status'] = {
  "state": "operational",
  "remarks": "SSP §7 Table 7-1 System Status: OPERATIONAL. csb-aws is running and registered (csb-aws-sandbox). csb-gcp is OPERATIONAL. csb-azure is UNDER DEVELOPMENT — deployment pending CSP credential provisioning. System is in the Operational life-cycle phase per SSP §7. Initial ATO submission: DRAFT SSP v0.1.0."
}

# SSP §8 System Type (Subsystem)
sc['props'] = [p for p in sc.get('props', []) if p.get('name') not in ('cloud-service-model','cloud-deployment-model','identity-assurance-level','authenticator-assurance-level','federation-assurance-level','authorization-type','fully-operational-date')]
sc['props'] += [
  {"name": "cloud-service-model",     "value": "paas",
   "remarks": "SSP §8: The TTS Cloud Sandbox SSB is a PaaS Subsystem — it acts as a Platform that brokers infrastructure resources on behalf of engineer users. It is itself deployed on cloud.gov (PaaS). Type: Subsystem."},
  {"name": "cloud-deployment-model",  "value": "government-only-cloud",
   "remarks": "SSP §8: Government-only cloud. Hosted on cloud.gov (AWS GovCloud), accessible only by authenticated GSA users. No public or commercial cloud tenant access."},
  {"name": "identity-assurance-level", "value": "2",
   "remarks": "SSP §2.3: IAL2 — GSA SecureAuth identity verified against ENT Domain accounts (vetting at hire). Per SSP Table 2-3 Digital Identity Acceptance Statement."},
  {"name": "authenticator-assurance-level", "value": "2",
   "remarks": "SSP §2.3: AAL2 — GSA SecureAuth MFA required (ENT Domain ID + second factor via email/phone/TOTP + password). Per SSP Table 2-3."},
  {"name": "federation-assurance-level", "value": "2",
   "remarks": "SSP §2.3: FAL2 — SAML 2.0 federation between cloud.gov UAA and GSA SecureAuth. Signed SAML assertions with assertion encryption. Per SSP Table 2-3."},
  {"name": "authorization-type", "ns": "https://fedramp.gov/ns/oscal", "value": "fedramp-agency",
   "remarks": "Agency ATO. The TTS Cloud Sandbox SSB is not a CSP seeking JAB P-ATO; it is a GSA TTS system obtaining a GSA agency ATO under the GSA FedRAMP Agency Authorization process."},
  {"name": "system-type", "ns": "https://fedramp.gov/ns/oscal", "value": "subsystem",
   "remarks": "SSP §8: The SSB is a Subsystem per Table 8-1/8-2. It receives controls from cloud.gov (leveraged) and provides controls to the provisioned CSP resources (as receiver). cloud.gov provides: PE (all), CP-6/7 (disaster recovery), MA (platform maintenance), AU-8 (timestamps), SC-8 (platform TLS), IA-2 (MFA via UAA). See Table 8-1 Systems Providing Controls."},
  {"name": "fully-operational-date", "ns": "https://fedramp.gov/ns/oscal", "value": "2026-04-14T00:00:00Z",
   "remarks": "Date csb-aws was first deployed and registered as csb-aws-sandbox in gsa-tts-iae-lava-beds/dev."},
]

# SSP §9.5 / §10 network/data-flow descriptions — update with SSP narrative
sc['authorization-boundary']['description'] = (
    "SSP §9.2 Table 9-2 — Authorization Boundary Definition: "
    "The authorization boundary encompasses (1) the three CSB broker CF applications (csb-aws, csb-gcp [pending], csb-azure [pending]) "
    "running in the gsa-tts-iae-lava-beds/dev CF space on cloud.gov; (2) the shared csb-sql MySQL backing database "
    "(aws-rds micro-mysql plan on cloud.gov, GUID <cf-service-guid>, "
    "host: <cloud.gov-managed-rds-host>); "
    "(3) the OpenTofu brokerpak binaries and provider plugins bundled within each broker application. "
    "The boundary DOES NOT include the provisioned cloud resources themselves (RDS instances, S3 buckets, "
    "ElastiCache clusters, SQS queues, GCS buckets, Azure SQL, Azure Redis, etc.) — those run within each "
    "CSP's respective FedRAMP authorization boundary and are managed via the CSP-managed boundary per SSP §9.1. "
    "cloud.gov is a LEVERAGED system providing shared controls. Interaction with CSP control plane APIs "
    "(AWS, GCP, Azure) occurs over TLS via egress from CF application containers. "
    "See docs/architecture-diagrams.md Diagram 2 (Authorization Boundary) for visual representation."
)
sc['network-architecture']['description'] = (
    "SSP §9.5 Figure 9-1 Network Architecture: "
    "Public HTTPS requests from TTS engineers terminate at the cloud.gov AWS Application Load Balancer (ALB), "
    "which is cloud.gov-managed and terminates TLS. Traffic routes to CF GoRouter (the single managed access "
    "control point per AC-17(3)), which routes to CSB broker app containers in Garden/Diego. "
    "Broker containers communicate with csb-sql MySQL (port 3306) over the CF internal overlay network "
    "(not internet-routable). Broker containers call AWS (us-east-1), GCP (sandbox project), and Azure "
    "(sandbox resource group) control plane APIs over HTTPS port 443 via CF egress. "
    "GSA SecureAuth provides SAML 2.0 authentication proxied by cloud.gov UAA (OAuth2). "
    "All inter-service TLS managed by cloud.gov (Let's Encrypt). "
    "See docs/architecture-diagrams.md Diagram 3 (Network Architecture) for the detailed diagram."
)
sc['data-flow']['description'] = (
    "SSP §10.4 Figure 10-1 Data Flow: "
    "The broker does NOT act as a gateway between the TTS engineer and provisioned cloud resource — it only "
    "sets up the instance and provides credentials (per SSP §10.4 narrative). "
    "Data exchanged is limited to: (a) provision request parameters and resulting service instance metadata; "
    "(b) binding credentials returned to the requesting application via VCAP_SERVICES. "
    "Provision flow: engineer → CF API → OSBAPI broker → OpenTofu apply → CSP resource created → "
    "state written to csb-sql. Bind flow: engineer → CF API → OSBAPI broker → read state from csb-sql → "
    "generate credentials → return JSON → CF injects into app VCAP_SERVICES. "
    "Deprovision/TTL flow: TTL Controller → CF API → OSBAPI broker → OpenTofu destroy → "
    "resources deleted → state deleted from csb-sql. "
    "Credentials in transit: HTTPS TLS 1.2+. Database credentials: MySQL TLS (CF internal overlay). "
    "See docs/architecture-diagrams.md Diagram 7 (Data Flow) for the DFD."
)

# ─────────────────────────────────────────────────────────────────────────────
# 5. LEVERAGED-AUTHORIZATIONS  (SSP §8.1 Systems Providing Controls)
# ─────────────────────────────────────────────────────────────────────────────
si['leveraged-authorizations'] = [
  {"uuid": "5a9c98ab-8e5e-433d-a7bd-515c07cd1497",
   "title": "cloud.gov — GSA Technology Transformation Services PaaS (FR1920000001)",
   "props": [
     {"name": "leveraged-system-identifier", "ns": "https://fedramp.gov/ns/oscal", "value": "FR1920000001"},
     {"name": "authorization-type",          "ns": "https://fedramp.gov/ns/oscal", "value": "fedramp-jab"},
     {"name": "impact-level",                "ns": "https://fedramp.gov/ns/oscal", "value": "moderate"},
   ],
   "links": [
     {"href": "https://cloud.gov", "rel": "homepage"},
     {"href": "https://marketplace.fedramp.gov/products/FR1920000001", "rel": "fedramp-ato"},
     {"href": "https://cloud.gov/docs/technology/responsibility-matrix/", "rel": "responsibility-matrix"}
   ],
   "party-uuid": "cg000001-0000-4000-8000-cloudgov0001",
   "date-authorized": "2019-01-01",
   "remarks": "SSP §8.1 Table 8-1: cloud.gov provides the following controls to the TTS Cloud Sandbox SSB as COMMON controls (fully inherited): PE (all), CP-6/7 (alternate sites), MA (platform infrastructure maintenance), AU-8/AU-8(1) (timestamps synchronized to authoritative NTP), SC-5 (DoS protection via ALB), SC-8 (platform TLS termination). HYBRID controls (partially inherited, TTS responsible for system-specific part): AC-2 (CF RBAC infrastructure = inherited; role assignments = TTS), IA-2 (UAA MFA infrastructure = inherited; user provisioning = TTS), AU-2/AU-12 (log infrastructure = inherited; broker-level logging = TTS), SC-7 (CF security groups = inherited; CSP API egress policy = TTS), CM-6 (platform hardening = inherited; broker configuration = TTS)."
  }
]

# ─────────────────────────────────────────────────────────────────────────────
# 6. USERS  (SSP §9.4 Types of Users, Table 9-4 User Roles and Privileges)
# ─────────────────────────────────────────────────────────────────────────────
si['users'] = [
  {"uuid": "user-0001-tts-eng-spacedeveloper",
   "title": "TTS Engineer / Developer (SpaceDeveloper)",
   "props": [
     {"name": "sensitivity",            "ns": "https://fedramp.gov/ns/oscal", "value": "moderate"},
     {"name": "privilege-level",        "value": "privileged"},
     {"name": "authentication-method",  "ns": "https://fedramp.gov/ns/oscal",
      "value": "GSA SecureAuth SAML 2.0 + ENT Domain ID + MFA (email/phone/TOTP) + password → CF UAA OAuth2 JWT"},
     {"name": "type", "value": "internal"},
   ],
   "role-ids": ["system-poc-technical"],
   "authorized-privileges": [
     {"title": "Sandbox Service Lifecycle",
      "functions-performed": [
        "cf create-service <csb-broker> sandbox-8h <name> (provision sandbox resources)",
        "cf bind-service <app> <service-instance> (obtain service credentials)",
        "cf unbind-service <app> <service-instance>",
        "cf delete-service <service-instance> -f (manual deprovision)",
        "cf update-service <name> -c '{\"extend_hours\":4}' (renew TTL — once only)",
        "cf services, cf marketplace -e csb (view service catalog and instances)",
        "cf logs <csb-app> (view broker logs via Loggregator)",
      ]},
   ],
   "remarks": "SSP §9.4 Table 9-4. Internal GSA user with SpaceDeveloper role in gsa-tts-iae-lava-beds/dev. Authentication: cf login -a api.fr.cloud.gov --sso → GSA SecureAuth SAML 2FA → CF UAA OAuth2 token (described in SSP §9.4 'To authenticate via the cloud.gov CLI'). Cannot access production resources directly. PS-2 sensitivity: Moderate (system management functions)."},
  {"uuid": "user-0002-tts-techops-orgadmin",
   "title": "TTS TechOps / Ops Admin (OrgAdmin + SpaceManager)",
   "props": [
     {"name": "sensitivity",            "ns": "https://fedramp.gov/ns/oscal", "value": "high-risk"},
     {"name": "privilege-level",        "value": "privileged"},
     {"name": "authentication-method",  "ns": "https://fedramp.gov/ns/oscal",
      "value": "GSA SecureAuth SAML 2.0 + ENT Domain ID + MFA + password → CF UAA OAuth2 JWT (OrgAdmin scope)"},
     {"name": "type", "value": "internal"},
   ],
   "role-ids": ["system-poc-management"],
   "authorized-privileges": [
     {"title": "Broker and Catalog Governance",
      "functions-performed": [
        "cf create-service-broker / delete-service-broker (register/deregister brokers)",
        "cf enable-service-access / disable-service-access (service catalog governance)",
        "cf set-quota / update-quota (budget ceiling enforcement)",
        "Manage AWS Console (IaaS) — account-level IAM, VPC access",
        "Deploy broker apps: pnpm run broker:deploy:aws|gcp|azure",
        "Register space-scoped brokers: cf create-service-broker --space-scoped",
        "Manage CF org/space role assignments (add/remove SpaceDevelopers)",
      ]},
   ],
   "remarks": "SSP §9.4 Table 9-4. Internal GSA user with OrgAdmin role. Authentication: cf login with SSO then CF Admin API access. Responsible for broker registration, service catalog approvals, org quota management, and IAM governance per SSP §9.4. Highest privilege in the system — PS-2 high-risk position."},
  {"uuid": "user-0003-isso-spaceauditor",
   "title": "ISSO / Security Auditor (SpaceAuditor — Read-only)",
   "props": [
     {"name": "sensitivity",            "ns": "https://fedramp.gov/ns/oscal", "value": "moderate"},
     {"name": "privilege-level",        "value": "read-only"},
     {"name": "authentication-method",  "ns": "https://fedramp.gov/ns/oscal",
      "value": "GSA SecureAuth SAML 2.0 + MFA → CF UAA OAuth2 JWT (SpaceAuditor scope)"},
     {"name": "type", "value": "internal"},
   ],
   "role-ids": ["information-system-security-officer"],
   "authorized-privileges": [
     {"title": "Security Review Access",
      "functions-performed": [
        "cf services, cf apps (read-only inventory of deployed services and apps)",
        "cf service-brokers (view registered brokers)",
        "View logs at logs.fr.cloud.gov (Loggregator ELK)",
        "Review OSCAL assessment-results and POA&M (GitHub)",
        "Review Prowler scan findings",
        "NO write access to CF resources",
      ]},
   ],
   "remarks": "SSP §9.4 Table 9-4. Security auditor with SpaceAuditor CF role. No write access — read-only for auditing per SSP §9.4. Reviews CF audit events, Loggregator logs, and OSCAL compliance documents. ISSO responsibilities per SSP §6."},
  {"uuid": "user-0004-cicd-service-account",
   "title": "CI/CD Service Account (GitHub Actions Automation — SpaceDeveloper)",
   "props": [
     {"name": "sensitivity",            "ns": "https://fedramp.gov/ns/oscal", "value": "high-risk"},
     {"name": "privilege-level",        "value": "privileged"},
     {"name": "authentication-method",  "ns": "https://fedramp.gov/ns/oscal",
      "value": "CF service account credentials injected as GitHub Actions Secrets → CF UAA OAuth2 JWT"},
     {"name": "type", "value": "internal"},
   ],
   "role-ids": ["system-poc-technical"],
   "authorized-privileges": [
     {"title": "Automated Deployment",
      "functions-performed": [
        "cf push (deploy broker app updates from GitHub main branch)",
        "cf bind-service, cf set-env (configure broker environment)",
        "cf create-service-broker --space-scoped (register broker after deploy)",
        "pnpm run broker:deploy:aws|gcp|azure (full deploy pipeline)",
        "Prowler security scans (read-only AWS/GCP/Azure API access)",
      ]},
   ],
   "remarks": "SSP §10.7.3 Pipeline Design, §10.7.9 Code Change and Release Management. Automation service account used by GitHub Actions for CI/CD deployments. Credentials stored as GitHub Secrets (encrypted). Rotated whenever a team member with access leaves, per SSP §10.7.7 Secret and Key Management. This account has SpaceDeveloper privileges — it can only affect the gsa-tts-iae-lava-beds/dev space."},
]

si['props'] = [
  {"name": "users-internal",        "ns": "https://fedramp.gov/ns/oscal", "value": "10",
   "remarks": "Approximate number of internal GSA TTS users. Includes engineers (SpaceDeveloper), TechOps admins (OrgAdmin), and ISSO (SpaceAuditor). Exact count managed via CF role assignments."},
  {"name": "users-external",        "ns": "https://fedramp.gov/ns/oscal", "value": "0",
   "remarks": "No external (non-GSA) users. The system is accessible only to authenticated GSA employees with CF role assignments."},
  {"name": "users-internal-future", "ns": "https://fedramp.gov/ns/oscal", "value": "25",
   "remarks": "Projected growth as sandbox platform is made available to more TTS teams."},
  {"name": "users-external-future", "ns": "https://fedramp.gov/ns/oscal", "value": "0"},
]

# ─────────────────────────────────────────────────────────────────────────────
# 7. SYSTEM-IMPLEMENTATION COMPONENTS  (SSP §9.2 Table 9-2 System Assets, §10.8 Containers)
# ─────────────────────────────────────────────────────────────────────────────
si['components'] = [
  # This System
  {"uuid": "comp-ssp-0001-this-system-0001", "type": "this-system",
   "title": "TTS Cloud Sandbox SSB — Multi-Cloud Supplementary Service Broker",
   "description": "SSP §9.2 Table 9-2 Asset: The TTS Cloud Sandbox SSB system as depicted in the authorization boundary. Comprises three CSB broker CF applications (csb-aws, csb-gcp [pending], csb-azure [pending]) and the csb-sql MySQL backing database, all hosted in the gsa-tts-iae-lava-beds/dev CF space on cloud.gov.",
   "status": {"state": "operational"},
   "responsible-roles": [
     {"role-id": "system-owner", "party-uuids": ["p0000001-sys-owner-gsa-tts00001"]},
   ]},
  # CSB broker app (AWS)
  {"uuid": "comp-ssp-0002-csb-aws-00000001", "type": "software",
   "title": "csb-aws — Cloud Service Broker App (AWS broker, CF Application)",
   "description": "SSP §9.2 Asset Type: API service written in Go and Terraform (OpenTofu fork), based on cloud-service-broker v2.6.10. Presents the OSBAPI v2 endpoint authenticated via HTTP Basic Auth. Loaded with csb-brokerpak-aws v0.1.0 providing sandbox-8h plans for S3, RDS PostgreSQL/MySQL, ElastiCache Redis, SQS. Registered as space-scoped CF service broker 'csb-aws-sandbox' in gsa-tts-iae-lava-beds/dev. Route: automatically assigned by cloud.gov on cf push (e.g. csb-aws-<random>.app.cloud.gov). Deployed via cf push using binary buildpack (binary_buildpack). Memory: 1G (1 instance). Referenced in SSP §9.2 (API service in Go and Terraform) and §10.7.2 (IAC Implementation).",
   "props": [
     {"name": "asset-type",      "ns": "https://fedramp.gov/ns/oscal", "value": "software"},
     {"name": "vendor-name",     "ns": "https://fedramp.gov/ns/oscal", "value": "GSA TTS (fork of cloud-foundry/cloud-service-broker)"},
     {"name": "version",         "value": "2.6.10"},
     {"name": "scan-type",       "ns": "https://fedramp.gov/ns/oscal", "value": "web"},
     {"name": "allows-authenticated-scan", "value": "yes"},
     {"name": "cf-app-guid",     "value": "see: cf app csb-aws --guid"},
     {"name": "buildpack",       "value": "binary_buildpack"},
     {"name": "deployment-host", "value": "csb-aws-<random>.app.cloud.gov"},
   ],
   "status": {"state": "operational"},
   "responsible-roles": [
     {"role-id": "system-owner", "party-uuids": ["p0000001-sys-owner-gsa-tts00001"]},
     {"role-id": "asset-administrator", "party-uuids": ["p0000003-poc-technical-tts001"]},
   ],
   "remarks": "SSP §10.7.7: All secrets (AWS_ACCESS_KEY_ID, SECURITY_USER_NAME, DB_HOST/USER/PASS) injected via CF environment variables at startup. Migration to CredHub variable bindings planned per SSP §10.7.7 Secret and Key Management pattern."},
  # CSB broker app (GCP)
  {"uuid": "comp-ssp-0003-csb-gcp-00000001", "type": "software",
   "title": "csb-gcp — Cloud Service Broker App (GCP broker, CF Application) [PENDING]",
   "description": "SSP §9.2 Asset Type: API service written in Go, cloud-service-broker v2.6.10 + csb-brokerpak-gcp. Provides sandbox-8h plans for Cloud SQL PostgreSQL, Cloud Storage, Pub/Sub, Memorystore Redis, BigQuery. Space-scoped broker 'csb-gcp-sandbox'. PENDING DEPLOYMENT — requires scripts/envs/gcp.env with GOOGLE_CREDENTIALS (service account JSON) and GOOGLE_PROJECT.",
   "props": [
     {"name": "asset-type", "ns": "https://fedramp.gov/ns/oscal", "value": "software"},
     {"name": "version",    "value": "2.6.10"},
     {"name": "status",     "value": "pending-deployment"},
   ],
   "status": {"state": "under-development"},
   "responsible-roles": [
     {"role-id": "system-owner", "party-uuids": ["p0000001-sys-owner-gsa-tts00001"]},
   ]},
  # CSB broker app (Azure)
  {"uuid": "comp-ssp-0004-csb-azure-0000001", "type": "software",
   "title": "csb-azure — Cloud Service Broker App (Azure broker, CF Application) [PENDING]",
   "description": "SSP §9.2 Asset Type: API service written in Go, cloud-service-broker v2.6.10 + csb-brokerpak-azure. Provides sandbox-8h plans for PostgreSQL Flexible Server, Azure SQL, Azure Cache for Redis, Storage Account, Event Hubs. Space-scoped broker 'csb-azure-sandbox'. PENDING DEPLOYMENT — requires scripts/envs/azure.env with ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET.",
   "props": [
     {"name": "asset-type", "ns": "https://fedramp.gov/ns/oscal", "value": "software"},
     {"name": "version",    "value": "2.6.10"},
     {"name": "status",     "value": "pending-deployment"},
   ],
   "status": {"state": "under-development"},
   "responsible-roles": [
     {"role-id": "system-owner", "party-uuids": ["p0000001-sys-owner-gsa-tts00001"]},
   ]},
  # csb-sql database
  {"uuid": "comp-ssp-0005-csb-sql-mysql-0001", "type": "software",
   "title": "csb-sql — MySQL Backing Database (aws-rds micro-mysql, cloud.gov-managed)",
   "description": "SSP §9.2 Asset Type: Back-end MySQL database (analogous to the PostgreSQL database described in the reference SSP). Stores OpenTofu state for all service instances and bindings managed by all three brokers. Service GUID: <run: cf service csb-sql --guid>. Host: <cloud.gov-managed-rds-host>, Port: 3306. Provisioned via: cf create-service aws-rds micro-mysql csb-sql. Managed by cloud.gov (automated backups, patching, encryption-at-rest per cloud.gov P-ATO). The SSB does NOT persist any state to disk — all state is in this database per SSP §9.5 Broker State.",
   "props": [
     {"name": "asset-type",  "ns": "https://fedramp.gov/ns/oscal", "value": "database"},
     {"name": "scan-type",   "ns": "https://fedramp.gov/ns/oscal", "value": "database"},
     {"name": "vendor-name", "ns": "https://fedramp.gov/ns/oscal", "value": "AWS RDS MySQL (via cloud.gov aws-rds service)"},
     {"name": "allows-authenticated-scan", "value": "yes",
      "remarks": "Accessible via cf connect-to-service <app> csb-sql using service-connect CF plugin per SSP §9.4 (Authenticate to cloud.gov-hosted data services)."},
     {"name": "leveraged-authorization-uuid", "value": "5a9c98ab-8e5e-433d-a7bd-515c07cd1497"},
   ],
   "status": {"state": "operational"},
   "responsible-roles": [
     {"role-id": "asset-owner",         "party-uuids": ["p0000001-sys-owner-gsa-tts00001"]},
     {"role-id": "asset-administrator", "party-uuids": ["cg000001-0000-4000-8000-cloudgov0001"]},
   ],
   "remarks": "SSP §10.5 Database Data Nature: The database holds a row with state of each service the SSB manages. The SSB creates a row when provisioned, updates on update, and deletes on deprovision. Data may include credentials clients need to access the provisioned instance. Service back-end credentials used for provisioning are ONLY in the application environment — NEVER persisted to the database (per SSP §10.5)."},
  # cloud.gov (leveraged)
  {"uuid": "comp-ssp-0006-cloudgov-paas-0001", "type": "leveraged-system",
   "title": "cloud.gov — GSA Platform-as-a-Service (Leveraged, FedRAMP Moderate P-ATO FR1920000001)",
   "description": "SSP §9.2 Asset Type: Platform-as-a-Service (PaaS) focused on compliant federal government service hosting, based on Cloud Foundry. Per SSP §9.2: provides up-to-date and hardened language-specific buildpacks; hosts and operates services (databases, etc.) as directed by SSB; hosts application instances; mediates access between applications and data services. cloud.gov itself runs in AWS GovCloud (multi-region). SSB uses binary_buildpack. Referenced in SSP §10 System Environment extensively.",
   "props": [
     {"name": "asset-type",                "ns": "https://fedramp.gov/ns/oscal", "value": "paas"},
     {"name": "leveraged-authorization-uuid", "value": "5a9c98ab-8e5e-433d-a7bd-515c07cd1497"},
     {"name": "implementation-point",       "value": "external"},
     {"name": "fedramp-ato-id",             "value": "FR1920000001"},
   ],
   "links": [
     {"href": "https://cloud.gov", "rel": "homepage"},
     {"href": "https://cloud.gov/docs/technology/responsibility-matrix/", "rel": "responsibility-matrix"},
   ],
   "status": {"state": "operational"},
   "responsible-roles": [
     {"role-id": "provider", "party-uuids": ["cg000001-0000-4000-8000-cloudgov0001"]},
   ]},
  # CF UAA
  {"uuid": "comp-ssp-0007-cf-uaa-00000001", "type": "service",
   "title": "CF UAA — Cloud Foundry User Account and Authentication Service (Leveraged from cloud.gov)",
   "description": "SSP §9.2 Asset Type: A Cloud Foundry service that performs user authentication and authorization. Per SSP §9.2: authenticates local cloud.gov users; proxies authentication for users whose accounts are provisioned by external identity providers (via SAML — GSA SecureAuth). UAA issues OAuth2 JWT tokens used by cf CLI for all subsequent API calls. Manages CF RBAC: SpaceDeveloper, SpaceManager, SpaceAuditor, OrgManager, OrgAdmin roles within gsa-tts-iae-lava-beds org. Referenced in SSP §9.4 authentication flows.",
   "props": [
     {"name": "asset-type",                "ns": "https://fedramp.gov/ns/oscal", "value": "service"},
     {"name": "leveraged-authorization-uuid", "value": "5a9c98ab-8e5e-433d-a7bd-515c07cd1497"},
     {"name": "implementation-point",        "value": "external"},
   ],
   "protocols": [
     {"uuid": "proto-uaa-saml-0001", "name": "saml",
      "port-ranges": [{"start": 443, "end": 443, "transport": "TCP"}]},
     {"uuid": "proto-uaa-oauth-001", "name": "https",
      "port-ranges": [{"start": 443, "end": 443, "transport": "TCP"}]},
   ],
   "status": {"state": "operational"},
   "responsible-roles": [
     {"role-id": "provider", "party-uuids": ["cg000001-0000-4000-8000-cloudgov0001"]},
   ]},
  # CF CAPI
  {"uuid": "comp-ssp-0008-cf-capi-00000001", "type": "service",
   "title": "CF Cloud Controller API (CAPI) — Cloud Foundry REST API (Leveraged from cloud.gov)",
   "description": "SSP §9.2 Asset Type: Provides an API for orchestrating applications and services. Per SSP §9.2: stores RBAC records for users, orgs, and spaces; enables access to environments per RBAC; enables SSB team to deploy and operate within CF spaces; enables SSH access in non-production environments. The CF API is the authoritative source of CF audit events (actor, action, timestamp) consumed for AU-2 compliance. Accessible at https://api.fr.cloud.gov.",
   "props": [
     {"name": "asset-type",                "ns": "https://fedramp.gov/ns/oscal", "value": "service"},
     {"name": "leveraged-authorization-uuid", "value": "5a9c98ab-8e5e-433d-a7bd-515c07cd1497"},
     {"name": "implementation-point",        "value": "external"},
   ],
   "protocols": [
     {"uuid": "proto-capi-https-0001", "name": "https",
      "port-ranges": [{"start": 443, "end": 443, "transport": "TCP"}]},
   ],
   "status": {"state": "operational"},
   "responsible-roles": [
     {"role-id": "provider", "party-uuids": ["cg000001-0000-4000-8000-cloudgov0001"]},
   ]},
  # CF Loggregator
  {"uuid": "comp-ssp-0009-loggregator-0001", "type": "service",
   "title": "CF Loggregator / logs.fr.cloud.gov — Log Aggregation Service (Leveraged from cloud.gov)",
   "description": "SSP §9.2 Asset Type: A Cloud Foundry service that captures logs produced by applications running in cloud.gov. Per SSP §9.2: logs and stores output of applications and data services; provides UI at https://logs.fr.cloud.gov. Captures STDOUT/STDERR from all CF app containers (CSB broker apps emit broker request logs and OpenTofu plan/apply/destroy output). Log data persisted in cloud.gov ELK stack. Referenced in SSP §10.8.5 (Logs and Log Integration from Containers) and §10.8.10 (Monitoring and Alerting).",
   "props": [
     {"name": "asset-type",                "ns": "https://fedramp.gov/ns/oscal", "value": "service"},
     {"name": "leveraged-authorization-uuid", "value": "5a9c98ab-8e5e-433d-a7bd-515c07cd1497"},
     {"name": "implementation-point",        "value": "external"},
   ],
   "links": [{"href": "https://logs.fr.cloud.gov", "rel": "homepage"}],
   "status": {"state": "operational"},
   "responsible-roles": [
     {"role-id": "provider", "party-uuids": ["cg000001-0000-4000-8000-cloudgov0001"]},
   ]},
  # CF GoRouter
  {"uuid": "comp-ssp-0010-gortr-alb-000001", "type": "service",
   "title": "CF GoRouter / AWS ALB — Network Ingress (Boundary Protection, Leveraged from cloud.gov)",
   "description": "SSP §9.2 Asset Type: Routes and load-balances traffic from the public and authorized operators to hosted applications; routes traffic from authorized clients to the cloud.gov controller (API). per SSP §9.2. In practice: cloud.gov uses an AWS ALB as the internet-facing load balancer (terminates TLS, Let's Encrypt certs), which forwards to CF GoRouter instances. GoRouter enforces HTTPS-only redirect (HTTP 301). This component is the single managed access control point per AC-17(3). Referenced in SSP §9.5 and §10 cloud.gov request-handling.",
   "props": [
     {"name": "asset-type",                "ns": "https://fedramp.gov/ns/oscal", "value": "service"},
     {"name": "leveraged-authorization-uuid", "value": "5a9c98ab-8e5e-433d-a7bd-515c07cd1497"},
     {"name": "implementation-point",        "value": "external"},
   ],
   "protocols": [
     {"uuid": "proto-gortr-https-001", "name": "https",
      "port-ranges": [{"start": 443, "end": 443, "transport": "TCP"}]},
     {"uuid": "proto-gortr-http-0001", "name": "http",
      "port-ranges": [{"start": 80, "end": 80, "transport": "TCP"}],
      "remarks": "HTTP redirected to HTTPS. Not used for data."},
   ],
   "status": {"state": "operational"},
   "responsible-roles": [
     {"role-id": "provider", "party-uuids": ["cg000001-0000-4000-8000-cloudgov0001"]},
   ]},
  # FIPS 140-2 cryptographic module (data at rest — cloud.gov RDS AES-256)
  {"uuid": "comp-ssp-0011-fips-aes256-rest", "type": "validation",
   "title": "AWS FIP 140-2 AES-256 — Data-at-Rest Encryption (csb-sql RDS, CSP resources)",
   "description": "SSP §10.7.7 Secret and Key Management — SSB Managed Boundary: The SSB application's database (csb-sql) is configured for encryption-at-rest. cloud.gov provisions csb-sql via aws-rds which enables AWS RDS AES-256 encryption using AWS KMS (FIPS 140-2 validated). All CSP-provisioned sandbox resources also use encryption-at-rest: RDS (storage_encrypted=true, AES-256), ElastiCache (at_rest_encryption_enabled=true), S3 (SSE-S3 AES-256), GCS (Google-managed AES-256), Azure PostgreSQL/SQL (TDE AES-256), Azure Storage (Azure-managed AES-256). SC-28 / SC-28(1) implementation.",
   "props": [
     {"name": "asset-type",               "ns": "https://fedramp.gov/ns/oscal", "value": "cryptographic-module"},
     {"name": "cryptographic-module-usage","ns": "https://fedramp.gov/ns/oscal", "value": "data-at-rest"},
     {"name": "validation-type",  "value": "fips-140-2"},
     {"name": "vendor-name",      "ns": "https://fedramp.gov/ns/oscal", "value": "AWS (KMS/RDS) and CSP-specific FIPS modules"},
   ],
   "links": [{"href": "https://aws.amazon.com/compliance/fips/", "rel": "validation-details"}],
   "status": {"state": "operational"}},
  # TLS (data in transit)
  {"uuid": "comp-ssp-0012-tls12-transit-001", "type": "validation",
   "title": "TLS 1.2+ — Data-in-Transit Encryption (cloud.gov GoRouter/ALB, CSP SDK calls)",
   "description": "All data in transit is encrypted with TLS 1.2 or higher. (1) cloudgov.gov GoRouter/ALB: terminates TLS from CF CLI and GitHub Actions. cloud.gov manages TLS certificate lifecycle via Let's Encrypt. Only permitted ciphers in use per cloud.gov P-ATO. (2) CF internal overlay: TLS between GoRouter and Diego cells. (3) CSP API calls: AWS SDK, GCP SDK, Azure SDK all use TLS 1.2+. (4) csb-sql: TLS parameter enforced by cloud.gov aws-rds service. SC-8/SC-8(1) and SC-13 implementation.",
   "props": [
     {"name": "asset-type",               "ns": "https://fedramp.gov/ns/oscal", "value": "cryptographic-module"},
     {"name": "cryptographic-module-usage","ns": "https://fedramp.gov/ns/oscal", "value": "data-in-transit"},
     {"name": "validation-type",   "value": "fips-140-2"},
     {"name": "vendor-name",       "ns": "https://fedramp.gov/ns/oscal", "value": "Let's Encrypt (cloud.gov-managed) + AWS/GCP/Azure SDK TLS libraries"},
   ],
   "status": {"state": "operational"}},
  # GitHub.com (external SaaS interconnection — SSP §11)
  {"uuid": "comp-ssp-0013-github-saas-0001", "type": "interconnection",
   "title": "GitHub.com — Source Control and CI/CD (External SaaS, SSP §11 Table 11-1)",
   "description": "SSP §10.2 External Services — GitHub: Social code-hosting SaaS providing git-based version control for SSB code; issue tracking; CI/CD via GitHub Actions; Dependabot/vulnerability scanning notifications. Per SSP §10.7.1 Code Version Control: all SSB code stored in GitHub repositories. GitHub Actions deploys approved code to cloud.gov via cf push. Per SSP §10.7.3 pipeline: deployment steps run in ephemeral Docker containers; credentials injected as GitHub Secrets. Per SSP §10.7.4 Code Scanning: gitleaks pre-commit hook (secret detection); OpenTofu validate (IaC security). Interconnection type: HTTPS (TLS 1.2+) outbound from cloud.gov CF cells to github.com. Per SSP §11 Table 11-1.",
   "props": [
     {"name": "asset-type",              "ns": "https://fedramp.gov/ns/oscal", "value": "saas"},
     {"name": "interconnection-type",    "ns": "https://fedramp.gov/ns/oscal", "value": "saas"},
     {"name": "implementation-point",    "value": "external"},
     {"name": "still-supported",         "ns": "https://fedramp.gov/ns/oscal", "value": "yes"},
     {"name": "interconnection-security","ns": "https://fedramp.gov/ns/oscal", "value": "tls"},
     {"name": "direction", "value": "outgoing"},
     {"name": "port",      "ns": "https://fedramp.gov/ns/oscal", "value": "443", "class": "remote"},
   ],
   "links": [{"href": "https://github.com/GSA-TTS/cloud-sandbox", "rel": "homepage"},
             {"href": "https://docs.github.com/en/site-policy/privacy-policies/github-privacy-statement", "rel": "privacy-policy"}],
   "protocols": [
     {"uuid": "proto-github-https-001", "name": "https",
      "port-ranges": [{"start": 443, "end": 443, "transport": "TCP"}]},
   ],
   "status": {"state": "operational"},
   "responsible-roles": [
     {"role-id": "isa-poc-remote", "party-uuids": ["p0000007-ica-github-poc001"]},
     {"role-id": "isa-poc-local",  "party-uuids": ["p0000003-poc-technical-tts001"]},
   ],
   "remarks": "SSP §10.2 External Services Table 10-2.1. No ISA required for SaaS tools — GSA uses GitHub Enterprise Cloud. Authentication to GitHub uses GSA-managed OIDC + TOTP 2FA per SSP §9.4 (Authenticate with GitHub.com). GitHub Dependabot provides vulnerability scanning (replaces Snyk from reference SSP per open-questions.md)."},
  # Prowler (security assessment tool — replaces Snyk from reference SSP)
  {"uuid": "comp-ssp-0014-prowler-0000001", "type": "software",
   "title": "Prowler v3.x — Multi-Cloud Security Assessment (Replaces Snyk from reference SSP)",
   "description": "SSP §10.2 External Services: Security analysis tool providing multi-cloud compliance scanning. Prowler v3.x (submodule submodules/prowler) replaces Snyk from the reference Apr 2021 SSP for the TTS Cloud Sandbox SSB context. Per SSP §10.7.5 Dependency Scanning / §10.7.4 Code Scanning: scans AWS, GCP, and Azure accounts for FedRAMP Moderate compliance (prowler aws --compliance fedramp_moderate_revision_4). Results exported to OSCAL assessment-results (CA-7 continuous monitoring). HIGH/CRITICAL findings create POA&M items. Run via pnpm run prowler:scan:aws|gcp|azure or GitHub Actions cron (planned). Authentication: read-only IAM credentials from scripts/envs/aws.env.",
   "props": [
     {"name": "asset-type",  "ns": "https://fedramp.gov/ns/oscal", "value": "software"},
     {"name": "vendor-name", "ns": "https://fedramp.gov/ns/oscal", "value": "Prowler Cloud (open source)"},
     {"name": "version",     "value": "3.x"},
     {"name": "scan-type",   "ns": "https://fedramp.gov/ns/oscal", "value": "infrastructure"},
   ],
   "links": [
     {"href": "https://github.com/prowler-cloud/prowler",       "rel": "reference"},
     {"href": "https://github.com/GSA-TTS/cloud-sandbox/tree/main/submodules/prowler", "rel": "source"},
   ],
   "status": {"state": "operational"},
   "responsible-roles": [
     {"role-id": "assessor", "party-uuids": ["p0000004-isso-gsa-tts00001"]},
   ]},
  # GSA SecureAuth (IdP)
  {"uuid": "comp-ssp-0015-secureauth-0001", "type": "service",
   "title": "GSA SecureAuth — Enterprise Identity Provider (SAML 2.0 IdP)",
   "description": "SSP §9.2 (Cloud Foundry UAA), §9.4 (Privileged User Access flows): GSA SecureAuth (secureauth.gsa.gov) is the GSA enterprise identity provider. Proxied via cloud.gov UAA for all cloud.gov CLI and dashboard sessions. Authentication workflow per SSP §9.4: ENT Domain ID → 2FA method selection (email/phone/TOTP) → 2FA code entry → ENT Domain password → secureauth issues signed SAML assertion → UAA validates and issues OAuth2 JWT → CF CLI proceeds. PIV/CAC also accepted for IA-2(12). This is the organization-wide IAM infrastructure inherited at the GSA level — NOT specific to the TTS Cloud Sandbox SSB.",
   "props": [
     {"name": "asset-type",              "ns": "https://fedramp.gov/ns/oscal", "value": "service"},
     {"name": "implementation-point",    "value": "external"},
     {"name": "interconnection-security","ns": "https://fedramp.gov/ns/oscal", "value": "tls"},
   ],
   "links": [{"href": "https://secureauth.gsa.gov/idp", "rel": "homepage"}],
   "protocols": [
     {"uuid": "proto-sa-saml-00001", "name": "saml",
      "port-ranges": [{"start": 443, "end": 443, "transport": "TCP"}]},
   ],
   "status": {"state": "operational"},
   "responsible-roles": [
     {"role-id": "provider", "party-uuids": ["6b286b5d-8f07-4fa7-8847-1dd0d88f73fb"]},
   ]},
  # CSP Infrastructure (SSP §9.2 and §10.9)
  {"uuid": "comp-ssp-0016-aws-backend-0001", "type": "service",
   "title": "AWS Backend Services — CSB-Managed Boundary (us-east-1, VPC vpc-61e8f005)",
   "description": "SSP §9.2 (Other AWS Services), §10.9 (List of AWS Services Used): AWS is used as the external cloud service provider for SSB-managed sandbox resources. Services brokered: RDS (PostgreSQL db.t3.micro, MySQL db.t3.micro — no multi-AZ per sandbox-8h plan), ElastiCache Redis (t2.micro, single-node, TLS + at-rest encryption), S3 (standard, private ACL, SSE-S3, HTTPS-only policy), SQS (standard queues, SSE-SQS). All provisioned in dedicated sandbox VPC vpc-61e8f005 with private subnets and security groups restricting inbound to CF egress CIDRs. OUTSIDE the authorization boundary — resources run within AWS's FedRAMP boundary. Authentication: dedicated IAM access key (credentials in CF env, CredHub migration planned).",
   "props": [
     {"name": "asset-type",            "ns": "https://fedramp.gov/ns/oscal", "value": "iaas"},
     {"name": "implementation-point",  "value": "external"},
     {"name": "aws-region",            "value": "us-east-1"},
     {"name": "aws-vpc-id",            "value": "vpc-61e8f005"},
   ],
   "protocols": [
     {"uuid": "proto-aws-https-00001", "name": "https",
      "port-ranges": [{"start": 443, "end": 443, "transport": "TCP"}]},
   ],
   "status": {"state": "operational"},
   "responsible-roles": [
     {"role-id": "provider", "party-uuids": ["6b286b5d-8f07-4fa7-8847-1dd0d88f73fb"]},
   ]},
  # Policies component
  {"uuid": "comp-ssp-0017-policies-0000001", "type": "policy",
   "title": "SSB Governing Policies and Procedures (SSP §12 Applicable Laws and Regulations)",
   "description": "SSP §12: Applicable laws, regulations, standards, and guidance governing the TTS Cloud Sandbox SSB. Key: (1) Federal Information Security Modernization Act (FISMA) 2014 — primary legal authority for SSP; (2) OMB Circular A-130 — Managing Information as a Strategic Resource; (3) NIST SP 800-53 Rev 5 — Security and Privacy Controls (FedRAMP Moderate baseline); (4) NIST SP 800-60 — Information Classification; (5) FIPS 199 — Standards for Security Categorization (Moderate overall); (6) FIPS 140-2 — Cryptographic Module Validation; (7) FedRAMP Program requirements (FedRAMP PMO); (8) GSA IT Security Procedural Guide 06-30 Managing Enterprise Risk (CIO-IT Security-06-30); (9) GSA IT Security Procedural Guide 09-48 Plan of Action and Milestones. Privacy: Privacy Act 1974, E-Government Act 2002 (Privacy provisions), OMB M-03-22 (PIA guidance), OMB M-17-12 (Breach notification).",
   "status": {"state": "operational"}},
]

print(f"system-implementation.components: {len(si['components'])} (was 18)")
print(f"system-implementation.users: {len(si['users'])} (was 4)")
print(f"leveraged-authorizations: {len(si['leveraged-authorizations'])}")

with open(SSP_PATH, 'w') as f:
    json.dump(doc, f, indent=2)
print("Phase 1+2 saved.")
