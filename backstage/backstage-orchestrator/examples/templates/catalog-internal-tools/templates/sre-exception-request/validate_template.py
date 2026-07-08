#!/usr/bin/env python3
"""
validate_template.py
--------------------
Cross-validates the sre-exception-request template.yaml against:
  1. exception-request-schema.json  — enum values and field types must match
  2. A test JSON document             — all JSON values must be in the template's enums

Usage:
  # Schema + template consistency check only:
  python3 validate_template.py

  # Include a JSON submission to validate values:
  python3 validate_template.py --json path/to/submission.json

Run this before every commit that touches template.yaml or exception-request-schema.json.
"""

import argparse
import json
import sys
from pathlib import Path

try:
    import yaml
except ModuleNotFoundError:
    sys.exit("PyYAML is required: pip install pyyaml")

# Fields whose template type intentionally differs from the JSON schema type.
# Reason: Backstage Scaffolder's RJSF does not reliably coerce values for
# custom ui:field extensions — using type:string avoids false validation errors.
# isPlatformBlocker: schema=boolean, template=string enum (Yes/No dropdown)
# currentScore / categoryAverage: schema=integer/number, template=string
TYPE_OVERRIDE_EXEMPTIONS = {'isPlatformBlocker', 'currentScore', 'categoryAverage'}

HERE = Path(__file__).parent
TEMPLATE_PATH = HERE / "template.yaml"
SCHEMA_PATH   = HERE / "exception-request-schema.json"

# Maps every form field key to its dot-path in the JSON document.
# Update this whenever a new field is added to the template.
JSONPATH_MAP: dict[str, tuple[str, str]] = {
    "hasHadAssessment":          ("preScreening",     "hasHadAssessment"),
    "assessmentTrack":           ("preScreening",     "assessmentTrack"),
    "isPlatformBlocker":         ("preScreening",     "isPlatformBlocker"),
    "submissionDate":            ("productDetails",   "submissionDate"),
    "productName":               ("productDetails",   "productName"),
    "teamOrganization":          ("productDetails",   "teamOrganization"),
    "experienceArea":            ("productDetails",   "experienceArea"),
    "techLeadName":              ("productDetails",   "techLeadName"),
    "primaryContactEmail":       ("productDetails",   "primaryContactEmail"),
    "portfolioLeadName":         ("productDetails",   "portfolioLeadName"),
    "portfolioLeadEmail":        ("productDetails",   "portfolioLeadEmail"),
    "priorAssessmentDate":       ("productDetails",   "priorAssessmentDate"),
    "criterionId":               ("criterion",        "criterionId"),
    "currentScore":              ("criterion",        "currentScore"),
    "categoryAverage":           ("criterion",        "categoryAverage"),
    "constraintType":            ("reasonAndImpact",  "constraintType"),
    "detailedExplanation":       ("reasonAndImpact",  "detailedExplanation"),
    "whatHaveYouTried":          ("reasonAndImpact",  "whatHaveYouTried"),
    "operationalRiskSeverity":   ("reasonAndImpact",  "operationalRiskSeverity"),
    "operationalRiskDescription":("reasonAndImpact",  "operationalRiskDescription"),
    "sreOperationalBurden":      ("reasonAndImpact",  "sreOperationalBurden"),
    "mitigationApproach":        ("mitigation",       "mitigationApproach"),
    "riskReductionDescription":  ("mitigation",       "riskReductionDescription"),
    "tenantImpact":              ("mitigation",       "tenantImpact"),
    "tenantImpactDescription":   ("mitigation",       "tenantImpactDescription"),
    "exceptionType":             ("remediationPlan",  "exceptionType"),
    "originalExceptionId":       ("remediationPlan",  "originalExceptionId"),
    "extensionProgressReport":   ("remediationPlan",  "extensionProgressReport"),
    "conditionalTriggerEvent":   ("remediationPlan",  "conditionalTriggerEvent"),
    "conditionalTriggerDate":    ("remediationPlan",  "conditionalTriggerDate"),
    "conditionalFallbackPlan":   ("remediationPlan",  "conditionalFallbackPlan"),
    "targetCompletionDate":      ("remediationPlan",  "targetCompletionDate"),
    "remediationTimeline":       ("remediationPlan",  "remediationTimeline"),
    "resourcesRequired":         ("remediationPlan",  "resourcesRequired"),
    "externalDependencies":      ("remediationPlan",  "externalDependencies"),
    "successCriteria":           ("remediationPlan",  "successCriteria"),
    "productOwnerName":          ("internalApprovals","productOwnerName"),
    "productOwnerEmail":         ("internalApprovals","productOwnerEmail"),
    "engManagerName":            ("internalApprovals","engManagerName"),
    "engManagerEmail":           ("internalApprovals","engManagerEmail"),
    "supportingDocLinks":        ("internalApprovals","supportingDocLinks"),
    "additionalContext":         ("internalApprovals","additionalContext"),
    "internalApprovalsConfirmed":("internalApprovals","internalApprovalsConfirmed"),
}


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate sre-exception-request template")
    parser.add_argument("--json", metavar="FILE", help="Optional JSON submission to validate")
    args = parser.parse_args()

    issues: list[str] = []

    # ── Load files ─────────────────────────────────────────────────────────────
    print(f"Loading {TEMPLATE_PATH.name} …")
    try:
        doc = yaml.safe_load(TEMPLATE_PATH.read_text())
    except yaml.YAMLError as exc:
        sys.exit(f"YAML parse error: {exc}")

    print(f"Loading {SCHEMA_PATH.name} …")
    schema = json.loads(SCHEMA_PATH.read_text())

    test_json: dict | None = None
    if args.json:
        print(f"Loading test JSON {args.json} …")
        test_json = json.loads(Path(args.json).read_text())

    print()

    # ── Build flat schema field map ────────────────────────────────────────────
    schema_fields: dict[str, dict] = {}
    for section_def in schema["properties"].values():
        for field, fdef in section_def.get("properties", {}).items():
            schema_fields[field] = fdef

    # ── Iterate form steps ─────────────────────────────────────────────────────
    params: list[dict] = doc["spec"]["parameters"]
    ok = 0

    for step_idx, step in enumerate(params):
        if step_idx == 0:
            continue  # Step 0 is the JSON import field — skip

        for field_key, tpl in step.get("properties", {}).items():
            if not isinstance(tpl, dict):
                continue
            scm = schema_fields.get(field_key, {})

            tpl_type  = tpl.get("type")
            tpl_enum  = tpl.get("enum")
            scm_type  = scm.get("type")
            scm_enum  = scm.get("enum")
            ui_field  = tpl.get("ui:field")
            json_path = (tpl.get("ui:options") or {}).get("jsonPath", "")

            # ── Check 1: annotation present ──────────────────────────────────
            if ui_field != "JsonPopulatedField":
                issues.append(f"[MISSING ANNOTATION] Step {step_idx} {field_key}: ui:field='{ui_field}'")
                continue

            if not json_path:
                issues.append(f"[MISSING jsonPath]    Step {step_idx} {field_key}: no ui:options.jsonPath")
                continue

            # ── Check 2: template↔schema enum parity ─────────────────────────
            if tpl_enum and scm_enum:
                tpl_set = {str(e) for e in tpl_enum}
                scm_set = {str(e) for e in scm_enum}
                for v in sorted(tpl_set - scm_set):
                    issues.append(f"[ENUM template∉schema] {field_key}: '{v}'")
                for v in sorted(scm_set - tpl_set):
                    issues.append(f"[ENUM schema∉template] {field_key}: '{v}'")

            # ── Check 3: template↔schema type compatibility ───────────────────
            if tpl_type and scm_type and field_key not in TYPE_OVERRIDE_EXEMPTIONS:
                scm_main = {t for t in (scm_type if isinstance(scm_type, list) else [scm_type]) if t != "null"}
                tpl_main = {t for t in (tpl_type if isinstance(tpl_type, list) else [tpl_type]) if t != "null"}
                if scm_main and tpl_main and scm_main != tpl_main:
                    issues.append(f"[TYPE MISMATCH]        {field_key}: template={tpl_type} schema={scm_type}")

            # ── Check 4: boolean field must not carry enum list ───────────────
            if tpl_type == "boolean" and tpl_enum:
                issues.append(f"[BOOL WITH ENUM]       {field_key}: type=boolean but has enum — remove enum")

            # ── Check 5: JSON submission value against template enum ──────────
            if test_json and tpl_enum:
                path = JSONPATH_MAP.get(field_key)
                if path:
                    section, key = path
                    json_val = test_json.get(section, {}).get(key)
                    if json_val is not None and not isinstance(json_val, bool):
                        if str(json_val) not in {str(e) for e in tpl_enum}:
                            issues.append(
                                f"[JSON VALUE∉ENUM]      {field_key}: '{json_val}' not in template enum"
                            )

            ok += 1

    # ── Summary ────────────────────────────────────────────────────────────────
    if issues:
        print(f"FOUND {len(issues)} ISSUE(S):\n")
        for issue in issues:
            print(f"  ❌  {issue}")
        print(f"\nTotal OK: {ok}  |  Issues: {len(issues)}")
        sys.exit(1)
    else:
        print(f"✅  All {ok} fields passed — template, schema, and JSON are consistent.")


if __name__ == "__main__":
    main()
