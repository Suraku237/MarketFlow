// Merges the per-service OpenAPI specs (each service documents its own
// endpoints) into one combined spec for Swagger UI, so the Gateway serves a
// single /docs page covering everything reachable through it.

const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');

const SPEC_FILES = ['auth-service.yaml', 'academic-service.yaml', 'finance-service.yaml'];

function loadSpec(filename) {
  return yaml.load(fs.readFileSync(path.join(__dirname, '..', 'openapi', filename), 'utf8'));
}

function loadCombinedSpec() {
  const specs = SPEC_FILES.map(loadSpec);

  return {
    openapi: '3.0.3',
    info: {
      title: 'SmartSchool API (via Gateway)',
      version: '1.0.0',
      description: 'Combined documentation for every endpoint reachable through the SmartSchool API Gateway.',
    },
    servers: specs[0].servers,
    tags: specs.flatMap((spec) => spec.tags || []),
    paths: Object.assign({}, ...specs.map((spec) => spec.paths || {})),
    components: {
      securitySchemes: Object.assign({}, ...specs.map((spec) => spec.components?.securitySchemes || {})),
      schemas: Object.assign({}, ...specs.map((spec) => spec.components?.schemas || {})),
    },
  };
}

module.exports = { loadCombinedSpec };
