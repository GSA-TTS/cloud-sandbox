#!/usr/bin/env node

import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
import { readFile } from 'node:fs/promises';
import { basename, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import Ajv from 'ajv';
import addFormats from 'ajv-formats';

const require = createRequire(import.meta.url);
const yaml = require('js-yaml');

const scriptDirectory = fileURLToPath(new URL('.', import.meta.url));
const schemaDirectory = resolve(scriptDirectory, '../schemas');

function usage() {
  console.error(
    'Usage: validate.mjs <protocol.yaml> <toolchain.lock.yaml> <observations.ndjson>'
  );
}

function reportSchemaErrors(label, errors) {
  for (const error of errors ?? []) {
    const location = error.instancePath || '/';
    console.error(`${label}${location}: ${error.message}`);
  }
}

async function loadYaml(path) {
  const source = await readFile(path, 'utf8');
  const value = yaml.load(source, { json: true });
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error(`${path}: expected a YAML object`);
  }
  return { source, value };
}

async function loadSchema(name) {
  return JSON.parse(await readFile(resolve(schemaDirectory, name), 'utf8'));
}

function validateCrossFile(protocol, toolchain, observations, protocolDigest) {
  const errors = [];
  const toolByName = new Map();

  for (const tool of toolchain.tools) {
    if (toolByName.has(tool.name)) {
      errors.push(
        `toolchain: duplicate tool name ${JSON.stringify(tool.name)}`
      );
    }
    toolByName.set(tool.name, tool);
  }

  if (protocol.seeds.length !== protocol.repetitions) {
    errors.push(
      'protocol: seeds must contain exactly one value per repetition'
    );
  }

  const serviceByProvider = {
    aws: 'eks',
    gcp: 'gke-standard',
    azure: 'aks',
  };

  observations.forEach(({ line, value: observation }) => {
    const label = `observations.ndjson:${line}`;
    if (!protocol.providers.includes(observation.provider)) {
      errors.push(`${label}: provider is not enabled by protocol`);
    }
    if (observation.service !== serviceByProvider[observation.provider]) {
      errors.push(`${label}: service does not match provider`);
    }
    if (observation.cluster_profile !== protocol.cluster_profile) {
      errors.push(`${label}: cluster_profile does not match protocol`);
    }
    if (!protocol.workloads.includes(observation.workload)) {
      errors.push(`${label}: workload is not enabled by protocol`);
    }
    if (observation.repetition > protocol.repetitions) {
      errors.push(`${label}: repetition exceeds protocol repetitions`);
    } else if (
      observation.seed !== protocol.seeds[observation.repetition - 1]
    ) {
      errors.push(`${label}: seed does not match the protocol repetition`);
    }
    if (
      !observation.kubernetes_version.startsWith(
        `${protocol.kubernetes_minor}.`
      )
    ) {
      errors.push(`${label}: kubernetes_version does not match protocol minor`);
    }
    if (observation.protocol_digest !== protocolDigest) {
      errors.push(`${label}: protocol_digest does not match the protocol file`);
    }
    if (
      Date.parse(observation.window_end) <= Date.parse(observation.window_start)
    ) {
      errors.push(`${label}: window_end must be later than window_start`);
    }

    const lockedTool = toolByName.get(observation.tool.name);
    if (!lockedTool) {
      errors.push(`${label}: tool is absent from toolchain lock`);
    } else if (
      lockedTool.version !== observation.tool.version ||
      lockedTool.sha256 !== observation.tool.sha256
    ) {
      errors.push(
        `${label}: tool version or checksum does not match toolchain lock`
      );
    }
  });

  return errors;
}

async function main() {
  if (process.argv.length !== 5) {
    usage();
    process.exitCode = 2;
    return;
  }

  const [protocolPath, toolchainPath, observationsPath] = process.argv
    .slice(2)
    .map((path) => resolve(path));
  const [
    protocolDocument,
    toolchainDocument,
    observationSource,
    protocolSchema,
    toolchainSchema,
    observationSchema,
  ] = await Promise.all([
    loadYaml(protocolPath),
    loadYaml(toolchainPath),
    readFile(observationsPath, 'utf8'),
    loadSchema('protocol.schema.json'),
    loadSchema('toolchain-lock.schema.json'),
    loadSchema('observation.schema.json'),
  ]);

  const ajv = new Ajv({ allErrors: true, strict: true });
  addFormats(ajv);
  const validateProtocol = ajv.compile(protocolSchema);
  const validateToolchain = ajv.compile(toolchainSchema);
  const validateObservation = ajv.compile(observationSchema);
  let valid = true;

  if (!validateProtocol(protocolDocument.value)) {
    valid = false;
    reportSchemaErrors(basename(protocolPath), validateProtocol.errors);
  }
  if (!validateToolchain(toolchainDocument.value)) {
    valid = false;
    reportSchemaErrors(basename(toolchainPath), validateToolchain.errors);
  }

  const observations = [];
  for (const [index, rawLine] of observationSource.split(/\r?\n/).entries()) {
    if (!rawLine.trim()) continue;
    try {
      const value = JSON.parse(rawLine);
      observations.push({ line: index + 1, value });
      if (!validateObservation(value)) {
        valid = false;
        reportSchemaErrors(
          `observations.ndjson:${index + 1}`,
          validateObservation.errors
        );
      }
    } catch (error) {
      valid = false;
      console.error(
        `observations.ndjson:${index + 1}: invalid JSON: ${error.message}`
      );
    }
  }

  if (observations.length === 0) {
    valid = false;
    console.error('observations.ndjson: expected at least one observation');
  }

  if (valid) {
    const protocolDigest = `sha256:${createHash('sha256')
      .update(protocolDocument.source)
      .digest('hex')}`;
    const crossFileErrors = validateCrossFile(
      protocolDocument.value,
      toolchainDocument.value,
      observations,
      protocolDigest
    );
    if (crossFileErrors.length > 0) {
      valid = false;
      crossFileErrors.forEach((error) => console.error(error));
    }
  }

  if (!valid) {
    process.exitCode = 1;
    return;
  }

  console.log(
    `Validated ${observations.length} observation(s), protocol, and toolchain lock.`
  );
}

main().catch((error) => {
  console.error(`benchmark validation failed: ${error.message}`);
  process.exitCode = 1;
});
