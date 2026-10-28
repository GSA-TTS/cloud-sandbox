import { execFileSync } from "node:child_process";
import { mkdirSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { createHash } from "node:crypto";

export const coreRevision = "1a127cf611d10aaf40a1f0e36fdc77172d5da564";
const directory = fileURLToPath(new URL("./.cache/", import.meta.url));
mkdirSync(directory, { recursive: true });
const manifest = { repository: "GSA-TTS/oscal-vault-core", revision: coreRevision, schemas: {} };
for (const model of ["component", "ssp"]) {
  const path = `compliance/schemas/oscal-1.1.3/oscal_${model}_schema.json`;
  const result = JSON.parse(
    execFileSync(
      "gh",
      ["api", `repos/GSA-TTS/oscal-vault-core/contents/${path}?ref=${coreRevision}`],
      { encoding: "utf8", timeout: 30000, maxBuffer: 4 * 1024 * 1024 },
    ),
  );
  if (result.encoding !== "base64" || typeof result.content !== "string") {
    throw new Error("Unexpected GitHub schema response");
  }
  const bytes = Buffer.from(result.content.replace(/\s/g, ""), "base64");
  const schema = JSON.parse(bytes.toString("utf8"));
  if (!schema.definitions || !schema.required) throw new Error("Invalid schema document");
  writeFileSync(`${directory}/${model}.json`, bytes);
  manifest.schemas[model] = createHash("sha256").update(bytes).digest("hex");
}
writeFileSync(`${directory}/manifest.json`, JSON.stringify(manifest, null, 2));
console.log(
  "PASS: cached official OSCAL 1.1.3 schemas at pinned core revision; no packages installed.",
);
