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

    // Locate the specific backstage-db service
    const allServices = Object.values(vcapServices).flat();
    const dbService = allServices.find(s => s.name === 'backstage-db');
    const ssoService = allServices.find(s => s.name === 'backstage-sso');

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

      console.log(
        '------------------------------------------------------------',
      );
      console.log(
        '[cloud.gov VCAP_SERVICES] Successfully bound RDS credentials:',
      );
      console.log(`- Database Host: ${process.env.POSTGRES_HOST}`);
      console.log(`- Database Port: ${process.env.POSTGRES_PORT}`);
      console.log(`- Database User: ${process.env.POSTGRES_USER}`);
      console.log(`- Database Name: ${process.env.POSTGRES_DB}`);
      console.log(
        '------------------------------------------------------------',
      );
    } else {
      console.warn(
        '[cloud.gov VCAP_SERVICES] No postgres or aws-rds bindings found. Relying on local env vars.',
      );
    }

    if (!process.env.BACKSTAGE_SESSION_SECRET) {
      const secretMaterial = [
        ssoService?.credentials?.client_secret,
        dbService?.credentials?.password,
      ]
        .filter(Boolean)
        .join(':');

      if (secretMaterial) {
        process.env.BACKSTAGE_SESSION_SECRET = crypto
          .createHash('sha256')
          .update(`backstage-session:${secretMaterial}`)
          .digest('hex');
        console.log(
          '[cloud.gov VCAP_SERVICES] Derived Backstage session secret from bound service credentials.',
        );
      } else {
        console.warn(
          '[cloud.gov VCAP_SERVICES] Unable to derive BACKSTAGE_SESSION_SECRET; OIDC login may fail.',
        );
      }
    }
  } else {
    console.log(
      '[cloud.gov VCAP_SERVICES] VCAP_SERVICES is not defined. Skipping Cloud Foundry binding.',
    );
  }
} catch (error) {
  console.error(
    '[cloud.gov VCAP_SERVICES] Error parsing VCAP_SERVICES:',
    error.message,
  );
}
