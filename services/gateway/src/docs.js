// Merges the per-service OpenAPI specs (each service documents its own
// endpoints) into one combined spec for Swagger UI, so the Gateway serves a
// single /docs page covering everything reachable through it.

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

function loadSpec(filename) {
  return yaml.load(fs.readFileSync(path.join(__dirname, '..', 'openapi', filename), 'utf8'));
}

function loadCombinedSpec() {
  const authSpec = loadSpec('auth-service.yaml');
  const inventorySpec = loadSpec('inventory-service.yaml');

  return {
    openapi: '3.0.3',
    info: {
      title: 'SmartStock API (via Gateway)',
      version: '1.0.0',
      description: 'Combined documentation for every endpoint reachable through the SmartStock API Gateway.',
    },
    servers: authSpec.servers,
    tags: [...(authSpec.tags || []), ...(inventorySpec.tags || [])],
    paths: { ...authSpec.paths, ...inventorySpec.paths },
    components: {
      securitySchemes: {
        ...(authSpec.components?.securitySchemes || {}),
        ...(inventorySpec.components?.securitySchemes || {}),
      },
      schemas: {
        ...(authSpec.components?.schemas || {}),
        ...(inventorySpec.components?.schemas || {}),
      },
    },
  };
}

module.exports = { loadCombinedSpec };
