#!/usr/bin/env python3
"""
patch_ssp_controls.py  —  Phase 3: Full control-implementation expansion
Replaces 20 placeholder stubs with real SSP §13 + §14 narratives sourced from
docs/Supplementary Service Broker (SSB) SSP.txt and system architecture.
Target: ~200 control entries covering the full FedRAMP Moderate baseline.
"""
import json, uuid

SSP_PATH = 'content/oscal_ssp_schema.json'
NS = 'https://fedramp.gov/ns/oscal'

# ─── Component UUIDs (from Phase 2 patch) ───────────────────────────────────
SYS   = 'comp-ssp-0001-this-system-0001'   # This System
CSB   = 'comp-ssp-0002-csb-aws-00000001'   # csb-aws broker (canonical)
CG    = 'comp-ssp-0006-cloudgov-paas-0001' # cloud.gov leveraged system
UAA   = 'comp-ssp-0007-cf-uaa-00000001'    # CF UAA
CAPI  = 'comp-ssp-0008-cf-capi-00000001'   # CF Cloud Controller API
LOG   = 'comp-ssp-0009-loggregator-0001'   # CF Loggregator
GTR   = 'comp-ssp-0010-gortr-alb-000001'   # GoRouter/ALB
FIPS  = 'comp-ssp-0011-fips-aes256-rest'   # FIPS AES-256
TLS   = 'comp-ssp-0012-tls12-transit-001'  # TLS 1.2+
GH    = 'comp-ssp-0013-github-saas-0001'   # GitHub
PROWL  = 'comp-ssp-0014-prowler-0000001'    # Prowler
SAUTH  = 'comp-ssp-0015-secureauth-0001'   # GSA SecureAuth
AWS_BE = 'comp-ssp-0016-aws-backend-0001'  # AWS Backend Services
POL    = 'comp-ssp-0017-policies-0000001'  # Policies/Procedures component


def u(seed: str) -> str:
    return str(uuid.uuid5(uuid.NAMESPACE_DNS, f'tts-ssb-ctrl-{seed}'))


def stmt(ctrl_id, parts: list):
    """Build statements list. parts = list of (suffix, [(comp_uuid, desc)])."""
    out = []
    for suffix, comps in parts:
        sid = f'{ctrl_id}_smt' if suffix == 'smt' else f'{ctrl_id}_smt.{suffix}'
        out.append({
            'uuid': u(f'{ctrl_id}-{suffix}'),
            'statement-id': sid,
            'by-components': [
                {'uuid': u(f'{ctrl_id}-{suffix}-{c[:12]}'), 'component-uuid': c,
                 'description': d}
                for c, d in comps
            ]
        })
    return out


def ctrl(cid, status, origination, parts):
    return {
        'uuid': u(f'req-{cid}'),
        'control-id': cid,
        'props': [
            {'name': 'implementation-status', 'ns': NS, 'value': status},
            {'name': 'control-origination',   'ns': NS, 'value': origination},
        ],
        'statements': stmt(cid, parts),
    }


def inh(cid, desc):
    """Fully inherited from cloud.gov."""
    return ctrl(cid, 'inherited', 'inherited',
                [('smt', [(CG, f'INHERITED from cloud.gov FR1920000001. {desc}')])])


def corp(cid, desc):
    """GSA corporate / agency-level control (sp-corporate)."""
    return ctrl(cid, 'implemented', 'sp-corporate',
                [('smt', [(POL, desc)])])


def sys_ctrl(cid, parts_list):
    """System-specific (sp-system) multi-part control."""
    return ctrl(cid, 'implemented', 'sp-system', parts_list)


def na(cid, desc):
    """Not applicable."""
    return ctrl(cid, 'not-applicable', 'sp-system',
                [('smt', [(SYS, desc)])])


# ─────────────────────────────────────────────────────────────────────────────
# CONTROLS
# ─────────────────────────────────────────────────────────────────────────────
reqs = []

# ══════════════════════════════════════
# AC — Access Control
# ══════════════════════════════════════

reqs.append(sys_ctrl('ac-1', [
    ('smt', [(POL, 'INHERITED (corporate): The GSA Access Control policy is defined in GSA IT Security Policy CIO 2100.1 and GSA IT Security Procedural Guide: Access Control CIO-IT Security-01-07. Disseminated agency-wide. GSA OCISO reviews CIO 2100.1 annually and CIO-IT Security-01-07 biennially.'),
             (SYS, 'SYSTEM-SPECIFIC: TTS-specific AC procedures are codified in this SSP (SSP §9.4 Access Types and Procedures), the brokerpak development guidelines (brokerpak.md), and the role-based access policy enforced via CF RBAC (SpaceDeveloper, SpaceManager, SpaceAuditor, OrgAdmin roles in gsa-tts-iae-lava-beds/dev). Reviewed annually as part of SSP review cycle.')])
]))

reqs.append(ctrl('ac-2', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED from cloud.gov: CF UAA manages account records, role-based access controls, and session management. cloud.gov enforces account lifecycle through org/space role assignments managed via CF CAPI. Automated account status managed by cloud.gov platform.'),
        (UAA, 'INHERITED from cloud.gov (CF UAA): CF UAA stores and manages accounts for authenticated users. Org/space role bindings enforced by UAA OAuth2 scope validation on every API call. Account managers = OrgAdmin-level users (TTS TechOps) who control cf set-space-role / cf unset-space-role assignments.'),
        (SYS, 'SYSTEM-SPECIFIC (TTS): Account types (per SSP §9.4): TTS Engineer/SpaceDeveloper (standard access), TTS TechOps/OrgAdmin (privileged), ISSO/SpaceAuditor (read-only), CI/CD Service Account (automated). Account approval required from System Owner. Accounts reviewed quarterly. Individuals departing GSA: CF roles immediately removed within 2 hours per GSA separation procedure. No shared accounts. No guest/anonymous accounts. Temporary accounts (TTL sandbox service accounts via VCAP_SERVICES) are auto-deleted on service deprovision per CP-10 / TTL lifecycle.')
    ])
]))

reqs.append(inh('ac-2.1',
    'CF UAA automated account management: account lifecycle events (create/modify/delete/disable) are recorded in CF CAPI audit log. TTS TechOps uses cf curl /v3/audit_events to review.'))

reqs.append(ctrl('ac-2.2', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Temporary sandbox service credentials (generated by OSBAPI /bind endpoint) are automatically removed when the service binding is deleted (cf unbind-service) or when the service instance is deprovisioned at TTL expiry (max 8h, one 4h renewal). No standing temporary accounts exist in the system. CI/CD service account credentials are rotated whenever a team member with access departs per SSP §10.7.7.')])
]))

reqs.append(ctrl('ac-2.3', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Inactive CF accounts: cloud.gov does not automatically disable inactive accounts by default. TTS TechOps reviews CF org membership quarterly (cf org-users gsa-tts-iae-lava-beds) and removes users with no active role need per the access review required by AC-2. CI/CD service account is reviewed with each quarterly review cycle. Any account unused for 90+ days is disabled per GSA CIO-IT Security-01-07.')])
]))

reqs.append(inh('ac-2.4',
    'CF CAPI automatically generates audit events for all account management actions: creating/modifying/deleting space roles (actor, action, target, timestamp). Events available at https://logs.fr.cloud.gov. TTS ISSO reviews these audit events during quarterly access reviews.'))

reqs.append(ctrl('ac-2.7', 'implemented', 'sp-system', [
    ('smt', [(UAA, 'CF UAA implements role-based schemes: OrgAdmin (full org control), OrgManager (org settings), SpaceManager (space settings), SpaceDeveloper (deploy/provision), SpaceAuditor (read-only). INHERITED infrastructure.'),
             (SYS, 'TTS assigns roles per SSP §9.4 Table 9-4. SpaceDeveloper role grants access only to gsa-tts-iae-lava-beds/dev space — no cross-space or cross-org access. OrgAdmin role restricted to TTS TechOps. Privileged role assignments require System Owner approval per AC-2.')])
]))

reqs.append(ctrl('ac-3', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov CF RBAC enforces access to apps, services, and APIs. CF GoRouter enforces HTTPS-only access. CF CAPI validates UAA JWT OAuth2 scope on every API call.'),
        (SYS, 'SYSTEM-SPECIFIC: CSB OSBAPI endpoint enforces HTTP Basic Auth (SECURITY_USER_NAME/PASSWORD injected via CF env). All OSBAPI requests authenticated and authorized at the broker layer. CSP IAM policies embedded in brokerpak OpenTofu modules restrict provisioned resources to the sandbox VPC (vpc-61e8f005) per principle of least privilege.')
    ])
]))

reqs.append(ctrl('ac-4', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: CF application security groups (ASGs) restrict egress from app containers. GoRouter enforces ingress routing. cloud.gov network architecture prevents lateral movement between apps in different orgs/spaces.'),
        (GTR, 'INHERITED: CF GoRouter routes only to authorized app instances. No direct inter-app communication outside CF internal routes.'),
        (SYS, 'SYSTEM-SPECIFIC: CSB broker outbound calls limited to: csb-sql on CF internal network (port 3306), CSP APIs (AWS/GCP/Azure, port 443). All data flows documented in SSP §10.4 Figure 10-1 and docs/architecture-diagrams.md Diagram 7. No unauthorized data flows are possible given CF security group restrictions.')
    ])
]))

reqs.append(ctrl('ac-5', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'TTS enforces separation of duties among three distinct roles (SSP §9.4): (1) Engineer/SpaceDeveloper — provisions and deprovisions services, cannot modify broker registration or CF org settings; (2) TechOps/OrgAdmin — manages broker deployment and CF org, cannot directly access provisioned CSP resources beyond what the broker provides; (3) ISSO/SpaceAuditor — read-only audit access, no write capabilities. Identity verification for privilege escalation requires System Owner approval. CI/CD pipeline requires GitHub PR review from a ≥1 additional team member before merge-to-main per SSP §10.7.2.')])
]))

reqs.append(ctrl('ac-6', 'implemented', 'sp-system', [
    ('smt', [
        (SYS, 'Least privilege enforced at multiple layers: CF layer: engineers limited to SpaceDeveloper in one org/space (gsa-tts-iae-lava-beds/dev). CSP layer: AWS IAM policy for broker grants only CreateDBInstance/DeleteDBInstance/DescribeDBInstances (and analogous GCP/Azure permissions) scoped to tagged sandbox resources. No IAM AdministratorAccess. Broker OSBAPI endpoint accepts only pre-approved plan+parameters per brokerpak service definition. See brokerpak.md for full IAM permission sets.'),
        (CSB, 'Brokerpak OpenTofu modules create CSP resources with the minimum IAM permissions required for the service type. RDS instances: no iam_database_authentication or enhanced monitoring (sandbox tier). S3 buckets: no PutBucketPolicy, no cross-account access. Redis: no AUTH string exposure beyond the binding credential response.')
    ])
]))

reqs.append(ctrl('ac-6.1', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Access to security functions (broker registration, CF service broker admin, CSP IAM console) restricted to TTS TechOps/OrgAdmin role. ISSO has read-only SpaceAuditor access to monitor but cannot modify security configurations. System Owner approval required to grant OrgAdmin to new individuals.')])
]))

reqs.append(ctrl('ac-6.2', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'TTS Engineers use SpaceDeveloper role (non-privileged relative to OrgAdmin functions) for day-to-day service provisioning. OrgAdmin (privileged) is not granted to Engineers. Engineers cannot modify CF org settings, register service brokers, or set quotas — these require TechOps/OrgAdmin role.')])
]))

reqs.append(ctrl('ac-6.5', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Privileged accounts (OrgAdmin, SpaceManager) restricted to TTS TechOps staff and the System Owner. Privileged account holders limited to minimum 2 individuals (System Owner + one TechOps engineer) for redundancy but not broad access. Privileged accounts reviewed quarterly per AC-2.')])
]))

reqs.append(inh('ac-6.9',
    'CF CAPI audit log records all privileged function executions: cf create-service-broker, cf enable-service-access, cf set-space-role, cf set-quota. Actor, action, and timestamp logged. Audit records accessible at logs.fr.cloud.gov.'))

reqs.append(ctrl('ac-6.10', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Non-privileged users (SpaceDeveloper role) cannot execute privileged CF commands (create-service-broker, enable-service-access, set-quota). CF UAA scope validation prevents unauthorized privilege escalation. Any attempt to call privileged API endpoints without OrgAdmin scope returns 403 Forbidden.')])
]))

reqs.append(inh('ac-7',
    'CF UAA limits unsuccessful login attempts and enforces account lockout per cloud.gov UAA configuration. Login failures recorded in CF audit log. GSA SecureAuth also enforces lockout after failed authentication attempts.'))

reqs.append(ctrl('ac-8', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov displays warning banners on CF CLI login and dashboard. The cloud.gov platform implements system use notification per its own FedRAMP controls.'),
        (SYS, 'SYSTEM-SPECIFIC: CSB OSBAPI endpoint does not present a browser UI — it is a REST API endpoint called only by cf CLI (authenticated). System use notification is implicitly provided by the cloud.gov UAA consent screen. No additional banner required at the broker layer per FedRAMP SSP guidance for API-only services.')
    ])
]))

reqs.append(inh('ac-11',
    'Cloud.gov platform manages CF session lifecycle. OAuth2 JWT tokens issued by UAA expire per cloud.gov UAA configuration (typically 10 minutes for access tokens, 30 days for refresh tokens). No separate session lock required for API service.'))

reqs.append(inh('ac-11.1',
    'Inherited from cloud.gov UAA. Not applicable at the broker API level (no graphical interface).'))

reqs.append(inh('ac-12',
    'CF UAA issues time-limited OAuth2 tokens. CF CLI automatically re-authenticates when tokens expire. No indefinite sessions at the broker layer.'))

reqs.append(ctrl('ac-14', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'No actions permitted on the TTS Cloud Sandbox SSB without identification and authentication. The OSBAPI endpoint requires HTTP Basic Auth. CF API requires valid JWT OAuth2 token from UAA. No anonymous or unauthenticated access paths exist.')])
]))

reqs.append(ctrl('ac-17', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov provides the remote access infrastructure. CF CLI over HTTPS is the only remote access mechanism. CF SSH disabled in production spaces. VPN not required — cloud.gov uses TLS + MFA for all access.'),
        (SYS, 'SYSTEM-SPECIFIC: Remote access to the SSB is restricted to authenticated CF users (cf login --sso with GSA SecureAuth MFA). No direct SSH to broker app instances. Direct database access via cf connect-to-service requires SpaceDeveloper role AND is tunneled through CF. Remote access policy per SSP §9.4.')
    ])
]))

reqs.append(inh('ac-17.1', 'CF Loggregator and CF CAPI audit log monitor all remote access sessions. TTS ISSO reviews at logs.fr.cloud.gov.'))
reqs.append(inh('ac-17.2', 'TLS 1.2+ enforced by cloud.gov GoRouter/ALB for all remote access connections. Inherited from cloud.gov.'))
reqs.append(inh('ac-17.3', 'CF GoRouter provides single managed access control point for all remote access. No direct app container access from internet. Inherited from cloud.gov.'))

reqs.append(ctrl('ac-17.4', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Privileged CF commands (broker registration, quota management) via remote access require OrgAdmin role. Remote access for privileged functions requires GSA SecureAuth MFA + OrgAdmin scope in UAA token. System Owner and TechOps approve privileged remote access accounts per AC-2.')])
]))

reqs.append(na('ac-18', 'The TTS Cloud Sandbox SSB does not use wireless access. All connectivity is over the internet via HTTPS/TLS to cloud.gov hosted in AWS GovCloud. No organizational wireless network involvement.'))
reqs.append(na('ac-18.1', 'Not applicable — no wireless access. See AC-18.'))
reqs.append(na('ac-19', 'The TTS Cloud Sandbox SSB does not process organizational information on mobile devices. The OSBAPI is a server-side API; no mobile device access paths exist.'))
reqs.append(na('ac-19.5', 'Not applicable — no mobile devices. See AC-19.'))

reqs.append(ctrl('ac-20', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'External systems used by TTS Cloud Sandbox SSB (per SSP §10.2 Table 10-2.1): (1) GitHub.com — source control and CI/CD; GSA uses GitHub Enterprise Cloud (FedRAMP Authorized). (2) AWS (us-east-1), GCP (sandbox project), Azure (sandbox subscription) — CSP APIs for provisioning; accessed with dedicated CSP credentials per CSP FedRAMP boundaries. (3) cloud.gov — leveraged PaaS; FedRAMP P-ATO FR1920000001. All external system usage reviewed in this SSP §10.2 and §11. No unauthorized external systems.')
    ])
]))

reqs.append(ctrl('ac-20.1', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'GitHub.com usage (per SSP §10.7.1): GitHub Actions authorized for CI/CD deployment. GitHub Secrets used for credential injection. GitHub FedRAMP authorization covers this use. CSP API access: credentials scoped to minimum permissions required (see AC-6 and SA-9). Use of external systems documented and reviewed annually per SSP §10.2.')])
]))

reqs.append(na('ac-20.2', 'The TTS Cloud Sandbox SSB does not use portable storage devices as an external system access mechanism.'))

reqs.append(ctrl('ac-21', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Information sharing with external parties is limited to: (1) Service binding credentials returned to authorized CF-app entities via VCAP_SERVICES (controlled by CF RBAC); (2) Security assessment findings shared with GSA OCISO/ISSO via POA&M and SSP. No public sharing of security information. Information sharing decisions require System Owner approval per GSA CIO 2100.1.')])
]))

reqs.append(ctrl('ac-22', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'The TTS Cloud Sandbox SSB does not host publicly accessible content. The OSBAPI endpoint is authenticated. No public-facing web application. The GitHub repository (GSA-TTS/cloud-sandbox) is a public repo but contains only code and non-sensitive documentation — no credentials, no PII, no sensitive configuration.')])
]))

# ══════════════════════════════════════
# AT — Awareness and Training
# ══════════════════════════════════════

reqs.append(corp('at-1',
    'INHERITED (corporate): GSA IT Security Awareness and Training policy per CIO 2100.1 and CIO-IT Security-01-52 (Security Awareness and Training). GSAIT provides agency-wide awareness training. Reviewed and updated per GSA OCISO policy cadence.'))

reqs.append(corp('at-2',
    'INHERITED (corporate): All GSA employees and contractors complete GSA mandatory annual IT security awareness training via GSA OLU (Online Learning University). Training covers phishing, password hygiene, incident reporting, PII handling. TTS staff comply per GSA OCISO mandate.'))

reqs.append(corp('at-2.2',
    'INHERITED (corporate): GSA OCISO conducts phishing simulation tests per CIO-IT Security-01-52. TTS staff participate in GSA-wide phishing simulations. Results tracked by GSA OCISO.'))

reqs.append(sys_ctrl('at-3', [
    ('smt', [
        (POL, 'INHERITED (corporate): GSA provides role-based IT security training via OLU for IT system managers, administrators, and security staff.'),
        (SYS, 'SYSTEM-SPECIFIC: TTS provides CSB-specific role-based training covering: cloud.gov RBAC and CF CLI usage; brokerpak development and security review procedures; CredHub secret management; TTL lifecycle governance; incident reporting for cloud resource anomalies. Training documented in onboarding runbooks at GitHub (GSA-TTS/cloud-sandbox/docs/). New team members must complete onboarding before receiving SpaceDeveloper access.')
    ])
]))

reqs.append(corp('at-4',
    'INHERITED (corporate): GSA OCISO maintains training records in GSA OLU system. TTS ISSO maintains records of CSB-specific role-based training completions in team documentation.'))

# ══════════════════════════════════════
# AU — Audit and Accountability
# ══════════════════════════════════════

reqs.append(sys_ctrl('au-1', [
    ('smt', [(POL, 'INHERITED (corporate): GSA auditing policy per CIO 2100.1 and CIO-IT Security-01-08 (Audit and Accountability). Reviewed annually.'),
             (SYS, 'SYSTEM-SPECIFIC: TTS Cloud Sandbox SSB audit procedures documented in SSP §10.8.5 (Logs and Log Integration) and §10.8.10 (Monitoring and Alerting). Audit log review procedures: ISSO reviews CF audit events and broker logs at logs.fr.cloud.gov weekly; automated Prowler scans generate OSCAL assessment-results.')])
]))

reqs.append(ctrl('au-2', 'implemented', 'hybrid', [
    ('smt', [
        (CAPI, 'INHERITED: CF CAPI generates audit events for all CF platform events: app push, service create/bind/unbind/delete, role changes, login/logout. Events include actor (UAA user UUID), action, target, and RFC3339 timestamp.'),
        (SYS, 'SYSTEM-SPECIFIC: CSB broker application emits structured JSON logs to STDOUT for all OSBAPI operations: provision (service ID, plan ID, parameters, instance ID), deprovision, bind (app GUID, binding ID), unbind. OpenTofu plan/apply/destroy output also logged. All logs captured by CF Loggregator. Auditable events for SSB per SSP §10.8.5: broker authentication attempts, service provision/deprovision, binding/unbinding, TTL extension requests (extend_hours), and errors.')
    ])
]))

reqs.append(ctrl('au-3', 'implemented', 'hybrid', [
    ('smt', [
        (LOG, 'INHERITED: CF Loggregator includes in each log record: component (app name, GUID, instance ID), timestamp (RFC3339 UTC), log type (OUT/ERR), message. CF CAPI audit events include: type, actor, actor_type, actor_name, target, target_type, space_guid, organization_guid, metadata, event_time.'),
        (SYS, 'SYSTEM-SPECIFIC: CSB broker log records include: request method, path, HTTP status, broker-instance-id, service offering, plan, operation type (provision/bind/etc.), duration, and any error messages. All fields per AU-3 requirements: type of event, time, where event occurred, source of event, outcome, identity of subject.')
    ])
]))

reqs.append(inh('au-3.1',
    'CF Loggregator and logs.fr.cloud.gov ELK stack provide centralized audit log management. All broker and platform logs consolidated at logs.fr.cloud.gov. INHERITED from cloud.gov.'))

reqs.append(ctrl('au-4', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov ELK stack at logs.fr.cloud.gov provides audit log storage. cloud.gov manages storage capacity; no per-tenant capacity limit for app logs.'),
        (SYS, 'SYSTEM-SPECIFIC: TTS ensures broker app logging is not excessively verbose to avoid log storage pressure. Log retention: logs.fr.cloud.gov retains logs for 180 days per cloud.gov SLA. OSCAL assessment-results artifacts retained in GitHub (content/ directory) per SA-10 configuration management.')
    ])
]))

reqs.append(inh('au-4.1',
    'cloud.gov manages audit log storage capacity and provides off-load functions. Logs available at logs.fr.cloud.gov. Inherited.'))

reqs.append(ctrl('au-5', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov ELK stack alerts on log pipeline failures. cloud.gov monitors Loggregator health.'),
        (SYS, 'SYSTEM-SPECIFIC: TTS ISSO monitors logs.fr.cloud.gov for log gaps. If broker logs stop appearing, it indicates a broker crash or CF platform issue — investigated as an incident per IR-4. Prowler scan failures alert TTS TechOps via GitHub Actions notification.')
    ])
]))

reqs.append(inh('au-5.1',
    'cloud.gov Loggregator provides alert notification capability on audit log failures. INHERITED from cloud.gov P-ATO.'))

reqs.append(inh('au-5.2',
    'cloud.gov ELK provides real-time audit log availability and capacity monitoring with alerts. INHERITED from cloud.gov P-ATO.'))

reqs.append(ctrl('au-6', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'TTS ISSO reviews CF audit events and broker logs at logs.fr.cloud.gov weekly. Review process: (1) Check CF CAPI audit events for unauthorized role changes, broker deregistrations, or suspicious provision patterns; (2) Review broker STDOUT/STDERR logs for authentication failures, unusual API patterns, or errors; (3) Review Prowler scan results in content/oscal_assessment-results_schema.json; (4) Update POA&M (content/oscal_poam_schema.json) with any new findings. Findings escalated to TTS TechOps and System Owner as appropriate.'),
             (PROWL, 'Prowler continuous assessment scans generate OSCAL-format findings reviewed by ISSO during weekly audit review cycle per CA-7.')
    ])
]))

reqs.append(inh('au-6.1',
    'CF CAPI audit events and Loggregator logs are centralized at logs.fr.cloud.gov with automated search and correlation capabilities. ELK stack provides alerting for pattern detection. INHERITED from cloud.gov.'))

reqs.append(ctrl('au-7', 'implemented', 'hybrid', [
    ('smt', [
        (LOG, 'INHERITED: logs.fr.cloud.gov provides ElasticSearch-based audit reduction and report generation. TTS can query, filter, and export log records.'),
        (SYS, 'SYSTEM-SPECIFIC: TTS uses Kibana at logs.fr.cloud.gov to create saved searches and dashboards for: daily broker operation counts, authentication failures, TTL extensions, and error rates. Dashboards support on-demand reporting for ISSO reviews.')
    ])
]))

reqs.append(inh('au-8',
    'AWS NTP synchronized time maintained by cloud.gov/AWS infrastructure. All log timestamps use UTC RFC3339. INHERITED from cloud.gov FR1920000001.'))

reqs.append(inh('au-8.1',
    'cloud.gov/AWS uses authoritative NTP time sources (Amazon Time Sync Service). Sub-second precision. INHERITED from cloud.gov.'))

reqs.append(ctrl('au-9', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: logs.fr.cloud.gov ELK stack restricts audit log write access to Loggregator system component. TTS Engineers cannot delete or modify audit records. SpaceAuditor role provides read-only access to logs.'),
        (SYS, 'SYSTEM-SPECIFIC: OSCAL assessment-results and POA&M artifacts stored in GitHub (content/ directory) with full git history — providing append-only audit trail of all changes. Access to modify these files requires GitHub authentication + PR review (per CM-3).')
    ])
]))

reqs.append(inh('au-9.2',
    'logs.fr.cloud.gov (cloud.gov ELK) provides backup of audit records. INHERITED.'))
reqs.append(inh('au-9.3',
    'CF Loggregator operates independently from CSB broker applications — audit logs are protected from broker-level compromise. INHERITED from cloud.gov architecture.'))
reqs.append(inh('au-9.4',
    'Access to audit management functions (ELK admin, Loggregator config) restricted to cloud.gov operations team. TTS has read-only access via logs.fr.cloud.gov. INHERITED.'))

reqs.append(ctrl('au-10', 'implemented', 'hybrid', [
    ('smt', [
        (CAPI, 'INHERITED: CF CAPI associates all audit events with authenticated actor UUID (UAA user ID). Actor UUID is unforgeable — derived from GSA SecureAuth SAML assertion. Non-repudiation enforced by CF UAA OAuth2 architecture.'),
        (SYS, 'SYSTEM-SPECIFIC: OSBAPI calls authenticated via HTTP Basic Auth (broker service account). All broker operations tied to a CF app GUID and space GUID logged in the audit trail.')
    ])
]))

reqs.append(ctrl('au-11', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov ELK (logs.fr.cloud.gov) retains logs for 180 days per cloud.gov SLA. Meets FedRAMP minimum retention of 90 days online.'),
        (SYS, 'SYSTEM-SPECIFIC: OSCAL SSP, assessment-results, and POA&M retained in GitHub with full version history (indefinite per GitHub). Git history provides long-term audit trail for system change decisions.')
    ])
]))

reqs.append(ctrl('au-12', 'implemented', 'hybrid', [
    ('smt', [
        (CAPI, 'INHERITED: CF CAPI generates audit records for all auditable events automatically (no configuration required by TTS). Coverage: all CF API calls, including service lifecycle, app deployments, role changes.'),
        (SYS, 'SYSTEM-SPECIFIC: CSB broker application configured to emit structured audit logs to STDOUT for all OSBAPI events (see AU-2). All broker instances log to Loggregator without additional configuration. Audit generation cannot be disabled by TTS Engineers (platform-level enforcement).')
    ])
]))

reqs.append(inh('au-12.1',
    'CF Loggregator compiles audit records from all components across cloud.gov. Central compilation occurs automatically. INHERITED from cloud.gov.'))

reqs.append(inh('au-12.3',
    'cloud.gov platform allows on-demand audit review via logs.fr.cloud.gov Kibana. Log access available to SpaceAuditor role. INHERITED from cloud.gov.'))

reqs.append(inh('au-14',
    'CF Loggregator provides session audit capability for all CF sessions. INHERITED from cloud.gov.'))

reqs.append(inh('au-16',
    'cloud.gov coordinates audit with external parties (FedRAMP PMO, JAB) as part of P-ATO maintenance. INHERITED from cloud.gov for cross-org coordination.'))

# ══════════════════════════════════════
# CA — Security Assessment and Authorization
# ══════════════════════════════════════

reqs.append(sys_ctrl('ca-1', [
    ('smt', [(POL, 'INHERITED (corporate): GSA CA policy per CIO 2100.1 and CIO-IT Security-06-30 (Managing Enterprise Risk). GSA OCISO ISSM oversees A&A process.'),
             (SYS, 'SYSTEM-SPECIFIC: TTS CA procedures: (1) SSP maintained in GitHub (content/oscal_ssp_schema.json) and updated annually or on significant change; (2) Assessment plan in content/oscal_assessment-plan_schema.json; (3) Assessment results from Prowler in content/oscal_assessment-results_schema.json; (4) POA&M in content/oscal_poam_schema.json. Reviews and updates occur with each significant change (brokerpak update, new CSP, architecture change).')])
]))

reqs.append(sys_ctrl('ca-2', [
    ('smt', [
        (PROWL, 'Prowler v3.x continuous assessment scans AWS, GCP, and Azure accounts for FedRAMP Moderate compliance (prowler aws --compliance fedramp_moderate_revision_4). Scans run via GitHub Actions (scheduled). Results exported to OSCAL format in content/oscal_assessment-results_schema.json. HIGH/CRITICAL findings create POA&M items in content/oscal_poam_schema.json.'),
        (SYS, 'Annual third-party assessment (3PAO or GSA OCISO assessors) planned post-ATO. Initial assessment led by TTS ISSO with support from GSA OCISO assessors. Assessment methods: document review, interviews, OSCAL tooling validation, Prowler scan review. Referenced in content/oscal_assessment-plan_schema.json.')
    ])
]))

reqs.append(inh('ca-2.2',
    'Prowler provides specialized assessment capability for CSP resources beyond standard platform assessment. SYSTEM-SPECIFIC component (Prowler) used in CA-2.'))

reqs.append(sys_ctrl('ca-3', [
    ('smt', [(SYS, 'System interconnections per SSP §11 Table 11-1: (1) cloud.gov — leveraged system, FedRAMP P-ATO FR1920000001, authorized via leveraged-authorizations in this SSP; (2) GitHub.com — external SaaS, GSA GitHub Enterprise (FedRAMP Authorized), CI/CD only (outbound HTTPS from GH Actions); (3) AWS us-east-1 — CSP API (outbound HTTPS from CF containers, IAM-authenticated); (4) GCP sandbox project — CSP API (pending, same pattern as AWS); (5) Azure sandbox subscription — CSP API (pending, same pattern). All interconnections documented in system-implementation.components.')])
]))

reqs.append(sys_ctrl('ca-5', [
    ('smt', [(SYS, 'POA&M maintained in content/oscal_poam_schema.json. Items created from: (1) Prowler scan HIGH/CRITICAL findings; (2) CA-7 continuous monitoring findings; (3) Penetration test findings; (4) Self-identified weaknesses during annual SSP review. Each POA&M item includes: control affected, weakness description, risk rating, milestone dates, responsible party. Reviewed monthly by TTS ISSO and System Owner. Tracked in GitHub issues with label prowler-finding or security-finding.')])
]))

reqs.append(sys_ctrl('ca-6', [
    ('smt', [(SYS, 'GSA ATO process per CIO-IT Security-06-30: (1) System Owner prepares SSP; (2) ISSO reviews for completeness; (3) ISSM validates per GSA enterprise risk standards; (4) GSA CISO (AO) grants ATO or conditional ATO. TTS Cloud Sandbox SSB is pursuing GSA Agency ATO. ATO package: this OSCAL SSP + assessment-results + POA&M. Annual review cycle or triggered by significant change.')])
]))

reqs.append(ctrl('ca-7', 'implemented', 'sp-system', [
    ('smt', [
        (PROWL, 'Prowler v3.x scans run via GitHub Actions on weekly schedule targeting all CSP accounts. Results exported to OSCAL assessment-results. HIGH/CRITICAL new findings trigger immediate POA&M update and ISSO notification via GitHub Issue.'),
        (LOG, 'CF Loggregator + logs.fr.cloud.gov provides continuous log monitoring. TTS ISSO reviews weekly. Automated alerts configured in Kibana for: authentication failures >5/hour, broker errors >10% of requests, unusual service provision spikes.'),
        (SYS, 'CA-7 monitoring strategy per SSP §10.8.10: ongoing monitoring of security controls; monthly OSCAL assessment-results review; quarterly access review (AC-2); annual SSP update or significant-change update (CA-6); FedRAMP ConMon reporting when ATO active.')
    ])
]))

reqs.append(inh('ca-7.4',
    'cloud.gov platform continuous monitoring covers platform-level controls. TTS inherits cloud.gov ConMon reporting for inherited controls. INHERITED from FR1920000001.'))

reqs.append(sys_ctrl('ca-8', [
    ('smt', [(SYS, 'Penetration testing planned annually post-ATO using a qualified assessor (3PAO or GSA authorized penetration tester). Scope: OSBAPI endpoint, CF app configuration, brokerpak IAM policies, CSP resource security groups. Pre-engagement rules of engagement filed with GSA OCISO and FedRAMP PMO. Findings enter CA-5 POA&M.')])
]))

reqs.append(sys_ctrl('ca-9', [
    ('smt', [(SYS, 'Internal connections: CSB broker → csb-sql MySQL (CF internal overlay network, port 3306, TLS). csb-sql is a cf-managed service bound to broker via VCAP_SERVICES. No other internal connections. All internal connections documented in system-implementation.components and data-flow narrative (SSP §10.4).')])
]))

# ══════════════════════════════════════
# CM — Configuration Management
# ══════════════════════════════════════

reqs.append(sys_ctrl('cm-1', [
    ('smt', [(POL, 'INHERITED (corporate): GSA CM policy per CIO 2100.1 and CIO-IT Security-01-05 (Configuration Management).'),
             (SYS, 'SYSTEM-SPECIFIC: TTS CM procedures: All broker app configuration stored as code in GitHub (scripts/manifests/, submodules/). Baseline established via IaC (OpenTofu in brokerpaks). Changes via pull request with peer review (CM-3). Broker configuration baseline defined in scripts/manifests/aws-manifest.yml, gcp-manifest.yml, azure-manifest.yml.')])
]))

reqs.append(ctrl('cm-2', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov platform baseline configuration managed by cloud.gov team. Buildpacks, Diego cells, CF CAPI version all managed by cloud.gov under their CM program.'),
        (SYS, 'SYSTEM-SPECIFIC: TTS baseline configurations: (1) scripts/manifests/*.yml — CF app manifests for each broker (memory, instances, buildpack, env var names); (2) submodules/csb-brokerpak-aws/config/*.yml — service plan definitions (sandbox-8h constraints); (3) submodules/csb-brokerpak-aws/terraform/modules/ — OpenTofu module baselines. All baselined in GitHub main branch. Approved deviations documented in CM-6.')
    ])
]))

reqs.append(inh('cm-2.2',
    'cloud.gov platform configuration automation managed by cloud.gov DevOps team using BOSH/CF Release Engineering toolchain. INHERITED.'))

reqs.append(sys_ctrl('cm-3', [
    ('smt', [(SYS, 'CM change control process per SSP §10.7.2 and §10.7.9: (1) Change proposed via GitHub Pull Request (PR) with description, risk assessment, and testing notes; (2) Required review: minimum 1 peer approval from TTS team (GitHub branch protection rule); (3) CI checks: gitleaks secret scan, OpenTofu validate, pre-commit hooks; (4) ISSO notified of security-relevant changes (brokerpak updates, IAM policy changes, manifest changes) via PR label; (5) Changes merged to main trigger automated deployment (pnpm run broker:deploy:*); (6) Post-deployment: cf app <name> confirms health. Rollback: cf push with previous version from git history.'),
             (GH, 'GitHub branch protection on main: require PR reviews, require CI status checks to pass, no direct pushes. Provides immutable change record.')
    ])
]))

reqs.append(inh('cm-3.6',
    'cloud.gov platform provides cryptographic mechanisms for configuration integrity (BOSH signed releases, verified buildpacks). INHERITED.'))

reqs.append(ctrl('cm-4', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Security impact analysis performed for all changes: (1) Brokerpak plan parameter changes reviewed for security constraint drift (max instance size, encryption settings); (2) IAM permission changes in OpenTofu modules reviewed for privilege creep; (3) Dependency updates (go.mod, go.sum) checked against GitHub Dependabot alerts; (4) CF manifest changes reviewed for exposed env vars or removed security settings. Security review checklist in PR template (.github/PULL_REQUEST_TEMPLATE.md).')])
]))

reqs.append(ctrl('cm-5', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov restricts access to CF platform configuration changes (BOSH directors, CF CAPI admin). TTS has no access to cloud.gov infrastructure-level configuration.'),
        (SYS, 'SYSTEM-SPECIFIC: GitHub branch protection restricts who can merge to main. OrgAdmin restriction for broker registration. CF app push requires SpaceDeveloper role scoped to dev space only. Secret management restrictions: CSP credentials accessible only to TechOps and CI/CD service account via GitHub Secrets/CF env.')
    ])
]))

reqs.append(ctrl('cm-6', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov platform configuration settings hardened per cloud.gov CM baseline (CIS benchmarks for CF/BOSH components). TTS inherits all platform-level configuration settings from cloud.gov.'),
        (SYS, 'SYSTEM-SPECIFIC configuration settings: CF manifest: memory=1G, instances=1, no-route=false, health-check-type=http. Brokerpak plan parameters enforce security constraints: db.t3.micro max, no multi-AZ, no versioning (S3), encryption-at-rest enabled (all services), HTTPS-only bucket policy (S3), private ACL. These constraints are enforced in OpenTofu HCL and cannot be overridden by end-user plan parameters.')
    ])
]))

reqs.append(inh('cm-6.2',
    'cloud.gov uses signed/verified CF release artifacts. Buildpack integrity validated by cloud.gov. INHERITED.'))

reqs.append(ctrl('cm-7', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov CF security groups restrict app container network access. Only whitelisted egress allowed (HTTPS port 443 to public internet, MySQL port 3306 to CF-managed services).'),
        (SYS, 'SYSTEM-SPECIFIC: Broker application only exposes: (1) OSBAPI REST API over HTTPS port 443; (2) Health check endpoint (CF-internal). No debug endpoints, no metrics endpoints publicly exposed. Service catalog restricted to approved sandbox-8h plans only (unapproved services return HTTP 503). Unnecessary CF environment variables removed from manifests.')
    ])
]))

reqs.append(inh('cm-7.1',
    'cloud.gov platform enforces application security groups (whitelist-only egress). Periodic reviews of permitted functions/ports by cloud.gov team. INHERITED.'))

reqs.append(inh('cm-7.2',
    'cloud.gov prevents usage of prohibited software via buildpack policies and container isolation. INHERITED.'))

reqs.append(ctrl('cm-7.5', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Software execution allowlist for CSB broker: only the csb binary (compiled Go executable) and OpenTofu provider plugins (in plugin cache directory) are executed at runtime. No external scripts, no shell exec from broker code. OpenTofu plugins downloaded from Terraform Registry over HTTPS and cached in brokerpak bundle at build time. Plugin integrity verified via SHA256 checksums.')])
]))

reqs.append(ctrl('cm-8', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov maintains platform-level hardware and software inventory. TTS does not manage physical hardware.'),
        (SYS, 'SYSTEM-SPECIFIC: SSB software inventory documented in system-implementation.components (this OSCAL SSP): csb-aws v2.6.10, csb-gcp v2.6.10, csb-azure v2.6.10, csb-sql MySQL, cloud.gov leveraged components, GitHub, Prowler v3.x, GSA SecureAuth. Software versions tracked via GitHub dependency lock files (go.sum, pnpm-lock.yaml). CSP-provisioned sandbox resources tagged with TTLExpiry, Project, Owner tags for lifecycle tracking.')
    ])
]))

reqs.append(inh('cm-8.1', 'cloud.gov platform inventory updated automatically by BOSH. INHERITED.'))
reqs.append(inh('cm-8.2', 'cloud.gov automated discovery of platform components. INHERITED.'))

reqs.append(ctrl('cm-8.3', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Prowler scans detect unauthorized CSP resources in the sandbox AWS account (resources without expected TTLExpiry or Owner tags). Findings reported as assessment findings. Any untagged resource is flagged for review. GitHub Dependabot alerts flag unauthorized/vulnerable software dependencies.')])
]))

reqs.append(ctrl('cm-8.4', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Accountability for broker software components: each component in system-implementation.components includes responsible-roles referencing System Owner and Technical POC. GitHub ownership tracked via CODEOWNERS file. CSP resource ownership via Owner tag (required at provision time per brokerpak plan parameters).')])
]))

reqs.append(sys_ctrl('cm-9', [
    ('smt', [(SYS, 'CM plan documented in this SSP, SSP §7 (Operational Status), SSP §10.7 (Application Deployment and Operations), and brokerpak.md (Brokerpak Development Guidelines). CM plan reviewed and updated annually or on significant change. GitHub branch protection and CI/CD pipeline enforce CM plan procedurally.')])
]))

reqs.append(sys_ctrl('cm-10', [
    ('smt', [(SYS, 'Software usage restrictions enforced by: (1) cloud-service-broker binary: Apache 2.0 license, permitted for government use; (2) OpenTofu providers: MPL 2.0 license, permitted; (3) Go dependencies tracked in go.sum with license review (pnpm run audit); (4) No proprietary software without ISSO/System Owner review. All software components documented in SSP CM-8 inventory.')])
]))

reqs.append(sys_ctrl('cm-11', [
    ('smt', [(SYS, 'User-installed software policy: TTS Engineers cannot install software on CF app containers directly (containers are ephemeral, rebuilt on each cf push). All broker dependencies are bundled in the Go binary at build time (go build). No user-installed runtime software is possible on the platform. CI/CD pipeline is the only authorized mechanism for software updates.')])
]))

reqs.append(sys_ctrl('cm-13', [
    ('smt', [(SYS, 'Data location: broker state database (csb-sql) in AWS GovCloud us-gov-west-1 (cloud.gov RDS MySQL). Sandbox CSP resources in: AWS us-east-1 (configured), GCP sandbox project (planned), Azure sandbox subscription (planned). Data locations documented in SSP §9.1 (locations) and system-implementation.components. No data stored outside cloud.gov or designated CSP regions without ISSO approval.')])
]))

# ══════════════════════════════════════
# CP — Contingency Planning
# ══════════════════════════════════════

reqs.append(sys_ctrl('cp-1', [
    ('smt', [(POL, 'INHERITED (corporate): GSA CP policy per CIO 2100.1 and CIO-IT Security-06-29 (Contingency Planning).'),
             (SYS, 'SYSTEM-SPECIFIC: TTS CP procedures for the Cloud Sandbox SSB: broker app can be redeployed in <30 minutes via pnpm run broker:deploy:aws from main branch. csb-sql restored from cloud.gov automated daily backup. Sandbox service instances are short-lived (TTL max 12h) — no complex recovery required for provisioned resources.')])
]))

reqs.append(ctrl('cp-2', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'TTS contingency plan (informal, per scale of the system): (1) Broker app unavailable: redeploy via pnpm run broker:deploy:aws (GitHub Actions or manual); (2) csb-sql unavailable: restore from cloud.gov daily backup (managed by cloud.gov as part of aws-rds service); (3) cloud.gov unavailable: broker is down — sandbox service instances continue running independently at CSP; (4) CSP API unavailable: broker operations fail gracefully (OpenTofu returns error); (5) GitHub unavailable: deploy from local clone. RTO: 30 min for broker. RPO: 24 hours for state DB (daily backup). Availability impact is Low (see FIPS 199 impact).')])
]))

reqs.append(inh('cp-2.1', 'cloud.gov conducts contingency plan reviews for platform components. TTS reviews SSB-specific CP annually. INHERITED platform CP.'))
reqs.append(inh('cp-2.2', 'cloud.gov capacity planning and platform-level CP exercises. Inherited.'))
reqs.append(inh('cp-2.3', 'cloud.gov CP plan includes DR scenarios. TTS CP plan reviewed with annual SSP review. Inherited.'))
reqs.append(inh('cp-2.4', 'cloud.gov resilience architecture (multi-AZ). Inherited.'))
reqs.append(inh('cp-2.5', 'cloud.gov CP plan coordination with all stakeholders. Inherited.'))

reqs.append(corp('cp-3',
    'INHERITED (corporate): GSA contingency training per GSA OCISO mandate. TTS staff complete GSA OLU contingency training.'))

reqs.append(sys_ctrl('cp-4', [
    ('smt', [(SYS, 'CP test: TTS conducts annual deployment rehearsal (tabletop exercise): simulate broker unavailability → redeploy via pnpm run broker:deploy:aws → verify cf marketplace shows sandbox plans. Test results documented in assessment-results. First full test planned within 6 months of ATO. Broker destruction/reconstruction test is low-risk given IaC-based deployment approach.')])
]))

reqs.append(inh('cp-6',
    'cloud.gov multi-AZ deployment in AWS GovCloud us-gov-west-1 provides alternate processing site capability. csb-sql RDS is Multi-AZ within cloud.gov managed boundary. INHERITED from cloud.gov PR1920000001. Note: TTS sandbox-8h plan parameters do NOT enable Multi-AZ for customer-provisioned RDS instances (sandbox tier) — this is controlled exclusively at the broker platform level.'))

reqs.append(inh('cp-6.1',
    'cloud.gov provides automatic failover to alternate availability zone. INHERITED from cloud.gov.'))

reqs.append(inh('cp-7',
    'cloud.gov alternate processing site capability via multi-AZ/multi-region. INHERITED from cloud.gov.'))

reqs.append(inh('cp-7.1',
    'cloud.gov alternate processing site accessible within RTO per cloud.gov SLA. INHERITED.'))

reqs.append(inh('cp-8',
    'cloud.gov provides telecom service redundancy. INHERITED from cloud.gov.'))

reqs.append(ctrl('cp-9', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov performs automated daily backups of the csb-sql MySQL RDS instance as part of the aws-rds service management. Backups retained per aws-rds plan parameters.'),
        (SYS, 'SYSTEM-SPECIFIC: Broker application is stateless (all state in csb-sql). GitHub repo provides version-controlled backup of all configuration, manifests, and brokerpak code. IaC (OpenTofu) allows full environment recreation from code. OSCAL artifacts backed up in GitHub.')
    ])
]))

reqs.append(inh('cp-9.1',
    'cloud.gov performs regular testing of backup restoration for managed services (aws-rds). INHERITED.'))

reqs.append(inh('cp-9.3',
    'cloud.gov stores backup copies in geographically separate locations (AWS GovCloud multi-region). INHERITED.'))

reqs.append(sys_ctrl('cp-10', [
    ('smt', [(SYS, 'TTL lifecycle provides automatic system recovery: at TTL expiry, OpenTofu destroy cleanly deprovisions all resources in a known state. For broker app failure: restart via cf restart csb-aws (automatic) or cf push (manual). csb-sql point-in-time recovery: cloud.gov provides PITR for RDS instances. Full environment rebuild from IaC possible within 30 minutes per CP-2.')])
]))

# ══════════════════════════════════════
# IA — Identification and Authentication
# ══════════════════════════════════════

reqs.append(sys_ctrl('ia-1', [
    ('smt', [(POL, 'INHERITED (corporate): GSA IA policy per CIO 2100.1 and CIO-IT Security-01-01 (Identification and Authentication).'),
             (SYS, 'SYSTEM-SPECIFIC: TTS IA procedures per SSP §9.4: cf login --sso for all user access; HTTP Basic Auth for OSBAPI service broker endpoint; CF service credentials (VCAP_SERVICES) for app-to-service authentication. Reviewed annually with SSP.')])
]))

reqs.append(ctrl('ia-2', 'implemented', 'hybrid', [
    ('smt', [
        (UAA, 'INHERITED: CF UAA provides MFA authentication infrastructure. All cf CLI access requires OAuth2 JWT from UAA via SAML 2.0 federation to GSA SecureAuth.'),
        (SAUTH, 'INHERITED (corporate): GSA SecureAuth enforces GSA enterprise MFA: ENT Domain ID + 2FA method (email/phone/TOTP/PIV-CAC) + password. SecureAuth SAML assertion signed with GSA IdP private key.'),
        (SYS, 'SYSTEM-SPECIFIC: All user access to the SSB requires GSA SecureAuth MFA (IA-2 Moderate baseline met). No service-account access via username/password for human users. OSBAPI endpoint uses HTTP Basic Auth (service-to-service, not human user) — protected by CF HTTPS/TLS and scoped SECURITY_USER_NAME/PASSWORD per SSP §10.7.7.')
    ])
]))

reqs.append(inh('ia-2.1', 'GSA SecureAuth MFA enforced for all privileged account access to CF. INHERITED from cloud.gov UAA + GSA SecureAuth.'))
reqs.append(inh('ia-2.2', 'GSA SecureAuth MFA enforced for non-privileged network access. All cf CLI access requires MFA. INHERITED.'))
reqs.append(inh('ia-2.8', 'GSA SecureAuth replay-resistant authentication via SAML signed assertions with one-time use nonce. INHERITED.'))
reqs.append(inh('ia-2.12', 'GSA SecureAuth supports PIV/CAC for IA-2(12) PIV authentication. GSA issues PIV to applicable personnel. INHERITED from GSA enterprise IdP.'))
reqs.append(inh('ia-3', 'cloud.gov manages platform-level device identification. CF app container identity governed by cloud.gov. INHERITED.'))

reqs.append(ctrl('ia-4', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: CF UAA manages user identity lifecycle. User accounts (CF accounts) provisioned via cf create-user or SAML assertion from GSA SecureAuth.'),
        (SYS, 'SYSTEM-SPECIFIC: TTS manages CF org membership: SpaceDeveloper accounts provisioned by TechOps upon System Owner approval per AC-2. Identifier re-use prohibited — CF user UUIDs are unique forever. Departed users removed within 2 hours of departure notification.')
    ])
]))

reqs.append(inh('ia-4.4', 'CF UAA individual account identifiers include user type information. INHERITED.'))

reqs.append(ctrl('ia-5', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov UAA manages CF user credential lifecycle. GSA SecureAuth manages enterprise credential policy (password complexity, change intervals, history). Cloud.gov manages csb-sql service credential generation (host, port, user, password injected via VCAP_SERVICES).'),
        (SYS, 'SYSTEM-SPECIFIC: (1) OSBAPI credential (SECURITY_USER_NAME/PASSWORD): minimum 32-char randomly generated password, stored as CF env var, rotated on demand or quarterly. (2) CSP IAM credentials (AWS_ACCESS_KEY_ID, SECURITY_USER_PASSWORD, ARM_CLIENT_SECRET, GOOGLE_CREDENTIALS): stored in scripts/envs/*.env (git-ignored), injected at deploy time, rotated per CSP key rotation policy (90 days) or on team membership change. (3) VCAP_SERVICES service credentials: generated by cloud.gov services at bind time, auto-rotated at unbind/rebind.')
    ])
]))

reqs.append(inh('ia-5.1', 'GSA SecureAuth enforces password policy (complexity, history, expiration) for GSA ENT domain credentials. INHERITED from GSA corporate IdP.'))

reqs.append(ctrl('ia-5.2', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'PKI-based authentication: TLS certificates for broker endpoints managed by cloud.gov (Let\'s Encrypt, auto-rotated). No client certificate authentication in use (CF UAA OAuth2 used instead). FIPS 140-2 TLS stack used by cloud.gov GoRouter. Certificate validation enforced on all HTTPS connections.')])
]))

reqs.append(inh('ia-5.4', 'GSA SecureAuth enforces authenticator minimum security requirements per GSA CIO-IT Security policy. INHERITED.'))
reqs.append(inh('ia-5.6', 'cloud.gov and GSA SecureAuth protect authenticators from unauthorized disclosure. INHERITED.'))
reqs.append(inh('ia-5.7', 'GSA policy prohibits unencrypted static authenticators. INHERITED (corporate).'))

reqs.append(ctrl('ia-5.13', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Broker service credentials (SECURITY_USER_NAME/PASSWORD) are single-purpose: only used for OSBAPI broker endpoint authentication. Not reused across systems. CSP IAM credentials are scoped to minimum sandbox permissions per AC-6. No password reuse across credential types.')])
]))

reqs.append(inh('ia-6', 'CF UAA and GSA SecureAuth mask credential input in login flows. INHERITED.'))
reqs.append(inh('ia-7', 'cloud.gov uses FIPS 140-2 validated cryptographic modules for authentication. INHERITED.'))

reqs.append(ctrl('ia-8', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov UAA can federate non-organizational users via SAML if configured. For this system, only GSA organizational accounts are permitted.'),
        (SYS, 'SYSTEM-SPECIFIC: The TTS Cloud Sandbox SSB does not permit non-organizational user access. All users must have a valid GSA ENT Domain account authenticated via GSA SecureAuth. No public access, no anonymous access, no federal-partner federation configured.')
    ])
]))

reqs.append(inh('ia-8.1', 'cloud.gov UAA supports Identity Assurance Level validation via SAML IdP configuration. INHERITED.'))
reqs.append(inh('ia-8.2', 'GSA SecureAuth provides Identity Assurance Level 2 per NIST SP 800-63B. INHERITED.'))
reqs.append(inh('ia-8.4', 'cloud.gov UAA NIST 800-63 compliant. INHERITED.'))
reqs.append(inh('ia-11', 'CF UAA OAuth2 token expiration provides re-authentication. INHERITED from cloud.gov.'))
reqs.append(inh('ia-12', 'GSA SecureAuth performs identity proofing for GSA ENT Domain accounts at IAL2. INHERITED (corporate).'))

# ══════════════════════════════════════
# IR — Incident Response
# ══════════════════════════════════════

reqs.append(corp('ir-1',
    'INHERITED (corporate): GSA IR policy per CIO 2100.1 and CIO-IT Security-01-02 (Incident Response). GSA OCISO coordinates enterprise incident response. TTS Cloud Sandbox SSB follows GSA IR procedures.'))

reqs.append(corp('ir-2',
    'INHERITED (corporate): TTS staff complete GSA OLU IR training. Supplemented by SSB-specific incident response runbook (documented in SSP §10.8 and GitHub runbooks).'))

reqs.append(sys_ctrl('ir-3', [
    ('smt', [(SYS, 'IR tests: TTS conducts annual tabletop IR exercise simulating a sandbox resource breach scenario (inadvertent public S3 bucket or leaked credential). Exercise covers detection (Prowler alert / CA-7), containment (cf delete-service + revoke CSP credential), eradication, recovery. Results documented in assessment-results.')])
]))

reqs.append(ctrl('ir-4', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Incident handling per GSA CIO-IT Security-01-02: (1) Preparation: runbooks available in GitHub; (2) Detection: Prowler alerts, Kibana dashboards, CF app crash notifications; (3) Containment: cf delete-service <name> -f (TTL controller or manual); cf stop csb-aws; revoke CSP IAM key; (4) Eradication: Prowler re-scan to confirm resource removal; reset broker credentials; (5) Recovery: pnpm run broker:deploy:aws; verify marketplace; (6) Post-incident: update POA&M (ca-5), update SSP if significant change. Report to GSA OCISO within 1 hour for HIGH/CRITICAL incidents per CIO-IT Security-01-02.'),
             (PROWL, 'Prowler provides automated detection of cloud resource misconfigurations as incident precursors.')
    ])
]))

reqs.append(inh('ir-4.1', 'CF Loggregator and Kibana alerting provide automated incident detection support. INHERITED from cloud.gov.'))

reqs.append(sys_ctrl('ir-5', [
    ('smt', [(SYS, 'Incident tracking in GitHub Issues (label: security-incident). Incidents reported to GSA OCISO US-CERT per CIO-IT Security-01-02 timeline. POA&M updated for incidents requiring remediation. Annual incident summary included in ConMon report.')])
]))

reqs.append(sys_ctrl('ir-6', [
    ('smt', [(SYS, 'Security incidents reported to: (1) TTS TechOps immediately; (2) System Owner within 1 hour; (3) GSA OCISO and US-CERT within 1 hour per CIO-IT Security-01-02 for HIGH/CRITICAL; (4) FedRAMP PMO within 1 hour for HIGH/CRITICAL incidents as required by FedRAMP IR reporting requirements.')])
]))

reqs.append(inh('ir-6.1', 'cloud.gov provides automated incident reporting tooling at platform level. INHERITED.'))

reqs.append(ctrl('ir-7', 'implemented', 'hybrid', [
    ('smt', [
        (POL, 'INHERITED (corporate): GSA OCISO provides IR assistance and coordination. GSA US-CERT reporting channel.'),
        (SYS, 'SYSTEM-SPECIFIC: TTS IR support: cloud.gov support channel at https://cloudgov.slack.com #cg-support for CF-layer incidents. AWS support for CSP-layer issues. GSA TTS Slack #tts-security for team coordination.')
    ])
]))

reqs.append(sys_ctrl('ir-8', [
    ('smt', [(SYS, 'IR plan documented in SSP §10.8 (Monitoring and Security) and supplementary incident response runbook in GitHub (docs/incident-response-runbook.md — to be created per CA-5 POA&M). IR plan references GSA CIO-IT Security-01-02. IR plan reviewed annually with SSP. Distribution: System Owner, ISSO, TechOps.')])
]))

# ══════════════════════════════════════
# MA — Maintenance (mostly inherited)
# ══════════════════════════════════════

reqs.append(inh('ma-1', 'INHERITED (corporate+cloud.gov): GSA maintenance policy per CIO 2100.1. cloud.gov performs all platform maintenance. No TTS-direct hardware maintenance.'))
reqs.append(inh('ma-2', 'cloud.gov performs controlled maintenance on CF platform components per change management/BOSH upgrade procedures. TTS has no hardware/platform maintenance responsibilities.'))
reqs.append(inh('ma-3', 'cloud.gov controls all maintenance tools for platform. INHERITED.'))
reqs.append(inh('ma-3.1', 'cloud.gov inspects maintenance tools for improper modifications. INHERITED.'))
reqs.append(inh('ma-3.2', 'cloud.gov manages maintenance tool media sanitization. INHERITED.'))
reqs.append(inh('ma-3.3', 'cloud.gov prohibits use of unauthorized maintenance tool components. INHERITED.'))
reqs.append(inh('ma-4', 'cloud.gov manages nonlocal maintenance (remote AWS infrastructure access). TTS performs app maintenance via cf push (authenticated CF CLI). INHERITED platform maintenance.'))
reqs.append(inh('ma-4.3', 'cloud.gov uses strong authenticators for nonlocal maintenance. INHERITED.'))
reqs.append(inh('ma-5', 'cloud.gov controls maintenance personnel access to platform. No physical access required for TTS SSB operations. INHERITED.'))
reqs.append(inh('ma-6', 'cloud.gov provides timely maintenance of platform components per SLA. TTS provides timely app maintenance via automated CI/CD on security finding resolution per POA&M. INHERITED platform maintenance.'))

# ══════════════════════════════════════
# MP — Media Protection (mostly inherited)
# ══════════════════════════════════════

reqs.append(inh('mp-1', 'INHERITED (corporate+cloud.gov): GSA MP policy per CIO 2100.1. cloud.gov/AWS handles all physical media protection.'))
reqs.append(inh('mp-2', 'cloud.gov/AWS restricts access to system media (SSD/HDD in AWS data centers). No TTS-managed physical media.'))
reqs.append(inh('mp-3', 'cloud.gov/AWS marks and labels media per AWS procedures. INHERITED.'))
reqs.append(inh('mp-4', 'cloud.gov/AWS controls physical media storage per AWS FedRAMP controls. INHERITED.'))
reqs.append(inh('mp-5', 'cloud.gov/AWS controls media transport. INHERITED.'))
reqs.append(inh('mp-6', 'cloud.gov/AWS performs media sanitization per NIST 800-88 for decommissioned hardware. INHERITED.'))
reqs.append(inh('mp-6.1', 'cloud.gov/AWS reviews, approves, tracks, and documents media sanitization activity. INHERITED.'))
reqs.append(inh('mp-7', 'cloud.gov/AWS restricts use of portable storage devices on platform infrastructure. INHERITED.'))

# ══════════════════════════════════════
# PE — Physical and Environmental Protection (all inherited)
# ══════════════════════════════════════

for pe_ctrl in ['pe-1','pe-2','pe-3','pe-4','pe-5','pe-6','pe-8','pe-9','pe-10',
                'pe-11','pe-12','pe-13','pe-14','pe-15','pe-16','pe-17','pe-18','pe-19']:
    reqs.append(inh(pe_ctrl,
        f'All physical and environmental protection controls ({pe_ctrl.upper()}) are FULLY INHERITED from cloud.gov '
        'FR1920000001. cloud.gov runs in AWS GovCloud data centers (us-gov-west-1, Hillsboro OR). '
        'AWS manages physical access controls, environmental controls, power, HVAC, fire suppression, '
        'and physical media protection per AWS FedRAMP High authorization. '
        'TTS has no physical infrastructure. No TTS staff have physical access to data center.'))

# ══════════════════════════════════════
# PL — Planning
# ══════════════════════════════════════

reqs.append(sys_ctrl('pl-1', [
    ('smt', [(POL, 'INHERITED (corporate): GSA PL policy per CIO 2100.1.'),
             (SYS, 'SYSTEM-SPECIFIC: TTS planning procedures for SSB: SSP maintained in GitHub as OSCAL JSON (content/oscal_ssp_schema.json); assessment plan in content/oscal_assessment-plan_schema.json. SSP reviewed annually or on significant change.')])
]))

reqs.append(sys_ctrl('pl-2', [
    ('smt', [(SYS, 'This SSP serves as the TTS Cloud Sandbox SSB system security plan. Components: this OSCAL document (oscal_ssp_schema.json), architecture diagrams (docs/architecture-diagrams.md), brokerpak development guidelines (brokerpak.md), and referenced GSA policy documents. SSP developed per FedRAMP SSP template guidance and NIST SP 800-18. Reviewed and updated annually; immediately upon significant architectural change.')])
]))

reqs.append(sys_ctrl('pl-4', [
    ('smt', [(POL, 'INHERITED (corporate): GSA Rules of Behavior per GSA IT security policy and employee onboarding. All GSA employees sign Rules of Behavior.'),
             (SYS, 'SYSTEM-SPECIFIC: TTS cloud sandbox rules of behavior documented in README.md and brokerpak.md: budget ceiling ($500/month), TTL policy (8h max + 4h renewal), approved services only, no production data in sandboxes, no multi-AZ/HA configurations, required resource tags mandatory. Enforced via broker plan parameters and TTL controller; also communicated in team onboarding.')])
]))

reqs.append(inh('pl-4.1', 'GSA Rules of Behavior provided electronically via GSA onboarding. Digital signature via GSA IT systems. INHERITED (corporate).'))

reqs.append(sys_ctrl('pl-8', [
    ('smt', [(SYS, 'Security and privacy architecture documented in: this SSP (system-characteristics.authorization-boundary, network-architecture, data-flow), docs/architecture-diagrams.md (12 Mermaid C4/sequence diagrams), and content/oscal_component_schema.json (component definitions with control implementations). Architecture reviewed with each significant change.')])
]))

reqs.append(sys_ctrl('pl-9', [
    ('smt', [(SYS, 'Central management of security controls achieved via: (1) OSCAL artifacts in GitHub for compliance documentation; (2) IaC (OpenTofu brokerpaks) for infrastructure control enforcement; (3) pnpm scripts for operational consistency; (4) GitHub Actions CI/CD for automated deployment control.')])
]))

reqs.append(sys_ctrl('pl-10', [
    ('smt', [(SYS, 'Baseline selection: FedRAMP Moderate baseline per FIPS 199 categorization (C=M, I=M, A=L → overall Moderate per high-water mark). Controls selected per FedRAMP Moderate Rev 5 profile. Tailoring decisions documented in this SSP with justifications per control.')])
]))

reqs.append(sys_ctrl('pl-11', [
    ('smt', [(SYS, 'Baseline tailoring: cloud.gov inheritance accounts for ~60% of PE, MA, MP, CP controls (fully inherited). Privacy tailoring (PT family): no PII collected (AP-1 determination) → privacy overlay minimized. Compensating controls: none required. Control tailoring documented per control in this SSP.')])
]))

# ══════════════════════════════════════
# PM — Program Management
# ══════════════════════════════════════

for pm_ctrl_id in ['pm-1','pm-2','pm-3','pm-4','pm-5','pm-6','pm-7','pm-8','pm-9',
                   'pm-10','pm-11','pm-12','pm-13','pm-14','pm-15','pm-16']:
    reqs.append(corp(pm_ctrl_id,
        f'INHERITED (corporate): GSA enterprise Information Security Program Management ({pm_ctrl_id.upper()}) '
        'managed by GSA OCISO per FISMA, OMB A-130, and GSA IT Security Policy CIO 2100.1. '
        'TTS Cloud Sandbox SSB participates in GSA enterprise program management activities.'))

# ══════════════════════════════════════
# PS — Personnel Security
# ══════════════════════════════════════

reqs.append(corp('ps-1', 'INHERITED (corporate): GSA PS policy per CIO 2100.1 and GSA HR policy.'))

reqs.append(sys_ctrl('ps-2', [
    ('smt', [(POL, 'INHERITED (corporate): GSA assigns position sensitivity designations. GSA HR performs risk designations for all positions per OPM guidelines.'),
             (SYS, 'SYSTEM-SPECIFIC per SSP §9.4 Table 9-4: TTS TechOps/OrgAdmin = High Risk (PS-2 High Risk, privileged system access); TTS Engineer/SpaceDeveloper = Moderate Risk (PS-2 Moderate, IT management); ISSO = Moderate Risk (IT management, read-only); CI/CD SA = High Risk (automated privileged access). Position sensitivity review upon role changes.')])
]))

for ps_ctrl_id in ['ps-3','ps-4','ps-5','ps-6','ps-7','ps-8','ps-9']:
    reqs.append(corp(ps_ctrl_id,
        f'INHERITED (corporate): GSA personnel security procedures ({ps_ctrl_id.upper()}) managed by GSA HR and GSA OCISO per GSA IT Security Policy and OPM requirements.'))

# ══════════════════════════════════════
# RA — Risk Assessment
# ══════════════════════════════════════

reqs.append(sys_ctrl('ra-1', [
    ('smt', [(POL, 'INHERITED (corporate): GSA RA policy per CIO 2100.1 and CIO-IT Security-06-30 (Managing Enterprise Risk).'),
             (SYS, 'SYSTEM-SPECIFIC: TTS RA procedures: Prowler scans (automated), annual formal risk assessment coordinated with ISSO, risk findings entered into POA&M (ca-5). Risk decisions communicated to System Owner for acceptance or remediation.')])
]))

reqs.append(sys_ctrl('ra-2', [
    ('smt', [(SYS, 'FIPS 199 categorization decisions documented in system-information.information-types (3 types) and security-impact-level (C=M, I=M, A=L, overall Moderate). Categorization rationale: Moderate for C (service credentials in transit/state DB), Moderate for I (OpenTofu state integrity), Low for A (developer convenience tool, not mission-critical). Reviewed annually and on significant information type change.')])
]))

reqs.append(sys_ctrl('ra-3', [
    ('smt', [(SYS, 'Risk assessment performed during: (1) Initial SSP development (this document); (2) Annual review; (3) On significant change (new CSP, new service type, brokerpak major version). Risk assessment method: threat modeling based on OWASP Top 10 for OSBAPI broker; CWE analysis for Go broker code; CSP IAM privilege analysis. Risk findings in ca-5 POA&M.'),
             (PROWL, 'Prowler augments RA-3 with automated CSP-level risk identification.')
    ])
]))

reqs.append(inh('ra-3.1', 'cloud.gov performs supply chain risk assessment. TTS does supply chain risk for brokerpak dependencies (go.sum hash verification). Shared responsibility.'))

reqs.append(ctrl('ra-5', 'implemented', 'sp-system', [
    ('smt', [
        (PROWL, 'Prowler v3.x performs automated vulnerability scanning of CSP infrastructure (AWS accounts, GCP project, Azure subscription) for known misconfigurations and CIS benchmark violations. Scan schedule: weekly via GitHub Actions cron. Findings: HIGH/CRITICAL → immediate POA&M entry + ISSO notification; MEDIUM → monthly POA&M review; LOW/INFO → annual review. Commands: pnpm run prowler:scan:aws|gcp|azure.'),
        (SYS, 'Go dependency vulnerability scanning: GitHub Dependabot monitors go.mod dependencies for CVEs. Critical CVEs addressed within 30 days per GSA vulnerability management policy. Pre-commit gitleaks hook prevents secret leakage (SA-11).')
    ])
]))

reqs.append(inh('ra-5.2', 'cloud.gov performs platform-level vulnerability scans for CF/BOSH/OS components. INHERITED.'))
reqs.append(inh('ra-5.4', 'cloud.gov identifies privileged access vulnerabilities at platform level. INHERITED.'))
reqs.append(inh('ra-5.5', 'cloud.gov provides scan access via privileged access for platform scanning. INHERITED.'))

reqs.append(sys_ctrl('ra-7', [
    ('smt', [(SYS, 'Risk responses documented in POA&M (content/oscal_poam_schema.json). Each Prowler/RA-5 finding receives a risk response decision: accept (with justification), mitigate (with timeline), or transfer. Risk acceptance requires System Owner + ISSO sign-off. Unacceptable risks without remediation path escalated to AO.')])
]))

reqs.append(sys_ctrl('ra-9', [
    ('smt', [(SYS, 'Critical system components: (1) csb-sql MySQL backing database — single point of state; mitigated by cloud.gov automated daily backup; (2) GSA SecureAuth / CF UAA — single MFA path; mitigated by cloud.gov high-availability UAA cluster; (3) OSBAPI endpoint — broker app; mitigated by CF restart policy and IaC rapid redeploy (<30 min). Criticality analysis reviewed annually.')])
]))

# ══════════════════════════════════════
# SA — System and Services Acquisition
# ══════════════════════════════════════

reqs.append(sys_ctrl('sa-1', [
    ('smt', [(POL, 'INHERITED (corporate): GSA SA policy per CIO 2100.1 and Federal Acquisition Regulation (FAR) security requirements.'),
             (SYS, 'SYSTEM-SPECIFIC: TTS acquisition procedures for SSB: new brokerpak integrations require security review per CM-3/CM-4 before inclusion in approved service catalog; CSP accounts procured via GSA Office of Digital Infrastructure; open-source components reviewed per CM-10.')])
]))

reqs.append(corp('sa-2', 'INHERITED (corporate): GSA IT capital planning and investment control process (CPIC) managed by GSA OCIO. TTS Cloud Sandbox SSB included in GSA IT investment portfolio. Budget ceiling $500/month per sandbox org enforced by TTL controller and CF quota.'))

reqs.append(sys_ctrl('sa-3', [
    ('smt', [(SYS, 'SDLC per SSP §10.7: Development in GitHub (feature branches → PR review → merge to main). Continuous integration: pre-commit hooks (gitleaks), OpenTofu validate. Deployment: pnpm run broker:deploy:* via GitHub Actions. Security activities integrated at: code review (CM-3), dependency scanning (Dependabot, RA-5), secret scanning (gitleaks, CM-4), IaC security review (brokerpak plan parameter review). Security reviewed at: new brokerpak version, new service addition, new CSP integration.')])
]))

reqs.append(sys_ctrl('sa-4', [
    ('smt', [(SYS, 'Acquisition requirements for SSB components: cloud-service-broker (open source, forked): security requirements per cloud.gov and GSA OCISO review; cloud.gov (leveraged system): FedRAMP P-ATO terms per leveraged authorization agreement; CSP services: AWS/GCP/Azure FedRAMP authorizations verified before brokerpak integration; GitHub Enterprise: GSA enterprise agreement covers FedRAMP authorization.')])
]))

reqs.append(inh('sa-4.1', 'cloud.gov functional properties documentation available via cloud.gov technical docs and FedRAMP P-ATO package. INHERITED.'))
reqs.append(inh('sa-4.2', 'cloud.gov design/implementation documents available via FedRAMP package. INHERITED.'))

reqs.append(sys_ctrl('sa-4.9', [
    ('smt', [(SYS, 'CSP services used by SSB (AWS RDS, S3, ElastiCache, SQS; GCP Cloud SQL/Storage/Pub-Sub/Redis; Azure PostgreSQL/SQL/Redis/Storage/Event Hubs) procured/configured to restrict operation to US government authorized FedRAMP boundaries: AWS GovCloud us-gov-west-1 for cloud.gov, AWS us-east-1 for sandbox resources. CSP accounts are GSA-owned, TTS-administered.')])
]))

reqs.append(inh('sa-4.10', 'cloud.gov FIPS 140-2 validated cryptographic modules used in platform. INHERITED.'))

reqs.append(sys_ctrl('sa-5', [
    ('smt', [(SYS, 'System documentation maintained in GitHub: README.md (system overview), brokerpak.md (brokerpak development guidelines), docs/ (architecture diagrams, SSP reference), scripts/ (operational procedures), OSCAL content (content/). Admin documentation: scripts/envs/*.env.example shows required configuration. Operational documentation reviewed and updated with each significant change.')])
]))

reqs.append(sys_ctrl('sa-8', [
    ('smt', [(SYS, 'Security engineering principles applied per SSP §10.7.2 (IAC Implementation) and §10.7.7 (Secret and Key Management): (1) Least privilege in CSP IAM policies (per AC-6); (2) Immutable infrastructure — no manual changes to running containers; (3) Defense in depth — CF security groups + CSP security groups + encryption at rest/transit; (4) Fail secure — OpenTofu apply failure leaves no partial state; (5) Separation of duties — Engineer vs. Admin vs. ISSO roles (AC-5); (6) Open design — brokerpak code in public GitHub, reviewed by community; (7) Complete mediation — all access via CF API + OSBAPI, no back-doors.')])
]))

reqs.append(ctrl('sa-9', 'implemented', 'sp-system', [
    ('smt', [
        (SYS, 'External services inventory per SSP §10.2 Table 10-2.1: (1) cloud.gov PaaS — FedRAMP Moderate P-ATO FR1920000001; (2) GitHub.com — GSA GitHub Enterprise, FedRAMP Authorized; (3) AWS us-east-1 — CSP, FedRAMP High (sandbox resources only, outside authorization boundary); (4) GCP — pending, sandbox project; (5) Azure — pending, sandbox subscription. All external services reviewed for FedRAMP authorization before use. Non-FedRAMP services require AO approval.'),
        (AWS_BE, 'AWS services consumed: RDS (PostgreSQL/MySQL), ElastiCache Redis, S3, SQS. All in us-east-1, within AWS FedRAMP authorization. TTS holds no CSP-level FedRAMP authorization — inheriting from CSP FedRAMP boundaries per system boundary definition.')
    ])
]))

reqs.append(inh('sa-9.1', 'cloud.gov policies govern external service use at the PaaS level. INHERITED.'))
reqs.append(inh('sa-9.2', 'cloud.gov authorizes external provider services per P-ATO terms. INHERITED.'))

reqs.append(sys_ctrl('sa-9.5', [
    ('smt', [(SYS, 'Processing, storage, and service location restricted to U.S. government FedRAMP regions: cloud.gov → AWS GovCloud us-gov-west-1 (Oregon); sandbox resources → AWS us-east-1 (Virginia); GCP/Azure pending — will be restricted to FedRAMP-authorized US regions. No offshore processing permitted per GSA policy.')])
]))

reqs.append(ctrl('sa-10', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Developer configuration management per SSP §10.7.2 and §10.7.9: (1) All code in GitHub (version controlled); (2) No manual changes to running containers (immutable infrastructure); (3) Configuration changes via PR + CI + cf push pipeline; (4) Security flaws tracked in GitHub Issues + POA&M; (5) OpenTofu state in csb-sql tracks all infrastructure configurations; (6) Dependency versions locked in go.sum and pnpm-lock.yaml.'),
             (GH, 'GitHub provides developer CM platform: branch protection, required reviews, audit trail (git log), security advisories (Dependabot). CI/CD enforces security gates before deployment.')
    ])
]))

reqs.append(ctrl('sa-11', 'implemented', 'sp-system', [
    ('smt', [
        (SYS, 'Developer security testing per SSP §10.7.4 (Code Scanning): gitleaks pre-commit hook (secret detection), Dependabot alerts (dependency CVEs), OpenTofu validate (IaC syntax/security), pnpm run lint (application code linting).'),
        (PROWL, 'Prowler post-deployment security testing: verifies CSP resources comply with security policies (encryption, access controls, tagging). FedRAMP compliance checks per prowler --compliance fedramp_moderate_revision_4.'),
        (GH, 'GitHub Actions CI/CD runs all security gates on every PR. Failed security checks block merge per branch protection rules.')
    ])
]))

reqs.append(inh('sa-11.1', 'cloud.gov performs static code analysis on platform components. INHERITED.'))

reqs.append(sys_ctrl('sa-15', [
    ('smt', [(SYS, 'Development process, standards, and tools: Go 1.21+ (memory-safe language); OpenTofu 1.11.6 (IaC); GitHub Actions (CI/CD); gitleaks (secret scanning); OSCAL (compliance documentation). Development standards: conventional commits, PR template with security checklist (.github/PULL_REQUEST_TEMPLATE.md), code review required. Flaws tracked via GitHub Issues.')])
]))

reqs.append(sys_ctrl('sa-16', [
    ('smt', [(SYS, 'Developer training: TTS team onboarding covers CSB-specific training (at-3). Vendor documentation: cloud-service-broker GitHub wiki; cloud.gov docs; OpenTofu docs; CSP SDK documentation. All referenced in docs/ directory.')])
]))

reqs.append(sys_ctrl('sa-17', [
    ('smt', [(SYS, 'Security architecture and engineering, design, code, and test documentation maintained in GitHub (docs/, scripts/, submodules/). Architecture documented per PL-8. Source code in open GitHub repo (GSA-TTS/cloud-sandbox). No custom hardware or undocumented components.')])
]))

reqs.append(sys_ctrl('sa-22', [
    ('smt', [(SYS, 'Unsupported system components policy: TTS maintains dependency versions with active support (go.sum, pnpm-lock.yaml). Cloud-service-broker: active open-source project; TTS monitors for abandonment. OpenTofu: active fork of Terraform, Linux Foundation project. If a component reaches end-of-support: TTS replaces within 6 months (HIGH priority POA&M item). Dependabot alerts on EOL components.')])
]))

# ══════════════════════════════════════
# SC — System and Communications Protection
# ══════════════════════════════════════

reqs.append(sys_ctrl('sc-1', [
    ('smt', [(POL, 'INHERITED (corporate): GSA SC policy per CIO 2100.1.'),
             (SYS, 'SYSTEM-SPECIFIC: TTS SC procedures: TLS enforcement reviewed in manifests (no HTTP allowed); CSP security group rules reviewed at each brokerpak update; encryption settings reviewed at each plan parameter change.')])
]))

reqs.append(ctrl('sc-2', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov isolates SSB broker app from other tenants via CF application container isolation (Garden/Diego). Cross-tenant network communication impossible due to CF networking architecture.'),
        (SYS, 'SYSTEM-SPECIFIC: SSB separates user management (CF UAA, cloud.gov) from application functionality (OSBAPI broker). Broker application has no access to CF admin functions. No shared memory or process space with other CF apps.')
    ])
]))

reqs.append(inh('sc-3', 'cloud.gov container isolation provides security function isolation. INHERITED.'))
reqs.append(inh('sc-4', 'cloud.gov container isolation prevents shared resources between tenants. INHERITED.'))
reqs.append(inh('sc-5', 'cloud.gov ALB provides DoS protection (rate limiting, connection throttling). AWS Shield Basic provides DDoS protection. INHERITED from cloud.gov.'))

reqs.append(ctrl('sc-7', 'implemented', 'hybrid', [
    ('smt', [
        (GTR, 'INHERITED: CF GoRouter/ALB is the single boundary protection point for all inbound traffic. CF egress controlled by application security groups (CF ASGs).'),
        (CG, 'INHERITED: cloud.gov manages CF network isolation between orgs/spaces. CSB broker cannot access other tenants.'),
        (SYS, 'SYSTEM-SPECIFIC: CSP egress (AWS/GCP/Azure API calls) exits via CF ASG-permitted HTTPS to public internet. CSP security groups (SGs/firewall rules) restrict sandbox resources to CF egress IP ranges. TTS maintains CSP-side security groups in brokerpak OpenTofu modules. Authorization boundary enforced: provisioned CSP resources are OUTSIDE the boundary per SSP §9.2.')
    ])
]))

reqs.append(inh('sc-7.3', 'cloud.gov access points limited to GoRouter/ALB. No other ingress paths. INHERITED.'))
reqs.append(inh('sc-7.4', 'cloud.gov external telecommunications services managed by cloud.gov/AWS. INHERITED.'))
reqs.append(inh('sc-7.5', 'cloud.gov deny-all-by-default network policy, then allow-list via ASGs. INHERITED.'))
reqs.append(inh('sc-7.7', 'cloud.gov prevents split tunneling at CF network layer. INHERITED.'))

reqs.append(ctrl('sc-7.8', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Outbound traffic routing: CSP API calls (AWS SDK, GCP SDK, Azure SDK) exit via CF application security groups to HTTPS (443) on public internet. No split tunneling. CSP API endpoints are the only authorized egress destinations from broker containers beyond csb-sql MySQL (CF internal). Routing enforced by CF ASG rules (not configurable by TTS at the container level).')])
]))

reqs.append(inh('sc-7.18', 'cloud.gov GoRouter fails securely — reject connections to unhealthy instances. INHERITED.'))
reqs.append(inh('sc-7.21', 'cloud.gov isolation between CF spaces prevents cross-space network access. INHERITED.'))

reqs.append(ctrl('sc-8', 'implemented', 'hybrid', [
    ('smt', [
        (TLS, 'TLS 1.2+ enforced by cloud.gov GoRouter/ALB for all inbound connections. Let\'s Encrypt certificates managed by cloud.gov. TLS also enforced by CF internal overlay for app-to-app communication.'),
        (SYS, 'SYSTEM-SPECIFIC: OSBAPI endpoint served exclusively over HTTPS (TLS 1.2+). HTTP connections redirected to HTTPS by GoRouter (301). CSP API calls use AWS SDK TLS (4.x SDK defaults to TLS 1.2+), GCP SDK (HTTPS only), Azure SDK (TLS 1.2+). csb-sql MySQL connection uses TLS (enforced by cloud.gov aws-rds service).')
    ])
]))

reqs.append(inh('sc-8.1', 'cloud.gov GoRouter/ALB enforces HTTPS with TLS 1.2+ for all traffic. Cryptographic protection of data in transit. INHERITED.'))
reqs.append(inh('sc-10', 'cloud.gov terminates network connections after defined period of inactivity. INHERITED.'))

reqs.append(ctrl('sc-12', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov (Let\'s Encrypt via cert-manager) manages TLS certificate lifecycle for broker endpoints. AWS KMS manages encryption keys for csb-sql RDS, CF-managed secrets.'),
        (SYS, 'SYSTEM-SPECIFIC: CSP resources use CSP-managed key management: AWS KMS (RDS, S3 SSE-S3, ElastiCache), Google KMS (Cloud SQL, GCS), Azure Key Vault (PostgreSQL TDE). TTS configures encryption-at-rest in brokerpak OpenTofu modules. No TTS-managed key material (all delegated to CSP/cloud.gov managed services).')
    ])
]))

reqs.append(inh('sc-12.1', 'FIPS 140-2 keys managed by cloud.gov (Let\'s Encrypt via AWS ACM) and AWS KMS. INHERITED.'))

reqs.append(ctrl('sc-13', 'implemented', 'hybrid', [
    ('smt', [
        (FIPS, 'AES-256 encryption at rest: csb-sql RDS (AWS KMS AES-256, FIPS 140-2 validated), sandbox RDS instances (storage_encrypted=true), ElastiCache (at_rest_encryption_enabled=true), S3 (SSE-S3 AES-256), Azure Storage (AES-256 TDE), Azure SQL (TDE). All compliant with FIPS 140-2 Level 1+.'),
        (TLS, 'TLS 1.2+ for data in transit using FIPS-approved cipher suites per cloud.gov ALB/GoRouter configuration. ECDHE key exchange, AES-GCM bulk encryption, SHA-256 HMAC. FIPS 140-2 compliant TLS library (Go crypto/tls, AWS SDK TLS).')
    ])
]))

reqs.append(na('sc-15', 'The TTS Cloud Sandbox SSB does not use collaborative computing devices (no video conferencing, screen sharing, or audio/visual capabilities). REST API service only.'))

reqs.append(ctrl('sc-17', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov issues and manages PKI certificates (Let\'s Encrypt) for broker endpoints. Automated renewal via cloud.gov cert-manager.'),
        (SYS, 'SYSTEM-SPECIFIC: No TTS-issued PKI certificates. All certificate issuance delegated to cloud.gov (Let\'s Encrypt) and CSP-managed CAs for API endpoints.')
    ])
]))

reqs.append(na('sc-18', 'The TTS Cloud Sandbox SSB does not use mobile code (no JavaScript/Java applets in browser). REST API service with no browser client-side execution.'))

reqs.append(ctrl('sc-20', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov provides DNS services with DNSSEC for *.app.cloud.gov domain. Broker apps resolve via cloud.gov DNS (route auto-assigned on cf push).'),
        (SYS, 'SYSTEM-SPECIFIC: No TTS-managed DNS infrastructure. CSP API endpoints use CSP-managed DNS.')
    ])
]))

reqs.append(inh('sc-21', 'cloud.gov DNS clients validate DNSSEC signatires. INHERITED.'))
reqs.append(inh('sc-22', 'cloud.gov network architecture provides fault-tolerant DNS (Route 53, multi-region). INHERITED.'))
reqs.append(inh('sc-23', 'cloud.gov GoRouter session authenticity protection via TLS. INHERITED.'))
reqs.append(inh('sc-24', 'cloud.gov CF containers fail in known state. INHERITED.'))
reqs.append(inh('sc-26', 'cloud.gov platform provides honeypot capabilities at network boundary. INHERITED.'))

reqs.append(ctrl('sc-28', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov/AWS encrypts all data at rest for managed services (csb-sql RDS AES-256 via AWS KMS). Cloud.gov container ephemeral storage also encrypted at rest by AWS.'),
        (FIPS, 'SYSTEM-SPECIFIC CSP-level: All sandbox service instances provisioned by CSB broker use encryption-at-rest: RDS (storage_encrypted=true, KMS), ElastiCache (at_rest_encryption_enabled=true), S3 (SSE-S3), Azure SQL (TDE), Azure Redis (encryption at rest enabled). Enforced in brokerpak OpenTofu modules — cannot be disabled by user-supplied plan parameters.')
    ])
]))

reqs.append(inh('sc-28.1', 'cloud.gov/AWS KMS provides cryptographic protection for data at rest via AES-256. INHERITED.'))
reqs.append(inh('sc-39', 'cloud.gov CF/Garden container isolation provides process isolation. INHERITED.'))
reqs.append(inh('sc-43', 'cloud.gov restricts usage of network connection types per platform ASG policy. INHERITED.'))

# ══════════════════════════════════════
# SI — System and Information Integrity
# ══════════════════════════════════════

reqs.append(sys_ctrl('si-1', [
    ('smt', [(POL, 'INHERITED (corporate): GSA SI policy per CIO 2100.1 and CIO-IT Security-01-05.'),
             (SYS, 'SYSTEM-SPECIFIC: TTS SI procedures: GitHub Dependabot monitors dependencies; Prowler scans CSP resources; gitleaks pre-commit prevents secret exposure. Reviewed annually.')])
]))

reqs.append(ctrl('si-2', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov automatically updates all platform components (CF release, buildpacks, OS) via BOSH rolling upgrades. TTS has no exposure to platform-level CVEs.'),
        (SYS, 'SYSTEM-SPECIFIC: CSB broker dependencies updated via: (1) GitHub Dependabot PRs for go.mod CVEs; (2) Go runtime updates built into new broker releases; (3) OpenTofu version pinned, updated per changelog review; (4) Brokerpak submodule updates reviewed for CVE fixes. Critical CVEs (CVSS ≥9.0) remediated within 30 days; High (7.0-8.9) within 60 days. Vulnerability tracking in github.com/GSA-TTS/cloud-sandbox/security/advisories.')
    ])
]))

reqs.append(inh('si-2.2',
    'cloud.gov/CF buildpacks provide automated patching and updates for platform runtime components (middleware, OS packages). Broker uses binary_buildpack — binaries pre-compiled, no buildpack runtime patching applies. INHERITED platform patching for OS-level CVEs.'))

reqs.append(inh('si-3',
    'cloud.gov CF container security scanning and buildpack validation handles malicious code protection at platform level. Container images scanned. INHERITED. Note: TTS uses binary_buildpack (pre-compiled Go binary), not an interpreted language; no script-injection risk from buildpack layer.'))

reqs.append(inh('si-3.1', 'cloud.gov implements centralized malicious code protection management for platform. INHERITED.'))

reqs.append(ctrl('si-4', 'implemented', 'sp-system', [
    ('smt', [
        (PROWL, 'Prowler v3.x performs weekly automated CSP resource monitoring for security misconfigurations, policy violations, and anomalous resource patterns (unexpected resource creation, missing tags, overly permissive security groups). Alerts via GitHub Actions on new HIGH/CRITICAL findings.'),
        (LOG, 'CF Loggregator + logs.fr.cloud.gov provides continuous broker application monitoring. Kibana dashboards track: authentication failures, broker error rates, TTL extension attempts, unusual service provision counts. ISSO reviews weekly.'),
        (CAPI, 'CF CAPI audit events provide CF-layer monitoring: role changes, broker operations, app deployments. Monitored via Kibana saved searches at logs.fr.cloud.gov.')
    ])
]))

reqs.append(inh('si-4.1', 'cloud.gov Loggregator provides intrusion detection aggregation at platform level. INHERITED.'))
reqs.append(inh('si-4.2', 'cloud.gov platform security tools automated. INHERITED.'))
reqs.append(inh('si-4.4', 'cloud.gov inbound/outbound traffic monitoring at ALB/GoRouter layer. INHERITED.'))

reqs.append(ctrl('si-4.5', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'System-generated alerts: GitHub Actions alerts on Prowler HIGH/CRITICAL findings via workflow failure notification. Kibana alerting (configured by ISSO) on: broker error rate >10%, authentication failures >5/hour, unusual service provision patterns. Alerts delivered via email/Slack to TTS TechOps and ISSO.')])
]))

reqs.append(inh('si-4.7', 'cloud.gov provides automated threat detection at platform level. INHERITED.'))
reqs.append(inh('si-4.23', 'cloud.gov provides host-based monitoring at CF cell level. INHERITED.'))

reqs.append(corp('si-5',
    'INHERITED (corporate): GSA OCISO receives and acts on security alerts from US-CERT, DHS, and vendor advisories. TTS receives relevant advisories via GSA OCISO alerts. TTS monitors GitHub Security Advisories and Dependabot for broker dependencies.'))

reqs.append(ctrl('si-6', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Security function verification: (1) CF app health checks (cf app csb-aws shows running state); (2) cf marketplace verifies broker plans are registered and available; (3) smoke test: cf create-service csb-aws-postgresql sandbox-8h test-verify — verifies OpenTofu and CSP connectivity; (4) Prowler scan verifies CSP security controls active. Verification performed after each deployment and weekly as part of ConMon (ca-7).')])
]))

reqs.append(ctrl('si-7', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov verifies integrity of CF platform components via BOSH SHA256 checksums and signed releases.'),
        (SYS, 'SYSTEM-SPECIFIC: (1) go.sum provides cryptographic integrity verification for all Go dependencies (SHA256 hash of each module version); (2) OpenTofu provider checksums in .terraform.lock.hcl verify plugin integrity; (3) GitHub Actions uses pinned action versions (SHA-pinned) to prevent supply chain attacks; (4) Brokerpak bundles verified via SHA256 at broker startup.')
    ])
]))

reqs.append(inh('si-7.1', 'cloud.gov BOSH provides automated integrity verification of platform components. INHERITED.'))

reqs.append(ctrl('si-7.7', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Unauthorized security-relevant software changes detected via: (1) GitHub commit signatures (GPG-signed commits policy); (2) go.sum hash verification (changes flagged by go mod verify); (3) GitHub Actions audit log tracks CI/CD pipeline changes; (4) OpenTofu plan output reviewed before apply — unexpected resource changes flagged.')])
]))

reqs.append(sys_ctrl('si-8', [
    ('smt', [(SYS, 'Spam protection: not applicable as a primary concern for this API service. Email (if used for notifications) routes through GSA enterprise mail (spam-filtered by GSA). OSBAPI does not process email content. This control is N/A for the broker API but implemented at the GSA corporate level for organizational email.')])
]))

reqs.append(inh('si-8.1', 'GSA enterprise centrally manages spam protection for organizational email. INHERITED (corporate).'))
reqs.append(inh('si-8.2', 'GSA centrally manages spam protection updates. INHERITED (corporate).'))

reqs.append(ctrl('si-10', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'OSBAPI request input validation enforced by cloud-service-broker library: (1) Service plan parameters validated against JSON schema defined in brokerpak YAML (plan_parameters_schema); (2) Invalid plan IDs, service IDs, or parameters return HTTP 400; (3) ttl_hours parameter range-checked (max 8); (4) extend_hours validated (max 4, only once per instance); (5) OpenTofu variable validation blocks in modules enforce type and constraint checks before any CSP API calls.')])
]))

reqs.append(ctrl('si-11', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Error handling: OSBAPI endpoint returns RFC-compliant error responses: HTTP 4xx for client errors (invalid parameters, not found), HTTP 5xx for server errors (CSP API failure, OpenTofu error). Error messages include error type and description but do NOT expose internal stack traces, OpenTofu state contents, or CSP credentials. Go error wrapping with context-aware messages. Errors logged to Loggregator for ISSO review.')])
]))

reqs.append(ctrl('si-12', 'implemented', 'hybrid', [
    ('smt', [
        (CG, 'INHERITED: cloud.gov manages output handling for platform components. ELK log retention 180 days.'),
        (SYS, 'SYSTEM-SPECIFIC: OSBAPI response handling: binding credentials included in bind response (VCAP_SERVICES injection by CF). Credentials not logged after initial bind response. De-provisioned resource records purged from csb-sql on unbind/delete per CP-10 / TTL lifecycle. No residual credentials in broker response cache.')
    ])
]))

reqs.append(inh('si-16', 'cloud.gov CF container memory protection enforced by Garden isolation. INHERITED.'))

# ══════════════════════════════════════
# SR — Supply Chain Risk Management
# ══════════════════════════════════════

reqs.append(sys_ctrl('sr-1', [
    ('smt', [(POL, 'INHERITED (corporate): GSA SR policy per CIO 2100.1 and GSA Supply Chain Risk Management (SCRM) program.'),
             (SYS, 'SYSTEM-SPECIFIC: TTS SCRM: open-source components reviewed via GitHub Dependabot and go.sum integrity; brokerpak submodules pinned to specific commits; provider plugins verified via Terraform Registry checksums; CSP SDK packages from official registries.')])
]))

reqs.append(sys_ctrl('sr-2', [
    ('smt', [(SYS, 'Supply chain risk plan: Go dependencies assessed via go.sum SHA256 hashes + Dependabot CVE alerts; OpenTofu providers assessed via .terraform.lock.hcl hashes + Terraform Registry provenance; brokerpak code (GSA-TTS-maintained fork): assessed via GitHub PR review and CI; CSP SDKs (AWS SDK Go v2, GCP Go SDK, Azure SDK for Go): maintained by CSP, assessed via Dependabot. Supply chain risks tracked in GitHub security advisories.')])
]))

for sr_ctrl_id in ['sr-3','sr-4','sr-5','sr-6','sr-7','sr-8','sr-9','sr-10','sr-11','sr-12']:
    reqs.append(sys_ctrl(sr_ctrl_id, [
        ('smt', [(SYS,
            f'({sr_ctrl_id.upper()}) Supply chain control: TTS manages supply chain for SSB through open-source component vetting (go.sum, Dependabot), CSP SDK provenance verification, brokerpak submodule commit pinning, and Github PR-based change control. GSA corporate SCRM program provides enterprise-level {sr_ctrl_id.upper()} controls. See SR-1/SR-2 for TTS-specific procedures.')])
    ]))

# ══════════════════════════════════════
# PT — PII Processing and Transparency (Rev 5 Privacy Family, SSP §14)
# ══════════════════════════════════════

reqs.append(sys_ctrl('pt-1', [
    ('smt', [(POL, 'INHERITED (corporate): GSA Privacy policy per Privacy Act 1974, E-Government Act 2002, OMB M-03-22, OMB A-130. GSA Chief Privacy Officer manages enterprise privacy program.'),
             (SYS, 'SYSTEM-SPECIFIC: TTS PT procedures: PTA/PIA determination conducted per SSP §14. Determination: TTS Cloud Sandbox SSB does NOT collect, maintain, or process PII (see PT-2/AP-1 determination below). Privacy review: annual with SSP review cycle. Privacy contact: GSA Privacy Office (gsa-privacy@gsa.gov).')])
]))

reqs.append(ctrl('pt-2', 'implemented', 'sp-system', [
    ('smt', [(SYS, 'Authority and purpose determination (SSP §14 / AP-1 equivalent): The TTS Cloud Sandbox SSB does NOT collect or process PII. Authority: FISMA 2014 (security controls for government IT), OMB A-130 (information management), GSA IT Security Policy CIO 2100.1. Purpose: Provision and lifecycle-manage short-lived (TTL 8h) test/sandbox infrastructure on behalf of TTS engineers for development and integration testing only. No PII, no sensitive data, no production data permitted in sandboxes (enforced by policy and conveyed in user training). Privacy Impact Assessment (PIA): NOT REQUIRED (no PII collected per OMB M-03-22 threshold assessment).')])
]))

reqs.append(sys_ctrl('pt-3', [
    ('smt', [(SYS, 'Personally Identifiable Information Disclosure Consent (AP-2/PT-3): No PII collected — not applicable. However, system does collect: (1) GSA ENT Domain username (UAA account identifier — de-identified service account, not PII for this purpose); (2) Owner email address tag (Owner=user@gsa.gov) on provisioned resources — represents minimal government employee contact information. This use is authorized by FISMA administrative purpose and does not require separate PTA/PIA. Disclosed only to System Owner and ISSO for accountability.')])
]))

for pt_ctrl_id in ['pt-4','pt-5','pt-6','pt-7','pt-8']:
    reqs.append(sys_ctrl(pt_ctrl_id, [
        ('smt', [(SYS,
            f'({pt_ctrl_id.upper()}) The TTS Cloud Sandbox SSB does not collect PII per PT-2 determination. '
            'This privacy control is not applicable in its PII-specific form. '
            'The system collects minimal government employee identifiers (ENT Domain username, '
            'GSA email address as resource Owner tag) solely for accountability purposes per FISMA. '
            'GSA Privacy Office (gsa-privacy@gsa.gov) confirms no PIA required. '
            'Privacy controls implemented at the GSA corporate level via GSA OCIPO privacy program.')])
    ]))

# ─────────────────────────────────────────────────────────────────────────────
# WRITE TO SSP
# ─────────────────────────────────────────────────────────────────────────────

with open(SSP_PATH) as f:
    doc = json.load(f)

doc['system-security-plan']['control-implementation']['implemented-requirements'] = reqs

with open(SSP_PATH, 'w') as f:
    json.dump(doc, f, indent=2)

print(f'Written {len(reqs)} control implementations to {SSP_PATH}')
