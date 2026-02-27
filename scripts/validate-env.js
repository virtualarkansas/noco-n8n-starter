/**
 * ============================================================
 * validate-env.js — Environment & Connectivity Validator
 * ============================================================
 *
 * Tests that your NocoDB and n8n services are reachable and that
 * your API tokens are valid.
 *
 * USAGE:
 *   # Load env vars first, then run:
 *   source .env && node scripts/validate-env.js
 *
 *   # Or use the npm script (which does the same thing):
 *   npm run validate
 *
 * WHAT IT CHECKS:
 *   1. NocoDB: GET /api/v3/meta/bases (if NOCODB_URL and NOCODB_API_TOKEN are set)
 *   2. n8n:    GET /api/v1/workflows?limit=1 (if N8N_URL and N8N_API_KEY are set)
 *
 * USES ONLY BUILT-IN NODE.JS MODULES — no npm dependencies needed.
 * ============================================================
 */

// Built-in Node.js modules for making HTTP requests
const http = require('http');
const https = require('https');
const { URL } = require('url');


// ============================================================
// CONFIGURATION — Read from environment variables
// ============================================================
// These should be set in your .env file and loaded via `source .env`
// before running this script.

const NOCODB_URL = process.env.NOCODB_URL;
const NOCODB_API_TOKEN = process.env.NOCODB_API_TOKEN;
const NOCODB_BASE_ID = process.env.NOCODB_BASE_ID;

const N8N_URL = process.env.N8N_URL;
const N8N_API_KEY = process.env.N8N_API_KEY;


// ============================================================
// UTILITY: Make an HTTP/HTTPS GET request
// ============================================================
// A simple Promise wrapper around Node.js built-in http/https modules.
// Returns the response status code and parsed JSON body.
//
// We use this instead of fetch() to avoid requiring Node 18+ or
// any external packages.

function httpGet(urlString, headers = {}) {
  return new Promise((resolve, reject) => {
    // Parse the URL to determine http vs https
    const parsedUrl = new URL(urlString);
    const client = parsedUrl.protocol === 'https:' ? https : http;

    const options = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port,
      path: parsedUrl.pathname + parsedUrl.search,
      method: 'GET',
      headers: {
        'Accept': 'application/json',
        ...headers,
      },
      // 10 second timeout
      timeout: 10000,
    };

    const req = client.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        let json = null;
        try {
          json = JSON.parse(data);
        } catch {
          // Response wasn't valid JSON — that's okay for some checks
        }

        resolve({
          statusCode: res.statusCode,
          body: json,
          raw: data,
        });
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timed out after 10 seconds'));
    });

    req.end();
  });
}


// ============================================================
// TEST: NocoDB Connectivity
// ============================================================

async function testNocoDB() {
  console.log('\n--- NocoDB ---');

  // Check if environment variables are set
  if (!NOCODB_URL) {
    console.log('⏭️  NOCODB_URL not set — skipping NocoDB check');
    return;
  }
  if (!NOCODB_API_TOKEN) {
    console.log('⏭️  NOCODB_API_TOKEN not set — skipping NocoDB check');
    return;
  }

  console.log(`   URL: ${NOCODB_URL}`);
  console.log(`   Token: ${'*'.repeat(8)}... (set)`);
  if (NOCODB_BASE_ID) {
    console.log(`   Base ID: ${NOCODB_BASE_ID}`);
  }

  try {
    // Test: List bases (the simplest authenticated endpoint)
    const url = `${NOCODB_URL}/api/v3/meta/bases`;
    const response = await httpGet(url, {
      'Authorization': `Bearer ${NOCODB_API_TOKEN}`,
    });

    if (response.statusCode === 200) {
      const bases = response.body?.list || [];
      console.log(`✅ NocoDB connection successful!`);
      console.log(`   Found ${bases.length} base(s)`);

      // List base names (helpful for finding your base ID)
      for (const base of bases) {
        const marker = base.id === NOCODB_BASE_ID ? ' ← current' : '';
        console.log(`   • ${base.title} (${base.id})${marker}`);
      }
    } else if (response.statusCode === 401) {
      console.log('❌ NocoDB authentication failed (401 Unauthorized)');
      console.log('   Your API token may be invalid or expired.');
      console.log('   Get a new one: Team & Settings → API Tokens');
    } else if (response.statusCode === 403) {
      console.log('❌ NocoDB access denied (403 Forbidden)');
      console.log('   Your token may not have permission for this endpoint.');
    } else {
      console.log(`❌ NocoDB returned HTTP ${response.statusCode}`);
      console.log(`   Response: ${response.raw.substring(0, 200)}`);
    }
  } catch (error) {
    console.log(`❌ NocoDB connection failed: ${error.message}`);
    if (error.code === 'ECONNREFUSED') {
      console.log('   The server is not running or the URL is wrong.');
    } else if (error.code === 'ENOTFOUND') {
      console.log('   The hostname could not be resolved. Check the URL.');
    }
  }
}


// ============================================================
// TEST: n8n Connectivity
// ============================================================

async function testN8n() {
  console.log('\n--- n8n ---');

  // Check if environment variables are set
  if (!N8N_URL) {
    console.log('⏭️  N8N_URL not set — skipping n8n check');
    return;
  }
  if (!N8N_API_KEY) {
    console.log('⏭️  N8N_API_KEY not set — skipping n8n check');
    return;
  }

  console.log(`   URL: ${N8N_URL}`);
  console.log(`   API Key: ${'*'.repeat(8)}... (set)`);

  try {
    // Test: List workflows with limit=1 (the simplest authenticated endpoint)
    const url = `${N8N_URL}/api/v1/workflows?limit=1`;
    const response = await httpGet(url, {
      'X-N8N-API-KEY': N8N_API_KEY,
    });

    if (response.statusCode === 200) {
      const workflows = response.body?.data || [];
      console.log(`✅ n8n connection successful!`);

      if (workflows.length > 0) {
        console.log(`   Found workflow(s). Most recent: "${workflows[0].name}"`);
        console.log(`   Active: ${workflows[0].active ? 'Yes' : 'No'}`);
      } else {
        console.log('   No workflows found yet (empty instance).');
      }
    } else if (response.statusCode === 401) {
      console.log('❌ n8n authentication failed (401 Unauthorized)');
      console.log('   Your API key may be invalid or revoked.');
      console.log('   Get a new one: Settings → n8n API → Create an API key');
    } else if (response.statusCode === 403) {
      console.log('❌ n8n access denied (403 Forbidden)');
      console.log('   The API may be disabled. Enable it in Settings → n8n API.');
    } else {
      console.log(`❌ n8n returned HTTP ${response.statusCode}`);
      console.log(`   Response: ${response.raw.substring(0, 200)}`);
    }
  } catch (error) {
    console.log(`❌ n8n connection failed: ${error.message}`);
    if (error.code === 'ECONNREFUSED') {
      console.log('   The server is not running or the URL is wrong.');
    } else if (error.code === 'ENOTFOUND') {
      console.log('   The hostname could not be resolved. Check the URL.');
    }
  }
}


// ============================================================
// MAIN — Run all tests
// ============================================================

async function main() {
  console.log('============================================');
  console.log(' NocoFlow Starter — Environment Validator');
  console.log('============================================');

  // Check if ANY env vars are set
  const hasAnyConfig = NOCODB_URL || NOCODB_API_TOKEN || N8N_URL || N8N_API_KEY;

  if (!hasAnyConfig) {
    console.log('\n⚠️  No environment variables found!');
    console.log('');
    console.log('   Make sure to load your .env file first:');
    console.log('     source .env && node scripts/validate-env.js');
    console.log('');
    console.log('   Or set up your environment:');
    console.log('     bash .claude/scripts/setup-env.sh <NOCODB_URL> <TOKEN> <BASE_ID> <N8N_URL> <API_KEY>');
    console.log('');
    process.exit(1);
  }

  // Run connectivity tests
  await testNocoDB();
  await testN8n();

  console.log('\n============================================');
  console.log(' Validation complete');
  console.log('============================================\n');
}

main().catch((error) => {
  console.error('Unexpected error:', error);
  process.exit(1);
});
