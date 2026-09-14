#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";

const [authFile, modelsFile, settingsFile, modelsPatchFile, ...authPatchFiles] = process.argv.slice(2);

if (!authFile || !modelsFile || !settingsFile || !modelsPatchFile) {
  console.error("Usage: sync-pi-broker-config.mjs <auth.json> <models.json> <settings.json> <models-patch.json> [auth-patch...]");
  process.exit(1);
}

function readJson(file, fallback) {
  if (!fs.existsSync(file)) {
    return fallback;
  }

  const raw = fs.readFileSync(file, "utf8").trim();
  if (!raw) {
    return fallback;
  }

  try {
    return JSON.parse(raw);
  } catch (error) {
    throw new Error(`${file} is not valid JSON: ${error.message}`);
  }
}

function writeJson(file, value) {
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, `${JSON.stringify(value, null, 2)}\n`, { mode: 0o600 });
  fs.chmodSync(file, 0o600);
}

const auth = readJson(authFile, {});
const models = readJson(modelsFile, {});
const settings = readJson(settingsFile, {});
const modelsPatch = readJson(modelsPatchFile, { providers: {} });

// Bedrock IAM and Vertex service-account credentials must come from env vars.
// Pi auth.json entries for these built-ins are interpreted as API-key auth.
delete auth["amazon-bedrock"];
delete auth["google-vertex"];

for (const authPatchFile of authPatchFiles) {
  const patch = readJson(authPatchFile, {});
  for (const [provider, value] of Object.entries(patch)) {
    auth[provider] = value;
  }
}

models.providers = models.providers || {};
for (const [provider, value] of Object.entries(modelsPatch.providers || {})) {
  const current = models.providers[provider] || {};
  models.providers[provider] = {
    ...current,
    ...value,
  };

  if (current.modelOverrides && !value.modelOverrides) {
    models.providers[provider].modelOverrides = current.modelOverrides;
  }
}

const enabledModels = [];
for (const [provider, value] of Object.entries(modelsPatch.providers || {})) {
  for (const model of value.models || []) {
    if (model?.id) {
      enabledModels.push(`${provider}/${model.id}`);
    }
  }
}
settings.enabledModels = enabledModels;

writeJson(authFile, auth);
writeJson(modelsFile, models);
writeJson(settingsFile, settings);

console.log(JSON.stringify({
  authProvidersUpdated: authPatchFiles.length,
  modelProvidersUpdated: Object.keys(modelsPatch.providers || {}).length,
  enabledModels: enabledModels.length,
}, null, 2));
