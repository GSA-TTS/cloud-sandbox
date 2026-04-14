---
description: "Use when: GitLab CI pipeline, GitHub → GitLab sync, pipeline trigger webhook, deployment pipeline, broker deploy job, prowler scan job, production deployment, GitLab runner, CI/CD variables, submodule version bump, pipeline architecture, .gitlab-ci.yml"
tools: [read, edit, search, execute, todo]
name: "CI/CD Pipeline"
---

# CI/CD Pipeline — GitHub → GitLab Deployment Architecture

## Overview

This repo uses a **two-repo architecture**:

| Repo                                 | Purpose                                              |
| ------------------------------------ | ---------------------------------------------------- |
| **GitHub** (`GSA-TTS/cloud-sandbox`) | Public · documentation · reuse template · no secrets |
| **GitLab** (production mirror)       | Secrets · GitLab runners · production deployments    |

Merge to `main` on GitHub → GitHub Action (`.github/workflows/sync-to-gitlab.yml`) → GitLab Pipeline Trigger API → `.gitlab-ci.yml` runs on GitLab runner.

## Key Files

| File                                   | Role                                                                                           |
| -------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `.gitlab-ci.yml`                       | Pipeline stages: validate → backing-db → deploy-aws → deploy-gcp → deploy-azure → prowler-scan |
| `.github/workflows/sync-to-gitlab.yml` | GitHub Action: fires GitLab trigger on push to main                                            |

## Pipeline Stages

```
validate          → CF login + env var sanity check
backing-db        → Ensure csb-sql MySQL exists
deploy-aws        → Build + cf push csb-aws (keyed on CSB_AWS_VERSION)
deploy-gcp        → Build + cf push csb-gcp (keyed on CSB_GCP_VERSION)
deploy-azure      → Build + cf push csb-azure (BLOCKED: set DEPLOY_AZURE=true when ARM_* vars ready)
prowler-scan-*    → Nightly FedRAMP Moderate scan across AWS / GCP / Azure
```

## Submodule Version Variables

Update these in `.gitlab-ci.yml` whenever a submodule commit pointer is bumped:

| Variable            | File                                          | Current  |
| ------------------- | --------------------------------------------- | -------- |
| `CSB_AWS_VERSION`   | `submodules/csb-brokerpak-aws/manifest.yml`   | `0.1.0`  |
| `CSB_GCP_VERSION`   | `submodules/csb-brokerpak-gcp/manifest.yml`   | `0.1.0`  |
| `CSB_AZURE_VERSION` | `submodules/csb-brokerpak-azure/manifest.yml` | `0.1.0`  |
| `PROWLER_VERSION`   | `submodules/prowler/pyproject.toml`           | `5.23.0` |

## Conditional Deploy Rules

Each deploy job runs only when its submodule or related scripts **change** (GitLab `changes:` key).
`deploy-azure` is additionally gated by `DEPLOY_AZURE == "true"` until Azure credentials are provisioned.

## Required GitLab CI/CD Variables

Set in GitLab project **Settings → CI/CD → Variables**. Mark all credential variables **Masked**.

| Variable                           | Type     | Notes                                |
| ---------------------------------- | -------- | ------------------------------------ |
| `CF_API`                           | env      | `https://api.fr.cloud.gov`           |
| `CF_ORG`                           | env      | `gsa-tts-iae-lava-beds`              |
| `CF_SPACE`                         | env      | `dev`                                |
| `CF_USERNAME`                      | env      | CF service account                   |
| `CF_PASSWORD`                      | env      | masked                               |
| `AWS_ACCESS_KEY_ID`                | env      | masked                               |
| `AWS_SECRET_ACCESS_KEY`            | env      | masked                               |
| `AWS_PAS_VPC_ID`                   | env      | masked                               |
| `CSB_AWS_SECURITY_USER_NAME`       | env      |                                      |
| `CSB_AWS_SECURITY_USER_PASSWORD`   | env      | masked                               |
| `GOOGLE_CREDENTIALS`               | **file** | SA JSON; use "file" type in GitLab   |
| `GOOGLE_PROJECT`                   | env      |                                      |
| `CSB_GCP_SECURITY_USER_NAME`       | env      |                                      |
| `CSB_GCP_SECURITY_USER_PASSWORD`   | env      | masked                               |
| `ARM_TENANT_ID`                    | env      | masked                               |
| `ARM_SUBSCRIPTION_ID`              | env      | masked                               |
| `ARM_CLIENT_ID`                    | env      | masked                               |
| `ARM_CLIENT_SECRET`                | env      | masked                               |
| `CSB_AZURE_SECURITY_USER_NAME`     | env      |                                      |
| `CSB_AZURE_SECURITY_USER_PASSWORD` | env      | masked                               |
| `PROWLER_AWS_ACCESS_KEY_ID`        | env      | read-only IAM key; masked            |
| `PROWLER_AWS_SECRET_ACCESS_KEY`    | env      | masked                               |
| `DEPLOY_AZURE`                     | env      | set `true` when Azure SP provisioned |

## Required GitHub Secrets

Set in GitHub **Settings → Secrets and variables → Actions**:

| Secret                          | Value                                          |
| ------------------------------- | ---------------------------------------------- |
| `GITLAB_PROJECT_ID`             | numeric project id (GitLab Settings → General) |
| `GITLAB_PIPELINE_TRIGGER_TOKEN` | GitLab Settings → CI/CD → Pipeline triggers    |
| `GITLAB_API_URL`                | `https://gitlab.com` or self-hosted URL        |
| `GITLAB_REF`                    | target branch in GitLab (default: `main`)      |

## Prowler Scheduled Scans

Create a GitLab scheduled pipeline (**CI/CD → Schedules**):

- Cron: `0 2 * * *` (2 AM UTC nightly)
- Branch: `main`
- No variables needed beyond those already set

To run Prowler ad hoc from any pipeline: set `RUN_PROWLER=true` as a variable on manual trigger.

## Adding a New Brokerpak Version

1. Update the submodule pointer: `git -C submodules/csb-brokerpak-<name> checkout <new-commit>`
2. Update `CSB_<NAME>_VERSION` in `.gitlab-ci.yml` to match `manifest.yml`
3. Commit and push to `main` → pipeline auto-triggers on changes to `submodules/<name>/**/*`

## TODO Placeholders

The pipeline has TODO comments where platform-specific details are needed:

- `# TODO: pin to a specific digest` — lock runner image SHA for reproducibility
- `# TODO: install Go 1.22+ and make` — deploy jobs need a custom image with CF CLI + Go + make
- `# TODO: upload results to $PROWLER_RESULTS_BUCKET` — Prowler output → S3 + OSCAL update
- `# TODO: enable once ARM_* variables are provisioned` — Azure job gated by `DEPLOY_AZURE=true`
