import { mkdirSync, writeFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { documents } from "./model.mjs";
import { planFixtures, registry } from "./fixtures/documents.mjs";
const root = new URL("./.cache/demo/", import.meta.url);
mkdirSync(root, { recursive: true });
const manifest = {
  version: 1,
  synthetic: true,
  documents: {},
  plans: Object.values(planFixtures).map(({ mapping }) => {
    const { instances, ...plan } = mapping;
    return plan;
  }),
  instances: registry.instances.map((i) => ({ ...i, plan: registry.plan })),
};
for (const [name, document] of Object.entries(documents)) {
  const bytes = JSON.stringify(document, null, 2);
  writeFileSync(new URL(`${name}.json`, root), bytes);
  manifest.documents[name] = {
    path: `${name}.json`,
    sha256: createHash("sha256").update(bytes).digest("hex"),
  };
}
writeFileSync(new URL("manifest.json", root), JSON.stringify(manifest, null, 2));
console.log(
  "Exported synthetic OSCAL documents and digest-bound manifest to poc/oscal-crm/.cache/demo/",
);
