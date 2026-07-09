/**
 * vcap-env.js
 *
 * Utility script for Cloud Foundry / cloud.gov deployments.
 * This script is pre-loaded via Node.js CLI `-r ./vcap-env.js` before booting Backstage.
 * It parses the VCAP_SERVICES environment variable to extract AWS RDS (PostgreSQL)
 * connection credentials and binds them to standard Backstage PostgreSQL environment variables.
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Symlink repair for @backstage/plugin-app-backend on cloud.gov
// Cloud Foundry tar-based droplets can sometimes lose intra-workspace symlinks created by Yarn.
try {
  const nodeModulesAppPath = path.resolve(__dirname, 'node_modules/app');
  const packagesAppPath = path.resolve(__dirname, 'packages/app');
  if (!fs.existsSync(nodeModulesAppPath) && fs.existsSync(packagesAppPath)) {
    console.log(
      '[cloud.gov VCAP_SERVICES] Repairing app package symlink for plugin-app-backend...',
    );
    fs.symlinkSync(packagesAppPath, nodeModulesAppPath, 'dir');
  }
} catch (e) {
  console.warn(
    '[cloud.gov VCAP_SERVICES] Failed to repair app symlink:',
    e.message,
  );
}

try {
  if (process.env.VCAP_SERVICES) {
    const vcapServices = JSON.parse(process.env.VCAP_SERVICES);

    const allServices = Object.values(vcapServices).flat();
    const dbServiceName = process.env.BACKSTAGE_DB_SERVICE_NAME;
    const ssoServiceName = process.env.BACKSTAGE_SSO_SERVICE_NAME;
    const dbService = allServices.find(s =>
      dbServiceName
        ? s.name === dbServiceName
        : s.label === 'aws-rds' || s.offering_name === 'aws-rds',
    );
    const ssoService = allServices.find(s =>
      ssoServiceName
        ? s.name === ssoServiceName
        : s.label === 'cloud-gov-identity-provider' ||
          s.offering_name === 'cloud-gov-identity-provider',
    );

    if (ssoService) {
      const ssoCredentials = ssoService.credentials || {};
      if (ssoCredentials.client_id && ssoCredentials.client_secret) {
        process.env.CLOUDGOV_CLIENT_ID = ssoCredentials.client_id;
        process.env.CLOUDGOV_CLIENT_SECRET = ssoCredentials.client_secret;
        console.log(
          '[cloud.gov VCAP_SERVICES] Successfully bound cloud.gov identity provider credentials.',
        );
      } else {
        console.warn(
          '[cloud.gov VCAP_SERVICES] SSO credentials missing client_id or client_secret.',
        );
      }
    } else {
      console.warn(
        '[cloud.gov VCAP_SERVICES] No cloud.gov identity provider bindings found. SSO login may fail.',
      );
    }

    if (dbService) {
      const credentials = dbService.credentials || {};

      const host = credentials.host || credentials.hostname;
      const port = String(credentials.port || '5432');
      const user = credentials.username || credentials.user;
      const password = credentials.password;
      const db = credentials.db_name || credentials.name;

      if (!host || !user || !password || !db) {
        console.error(
          '[cloud.gov VCAP_SERVICES] Database credentials missing required fields. Exiting.',
        );
        process.exit(1);
      }

      // Inject credentials as environment variables expected by app-config.production.yaml
      process.env.POSTGRES_HOST = host;
      process.env.POSTGRES_PORT = port;
      process.env.POSTGRES_USER = user;
      process.env.POSTGRES_PASSWORD = password;
      process.env.POSTGRES_DB = db;

      console.log('[cloud.gov VCAP_SERVICES] Successfully loaded RDS credentials.');
    } else {
      console.warn(
        '[cloud.gov VCAP_SERVICES] No postgres or aws-rds bindings found. Relying on local env vars.',
      );
    }

    const secretMaterial = [
      ssoService?.credentials?.client_secret,
      dbService?.credentials?.password,
    ]
      .filter(Boolean)
      .join(':');

    ensureSessionSecret(secretMaterial);
  } else {
    console.log(
      '[cloud.gov VCAP_SERVICES] VCAP_SERVICES is not defined. Skipping Cloud Foundry binding.',
    );
    ensureSessionSecret();
  }
} catch (error) {
  console.error(
    '[cloud.gov VCAP_SERVICES] Error parsing VCAP_SERVICES:',
    error.message,
  );
  ensureSessionSecret();
}

function ensureSessionSecret(secretMaterial) {
  if (process.env.BACKSTAGE_SESSION_SECRET) {
    return;
  }

  if (secretMaterial) {
    process.env.BACKSTAGE_SESSION_SECRET = crypto
      .createHash('sha256')
      .update(`backstage-session:${secretMaterial}`)
      .digest('hex');
    console.log(
      '[cloud.gov VCAP_SERVICES] Derived Backstage session secret from bound service credentials.',
    );
    return;
  }

  process.env.BACKSTAGE_SESSION_SECRET = crypto.randomBytes(32).toString('hex');
  console.warn(
    '[cloud.gov VCAP_SERVICES] BACKSTAGE_SESSION_SECRET was not set and no binding material was available; generated an ephemeral session secret.',
  );
}
