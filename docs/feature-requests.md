# Cloud Sandbox Feature Requests & Future Work

Based on a comprehensive review of the `cloud-sandbox` codebase, the project showcases an impressive architecture for multi-cloud sandbox lifecycle management, enforcing strict 8-hour TTLs and budgets using the Cloud Foundry Cloud Service Broker (CSB) and custom OpenTofu/Terraform brokerpaks. It also includes forward-looking Model Context Protocol (MCP) integrations for AI agents.

However, there are several areas where the codebase can be improved to increase robustness, finalize the user experience, and ensure maintainability. Here are the prioritized suggestions for future work:

## 1. Frontend Customization & Dashboard Implementation
Currently, the Gatsby frontend (`src/`) appears to be heavily based on a Federalist + USWDS 2.0 boilerplate template. 
* **Remove Boilerplate Data:** `gatsby-config.js` is still populated with placeholder metadata like `author: "Foo"`, `title: "Agency Name"`, and dummy search.gov/DAP configurations. Update these to reflect the actual GSA TTS Sandbox project.
* **Transition to an Active Dashboard:** While the site currently serves OSCAL static documentation, it should be expanded into an active developer dashboard. By interfacing with the CF API, you can provide engineers with a UI to view their active sandboxes, remaining TTL countdowns, budget utilization against the $500/month cap, and direct links to connect to their environments.

## 2. Introduce Comprehensive Testing
The repository relies heavily on custom scripts and UI components, but testing is mostly isolated to the brokerpak submodules and Prowler. 
* **Shell Script Testing:** The deployment and orchestration scripts in `scripts/` (e.g., `deploy-aws.sh`, `refresh-model-catalogs.sh`) handle complex state and environmental variables. Introduce a framework like **Bats (Bash Automated Testing System)** to ensure these scripts don't break during refactors and correctly handle edge cases (like missing `cf` CLI authentication).
* **Python MCP Testing:** The local MCP tools in `tools/mcp` currently lack unit tests. Introduce `pytest` to test the logic of your `databricks-mcp` and custom integration behaviors.
* **Frontend UI Testing:** Add **Jest** and **React Testing Library** for the React components in `src/components/` and `src/pages/` to prevent regressions as the UI scales.

## 3. Architecture & Operational Hardening
* **Out-of-band TTL Cleanup Mechanism:** The 8-hour TTL is currently enforced at the CSB/Terraform plan level. If the brokerpak database crashes or Cloud Foundry experiences an outage, instances could be orphaned and accrue costs. Implement an out-of-band serverless function (e.g., AWS Lambda, GCP Cloud Function) that runs on a cron schedule to cross-reference the `csb-sql` broker state with actual active instances in the CSPs, forcefully terminating any orphaned resources over 8 hours old.
* **Dynamic Environment Variable Generation:** In `scripts/envs/aws.env.example`, the CF broker plans are maintained as hardcoded JSON strings inside Bash variables (e.g., `GSB_SERVICE_CSB_AWS_POSTGRESQL_PLANS='[{...}]'`). This is prone to syntax errors. Create a lightweight Python or Node utility that dynamically builds these JSON payloads from simpler YAML configuration files during the `cf push` pipeline.

## 4. Continuous Compliance & OSCAL Automation
* **Living System Security Plan (SSP):** The repository maintains OSCAL schemas (`src/oscal/`, `content/`) and uses Prowler for continuous CIS/FedRAMP hardening. You can bridge these two by writing a script that parses Prowler's output JSON and automatically updates the respective OSCAL control statuses (e.g., using `scripts/patch_ssp_controls.py`). This would effectively turn the repository into a fully automated, living SSP.
* **CI/CD Pipeline Expansion:** I noticed a `.gitlab-ci.yml` and a `.github` folder. Standardize on your primary CI/CD platform and ensure PR checks automatically run `prowler:test`, `broker:validate`, `broker:lint`, and your `secrets:scan` (`gitleaks`) on every commit to prevent misconfigured brokerpaks from being pushed to the `master` branch.
