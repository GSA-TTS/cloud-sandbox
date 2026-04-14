# Service Approval Extraction Summary

Generated 2026-04-14 to preserve high-value information before source file removal/archival.

## Extraction Coverage

| Cloud | Source format | Parsed count | Approved | Denied | Output review | Output conditions |
|---|---|---:|---:|---:|---|---|
| Azure | Spreadsheet CSV | 190 | 71 | 119 | [docs/azure/service-approval-review.md](azure/service-approval-review.md) | [docs/azure/approved-service-conditions.md](azure/approved-service-conditions.md) |
| GCP | Spreadsheet CSV | 151 | 85 | 66 | [docs/gcp/service-approval-review.md](gcp/service-approval-review.md) | [docs/gcp/approved-service-conditions.md](gcp/approved-service-conditions.md) |
| AWS | Markdown review files | 37 | 18 | 19 | [docs/aws/service-approval-review.md](aws/service-approval-review.md) | [docs/aws/approved-service-conditions.md](aws/approved-service-conditions.md) |

## Valuable Dimensions Preserved

- Spreadsheet-derived: service category/type, short/full descriptions, in-house approval status, PCI field, and justification notes.
- AWS markdown-derived: FedRAMP status line, caveat/table/url presence indicators, and source-file traceability.
- Platform alignment: current CSB broker support and OpenTofu implementation feasibility.

## Suggested Improvements / Additional Dimensions

1. Normalize approval taxonomy to: `Approved`, `Approved with Caveats`, `Pending Review`, `Denied`.
2. Add `Environment Scope` dimension (`Commercial`, `GovCloud`, both) parsed from status text.
3. Add `Data Sensitivity` and `Business Owner` fields for RMF/ATO integration decisions.
4. Add `Evidence Link` to decision ticket/memo IDs beyond service overview docs.
5. Add `Broker Gap Type`: `Not implemented`, `Stub plan`, `Denied policy`, `Pending approval`.
6. Add governance metadata: `last-reviewed-date`, `reviewer`, `decision-id`, and `expiry/re-review-date`.

## Data Quality Notes

- Legacy AWS documents sometimes include both recommendation text and not-approved status; denied classification was kept conservative in those cases.
- Duplicate AWS Aurora source docs are preserved for provenance.
- GCP status strings contain minor spelling variants and were normalized during classification.
