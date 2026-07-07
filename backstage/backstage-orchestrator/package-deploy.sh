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
# Use node to aggressively strip dependencies and break the workspace link
node -e "
  const fs = require('fs');

  // 1. Strip root package.json
  const rootPath = './deploy-workspace/package.json';
  const rootPkg = JSON.parse(fs.readFileSync(rootPath));
  delete rootPkg.devDependencies;

  if (rootPkg.scripts) {
    delete rootPkg.scripts.postinstall;
    delete rootPkg.scripts.build;
    delete rootPkg.scripts['build:all'];
    delete rootPkg.scripts['build:backend'];
    delete rootPkg.scripts.tsc;
  }
  fs.writeFileSync(rootPath, JSON.stringify(rootPkg, null, 2));

  // 2. Strip frontend package.json of all dependencies so Yarn staging installs 0 bytes for it
  const appPath = './deploy-workspace/packages/app/package.json';
  if (fs.existsSync(appPath)) {
    const appPkg = JSON.parse(fs.readFileSync(appPath));
    delete appPkg.dependencies;
    delete appPkg.devDependencies;
    fs.writeFileSync(appPath, JSON.stringify(appPkg, null, 2));
  }

  // 3. Strip backend package.json of devDependencies and local app dependency
  const backendPath = './deploy-workspace/packages/backend/package.json';
  if (fs.existsSync(backendPath)) {
    const backendPkg = JSON.parse(fs.readFileSync(backendPath));
    delete backendPkg.devDependencies;
    if (backendPkg.dependencies && backendPkg.dependencies.app) {
      delete backendPkg.dependencies.app;
    }
    fs.writeFileSync(backendPath, JSON.stringify(backendPkg, null, 2));
  }
"

echo "==> Deploy workspace is ready."
