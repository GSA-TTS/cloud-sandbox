# Cloud.gov security-auditor bindings

The `csb-*-security-auditor` services create provider-specific, read-only audit
identities. The `sandbox-8h` plan records an eight-hour maximum lifecycle
timestamp; it does not automatically delete an identity without a separately
approved TTL controller. Credentials are delivered only through Cloud Foundry
service bindings. Prowler is the current supported consumer; its credentials
are not copied into Prowler's database or deployment manifest.

## Rollout sequence

1. Complete brokerpak review, package validation, and service approval.
2. Publish the AWS, GCP, and Azure security-auditor offerings to the Cloud.gov broker.
  Do not use CSB's global `preview` toggle as an approval gate: it enables or
  disables every preview-tagged offering in that broker. Before publication,
  attach the accepted provider approval record to the deployment change and
  restrict Cloud Foundry service access to the approved organization and space.
3. Create one `sandbox-8h` service instance for each approved provider scope.
4. Bind an instance only to the approved audit client. For the hosted Prowler
  integration, bind both `prowler-api-web` and `prowler-api-worker`; do not bind
  the scheduler unless a scheduled task needs cloud credentials.
5. Restage bound applications so Cloud Foundry supplies `VCAP_SERVICES`.
6. For the Prowler integration, store only this selector in provider configuration:

   ```json
   { "vcap_service_instance_name": "the-bound-service-instance-name" }
   ```

7. Run the provider connection test, then create the hosted scan and review
   findings in the Cloud.gov Prowler UI.

The binding name is an exact service-instance selector. Prowler rejects a
missing, duplicate, malformed, or provider-mismatched binding. It does not use
the first service under a broker label.

## Provider scope

- **AWS:** A binding user can assume only its paired auditor role with the
  instance external ID. The role session lasts at most one hour and has the
  managed `SecurityAudit` and `ViewOnlyAccess` policies. Review managed-policy
  drift before production approval.
- **GCP:** The service account has project-scoped `roles/viewer` and
  `roles/serviceusage.serviceUsageConsumer`. Organization discovery is not
  included. Binding keys must be removed by unbind/deprovision.
- **Azure:** The Entra service principal receives only subscription-scoped
  `Reader`. It has no Microsoft Graph permissions and no App Service
  key/config-list actions. Binding-specific client-secret expiry matches the
  instance expiry.

## Lifecycle and safety controls

- Sandbox plans permit a maximum recorded lifetime of eight hours. The broker
  records `ttl_expires_at` as lifecycle metadata; that timestamp alone does not
  delete an identity or revoke AWS/GCP credentials.
- Unbind removes the generated binding credential. Deprovision removes the
  provider audit identity and its access only when Cloud Foundry deprovisioning
  is invoked. Azure binding-specific client secrets expire at `ttl_expires_at`,
  while its service principal and Reader assignment still require normal
  deprovisioning for removal.
- Broker instance details retain the effective lifecycle metadata (`Project`,
  `Owner`, `TTLExpiry`, `CostCenter=sandbox-nonprod`, `Cloud`, and
  `Environment`) and Cloud Foundry provenance. AWS applies the tag map to the
  auditor IAM role, which supports IAM tags. GCP service accounts/project IAM
  memberships do not accept labels, and Entra applications, service principals,
  and Azure role assignments do not accept Azure resource tag maps; their
  metadata must therefore be tracked in the broker instance record until a
  provider-supported identity metadata mechanism is approved.
- Do not log `VCAP_SERVICES`, broker bind responses, access keys, client
  secrets, service-account key JSON, or normalized binding payloads.
- Provisioning, binding, restaging, and scans are operational actions and
  require the applicable cloud, broker, and security approvals.

## Approval evidence

Before publishing any security-auditor offering, obtain and link the three approval records:

- `[Service Approval Request] aws/security-auditor`
- `[Service Approval Request] gcp/security-auditor`
- `[Service Approval Request] azure/security-auditor`

Each record must identify the approved account, project, or subscription scope;
the provider's read-only permissions; the eight-hour lifecycle; the
binding-only credential delivery model; required broker labels; and the GCP and
Azure identity-metadata limitation. Record the approving authority and the
deployment revision that contains the approved service definition.

## Pre-deployment readiness gate

Do not deploy a broker or provision an audit identity until all of the following
are recorded in the deployment change:

- Links to the three accepted approval records and their approved cloud scopes.
- A Cloud.gov target and RBAC check for the intended organization and space,
  plus service-access restrictions for those scopes.
- Confirmation that the untracked provider environment files exist and contain
  the required deployment credentials. Do not print their contents.
- Confirmation that the Prowler web and worker applications have approved
  egress (or an approved proxy) to the relevant provider APIs.
- For Azure, confirmation that the broker deployment identity can create Entra
  applications and client secrets and assign `Reader` at the approved
  subscription scope.
- An explicit deprovision and provider-side removal verification step. The
  `sandbox-8h` timestamp is not an automatic AWS or GCP cleanup mechanism.

Run one provider deployment and one provider connection check at a time. Stop
on a failed gate; do not compensate by broadening permissions or exposing
binding credentials in diagnostics.

## Compliance frameworks

Use a provider-specific, allow-listed framework selection in the hosted Prowler
API. Do not expose arbitrary scanner arguments. Framework support and the
minimum audit permissions must be verified against the selected Prowler bundle
before publishing a service plan.