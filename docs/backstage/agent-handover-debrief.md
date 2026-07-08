# Backstage on cloud.gov: Agent Handover Debrief

**Date:** 2026-07-07
**Context:** Deployment of a Backstage developer portal monolithic app to cloud.gov (Cloud Foundry) using the Node.js buildpack.

## 1. Architectural Decisions & Deployment Strategy
*   **Artifact-based Deployment:** Cloud Foundry's `nodejs_buildpack` staging environment restricts memory/disk to 2GB/4GB by default. We abandoned raw source deployment (which caused `ENOSPC` and `OOM` crashes due to massive `yarn install` devDependency graphs) in favor of **artifact deployment**.
*   **`deploy-workspace` Mechanism:** To deploy, we compile the app locally (`yarn workspace app build` & `yarn workspace backend build`) which produces `packages/backend/dist/bundle.tar.gz`. We run `./package-deploy.sh` to extract this bundle, strip out all `devDependencies`, remove local workspace links, and pre-create empty cache directories. We deploy ONLY the resulting `deploy-workspace/` directory via `manifest.yml`.
*   **Dynamic Credential Binding (`vcap-env.js`):** Because Backstage expects traditional environment variables (like `POSTGRES_USER` and `CLOUDGOV_CLIENT_ID`), but cloud.gov uses the `VCAP_SERVICES` JSON block, we use a pre-load script (`node -r ./vcap-env.js ...`) in the manifest start command. This script dynamically parses `VCAP_SERVICES` to locate `backstage-db` (AWS RDS) and `backstage-sso` (cloud-gov-identity-provider) and injects standard env vars into the Node process before Backstage initializes.

## 2. Resolved Issues in the Last Session
*   **CF Staging `ENOSPC` (Disk Exhaustion):** Yarn/npm were downloading gigabytes of cache into the Cloud Foundry RAM disk (`/tmp`). We fixed this by redirecting `TMPDIR`, `YARN_CACHE_FOLDER`, and `NPM_CONFIG_CACHE` to physical disk paths (`/home/vcap/app/.tmp`, etc.) inside the container, keeping them alive with `.keep` files. We also stripped `devDependencies` and the `app` workspace link out of `package.json` to prevent CF from attempting a massive dependency fetch.
*   **Frontend Plugin Crashes (`NotImplementedError` for `apiRef`):** The app crashed on boot because `@backstage/plugin-notifications` was missing. Added it to the declarative frontend in `App.tsx` and rebuilt the bundle.
*   **Auth Bypass & Configuration:** Backstage was skipping authentication. We disabled the `guest` provider in `app-config.yaml` and explicitly registered the OIDC sign-in screen using the new declarative frontend syntax (`core.router.signInPage` with `provider: oidc`). We also added fallback `:-placeholder` values to `app-config.production.yaml` so the OIDC plugin doesn't crash if `vcap-env.js` fails to find SSO credentials immediately.
*   **Symlink Loss:** The `bundle.tar.gz` artifact loses the `node_modules/app` -> `packages/app` symlink when unpacked in CF. We added a runtime repair script in `vcap-env.js` to recreate this symlink dynamically so `@backstage/plugin-app-backend` can serve the frontend successfully.

## 3. Current State
*   The application manifest (`manifest.yml`) and `app-config.production.yaml` are correctly scoped to the public route: `https://backstage-sandbox-portal.app.cloud.gov`.
*   The `deploy-workspace` compiles successfully, respects the 2GB Cloud Foundry sandbox limit, and bypasses out-of-space staging errors.
*   The `cloud-gov-identity-provider` has been brokered to the app as `backstage-sso` with the correct `redirect_uris` callback configured.

## 4. Next Steps for Incoming Agent
1. **Validate OIDC Authentication Flow:** Once the portal starts, attempt to log in via cloud.gov SSO. Check the Cloud Foundry logs (`cf logs backstage-sandbox-portal`) to ensure the callback routing completes successfully and identity tokens map properly to Backstage users.
2. **Fix Missing Catalog Example Data Warnings:** The logs continuously throw warnings: `file /home/vcap/app/examples/entities.yaml does not exist`. This happens because `app-config.production.yaml` is pointing to local files that aren't included in the production `bundle.tar.gz`.
   *   *Action:* Remove the `locations:` block pointing to `./examples/...` in `app-config.production.yaml` and replace it with a remote URL (like a GitHub URL) that hosts your catalog entities.
3. **Database Migrations:** Monitor the logs to verify that the PostgreSQL database connection string is properly formed by `vcap-env.js` and that Backstage successfully applies its schema migrations.
4. **General Debugging Strategy:** If you need to make code changes, **always** remember to rebuild the bundle (`yarn build:all` or `yarn workspace app build && yarn workspace backend build`), then run `./package-deploy.sh`, and finally `cf push`. Do not push raw source files.
