# Imported Backstage Examples

This directory preserves Backstage catalog and scaffolder examples cherry-picked from internal platform repositories before removing the local checked-out source trees.

- `catalog-internal-tools/` contains internal workflow templates and the starter example from `catalog-internal-tools-main`.
- `iac-official/` contains AWS IaC and service-catalog scaffolder template descriptors plus rendered resource catalog examples from `iac-official-main`.
- `../apis/tenant-portal/` contains a catalog API example derived from the tenant portal backend OpenAPI specification.

Some imported templates reference custom field extensions or actions such as `http:backstage:request`, `github:issues:create`, `github:actions:dispatch`, `GitOrgPicker`, `S3BucketNameField`, and JSON import fields. They are intentionally preserved as examples; wire those extensions into a Backstage instance before executing the affected templates.