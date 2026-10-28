import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
const cwd = fileURLToPath(new URL("./", import.meta.url));
const root = fileURLToPath(new URL("../../", import.meta.url));
execFileSync(
  `${root}/node_modules/.bin/oxfmt`,
  ["--check", "poc/oscal-crm", "docs/adr/0006-use-native-oscal-for-crm-api-prototype.md"],
  { cwd: root, stdio: "inherit" },
);
execFileSync(
  "gitleaks",
  ["dir", "poc/oscal-crm", "--redact", "--no-banner", "--config", ".gitleaks.toml"],
  { cwd: root, stdio: "inherit" },
);
execFileSync(
  "gitleaks",
  [
    "dir",
    "docs/adr/0006-use-native-oscal-for-crm-api-prototype.md",
    "--redact",
    "--no-banner",
    "--config",
    ".gitleaks.toml",
  ],
  { cwd: root, stdio: "inherit" },
);
for (const file of [
  "bootstrap.mjs",
  "model.mjs",
  "contract.mjs",
  "validate.mjs",
  "server.mjs",
  "proof.mjs",
  "verify.mjs",
  "fixtures/documents.mjs",
  "context.mjs",
  "export-demo.mjs",
  "viewer/app.mjs",
  "test/api.test.mjs",
  "test/context.test.mjs",
  "scheduler/contract-mock.mjs",
  "scheduler/adapter.mjs",
  "test/scheduler.test.mjs",
]) {
  execFileSync(process.execPath, ["--check", file], { cwd, stdio: "inherit" });
}
execFileSync(process.execPath, ["validate.mjs"], { cwd, stdio: "inherit" });
execFileSync(process.execPath, ["export-demo.mjs"], { cwd, stdio: "inherit" });
execFileSync(process.execPath, ["context.mjs", ".cache/demo/manifest.json"], {
  cwd,
  stdio: "inherit",
});
execFileSync(
  process.execPath,
  ["--test", "test/api.test.mjs", "test/context.test.mjs", "test/scheduler.test.mjs"],
  {
    cwd,
    stdio: "inherit",
  },
);
execFileSync(process.execPath, ["proof.mjs"], { cwd, stdio: "inherit" });
console.log(
  "PASS: formatting, secrets scan, syntax, official schemas, semantic checks, tests and live HTTP proof.",
);
