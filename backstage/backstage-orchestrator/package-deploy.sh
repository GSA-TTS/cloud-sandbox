#!/bin/bash
set -euo pipefail

echo "==> Preparing deploy-workspace..."
rm -rf deploy-workspace
mkdir -p deploy-workspace

echo "==> Extracting production bundle..."
tar -xzf packages/backend/dist/bundle.tar.gz -C deploy-workspace

echo "==> Copying deployment configurations..."
cp vcap-env.js deploy-workspace/
cp app-config.yaml deploy-workspace/
cp app-config.production.yaml deploy-workspace/

echo "==> Removing devDependencies from root package.json to prevent CF staging bloat..."
# Use node to strip devDependencies and explicitly remove the postinstall hook entirely
# We also wipe any scripts that might attempt to trigger builds during CF staging
node -e "
  const fs = require('fs');
  const path = './deploy-workspace/package.json';
  const pkg = JSON.parse(fs.readFileSync(path));
  delete pkg.devDependencies;

  if (pkg.scripts) {
    delete pkg.scripts.postinstall;
    delete pkg.scripts.build;
    delete pkg.scripts['build:all'];
    delete pkg.scripts['build:backend'];
    delete pkg.scripts.tsc;
  }

  fs.writeFileSync(path, JSON.stringify(pkg, null, 2));
"

echo "==> Deploy workspace is ready."
