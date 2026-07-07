#!/bin/bash
set -euo pipefail

echo "Extracting Backstage production bundle..."
tar -xzf packages/backend/dist/bundle.tar.gz

echo "Starting Backstage Backend with VCAP_SERVICES bindings..."
exec node -r ./vcap-env.js packages/backend --config app-config.yaml --config app-config.production.yaml
