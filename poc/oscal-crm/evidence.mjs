import { createHash } from "node:crypto";

export const evaluatedAt = "2026-10-28T00:00:00Z";
export const maxAgeDays = 90;

const day = 24 * 60 * 60 * 1000;
const digest = (value) => createHash("sha256").update(JSON.stringify(value)).digest("hex");

export function observationView(crm, records, now = evaluatedAt) {
  const nowMs = Date.parse(now);
  const rows = crm.controls.map((row) => {
    const matches = records
      .filter((r) => r.control_id === row.control_id)
      .sort((a, b) => Date.parse(b.observed_at) - Date.parse(a.observed_at));
    const latest = matches[0];
    const ageDays = latest ? Math.floor((nowMs - Date.parse(latest.observed_at)) / day) : null;
    const evidence_state = !latest ? "missing" : ageDays > maxAgeDays ? "stale" : "current";
    const declared = row.implemented.declared_state;
    const comparison =
      declared === "implemented" && evidence_state !== "current"
        ? "declared-without-current-evidence"
        : evidence_state === "current"
          ? "declared-with-current-observation"
          : "declared-only";
    return {
      control_id: row.control_id,
      statement_id: row.statement_id,
      declared_state: declared,
      claim_basis: row.implemented.claim_basis,
      evidence_state,
      observed_at: latest?.observed_at ?? null,
      age_days: ageDays,
      observation_source: latest?.source ?? null,
      comparison,
      assessment_state: "not-assessed",
    };
  });
  const body = {
    profile: "urn:cloud-sandbox:poc:crm:1",
    profile_version: "0.1.0",
    offering_id: crm.offering_id,
    plan_id: crm.plan_id,
    evaluated_at: now,
    max_age_days: maxAgeDays,
    source_digest: digest(crm.source_documents),
    interpretation:
      "Observations are operator-entered synthetic records. A current observation does not establish implementation or assessment; assessment_state stays not-assessed.",
    controls: rows,
  };
  return { ...body, view_digest: digest(body) };
}
