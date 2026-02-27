/**
 * ============================================================
 * sync-workflows.js — Export & Import n8n Workflows
 * ============================================================
 *
 * A utility for syncing workflows between your n8n instance and
 * local JSON files. Useful for version control and backups.
 *
 * USAGE:
 *   # Export all workflows from n8n to workflows/exports/
 *   source .env && node scripts/sync-workflows.js export
 *
 *   # Import all workflows from workflows/examples/ into n8n
 *   source .env && node scripts/sync-workflows.js import
 *
 * REQUIRES:
 *   - N8N_URL and N8N_API_KEY environment variables
 *
 * USES ONLY BUILT-IN NODE.JS MODULES — no npm dependencies needed.
 * ============================================================
 */

const http = require('http');
const https = require('https');
const { URL } = require('url');
const fs = require('fs');
const path = require('path');


// ============================================================
// CONFIGURATION
// ============================================================

const N8N_URL = process.env.N8N_URL;
const N8N_API_KEY = process.env.N8N_API_KEY;

// Directory paths (relative to project root)
const EXPORTS_DIR = path.join(process.cwd(), 'workflows', 'exports');
const EXAMPLES_DIR = path.join(process.cwd(), 'workflows', 'examples');


// ============================================================
// UTILITY: HTTP Request Helper
// ============================================================
// Makes HTTP/HTTPS requests using built-in Node.js modules.
// Supports GET and POST methods with JSON bodies.

function httpRequest(urlString, options = {}) {
  return new Promise((resolve, reject) => {
    const parsedUrl = new URL(urlString);
    const client = parsedUrl.protocol === 'https:' ? https : http;

    const reqOptions = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port,
      path: parsedUrl.pathname + parsedUrl.search,
      method: options.method || 'GET',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-N8N-API-KEY': N8N_API_KEY,
        ...options.headers,
      },
      timeout: 30000,
    };

    const req = client.request(reqOptions, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        let json = null;
        try {
          json = JSON.parse(data);
        } catch {
          // Not JSON
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
      reject(new Error('Request timed out'));
    });

    // Send request body for POST/PUT
    if (options.body) {
      req.write(JSON.stringify(options.body));
    }

    req.end();
  });
}


// ============================================================
// UTILITY: Sanitize filename
// ============================================================
// Converts a workflow name into a safe filename.
// "My Cool Workflow!" → "my-cool-workflow.json"

function sanitizeFilename(name) {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')  // Replace non-alphanumeric chars with hyphens
    .replace(/^-+|-+$/g, '')       // Remove leading/trailing hyphens
    .substring(0, 100)             // Limit length
    + '.json';
}


// ============================================================
// EXPORT: Fetch all workflows and save as JSON files
// ============================================================
// Downloads every workflow from your n8n instance and saves
// each one as a JSON file in workflows/exports/.

async function exportWorkflows() {
  console.log('============================================');
  console.log(' Exporting workflows from n8n');
  console.log('============================================\n');

  // Step 1: Create the exports directory if it doesn't exist
  if (!fs.existsSync(EXPORTS_DIR)) {
    fs.mkdirSync(EXPORTS_DIR, { recursive: true });
    console.log(`Created directory: ${EXPORTS_DIR}`);
  }

  // Step 2: Fetch the list of all workflows
  console.log(`Fetching workflow list from ${N8N_URL}...\n`);
  const listResponse = await httpRequest(`${N8N_URL}/api/v1/workflows`);

  if (listResponse.statusCode !== 200) {
    console.log(`❌ Failed to list workflows (HTTP ${listResponse.statusCode})`);
    console.log(`   ${listResponse.raw.substring(0, 200)}`);
    process.exit(1);
  }

  const workflows = listResponse.body?.data || [];

  if (workflows.length === 0) {
    console.log('No workflows found in your n8n instance.');
    return;
  }

  console.log(`Found ${workflows.length} workflow(s). Exporting...\n`);

  // Step 3: Fetch each workflow's full details and save to file
  let exported = 0;
  let failed = 0;

  for (const workflow of workflows) {
    try {
      // Fetch the full workflow (list endpoint only returns metadata)
      const detailResponse = await httpRequest(
        `${N8N_URL}/api/v1/workflows/${workflow.id}`
      );

      if (detailResponse.statusCode !== 200) {
        console.log(`   ❌ Failed to fetch "${workflow.name}" (HTTP ${detailResponse.statusCode})`);
        failed++;
        continue;
      }

      // Build a safe filename from the workflow name
      const filename = sanitizeFilename(workflow.name);
      const filepath = path.join(EXPORTS_DIR, filename);

      // Save the workflow JSON to file (pretty-printed)
      fs.writeFileSync(
        filepath,
        JSON.stringify(detailResponse.body, null, 2),
        'utf8'
      );

      const activeStatus = workflow.active ? '🟢 active' : '⚪ inactive';
      console.log(`   ✅ ${workflow.name} (${activeStatus}) → ${filename}`);
      exported++;

    } catch (error) {
      console.log(`   ❌ Error exporting "${workflow.name}": ${error.message}`);
      failed++;
    }
  }

  // Step 4: Print summary
  console.log(`\n---`);
  console.log(`Exported: ${exported}, Failed: ${failed}`);
  console.log(`Files saved to: ${EXPORTS_DIR}`);
}


// ============================================================
// IMPORT: Read JSON files and create workflows in n8n
// ============================================================
// Reads each .json file from workflows/examples/ and creates
// a new workflow in your n8n instance.

async function importWorkflows() {
  console.log('============================================');
  console.log(' Importing workflows into n8n');
  console.log('============================================\n');

  // Step 1: Check that the examples directory exists
  if (!fs.existsSync(EXAMPLES_DIR)) {
    console.log(`❌ Examples directory not found: ${EXAMPLES_DIR}`);
    console.log('   Create some workflow JSON files there first.');
    process.exit(1);
  }

  // Step 2: Read all .json files from the directory
  const files = fs.readdirSync(EXAMPLES_DIR)
    .filter(f => f.endsWith('.json'));

  if (files.length === 0) {
    console.log('No .json files found in workflows/examples/');
    return;
  }

  console.log(`Found ${files.length} workflow file(s). Importing...\n`);

  // Step 3: Create each workflow in n8n
  let imported = 0;
  let failed = 0;

  for (const file of files) {
    const filepath = path.join(EXAMPLES_DIR, file);

    try {
      // Read the JSON file
      const content = fs.readFileSync(filepath, 'utf8');
      const workflow = JSON.parse(content);

      // Create the workflow in n8n via API
      // We send only the fields n8n expects for creation
      const createPayload = {
        name: workflow.name || file.replace('.json', ''),
        nodes: workflow.nodes || [],
        connections: workflow.connections || {},
        settings: workflow.settings || { executionOrder: 'v1' },
      };

      const response = await httpRequest(`${N8N_URL}/api/v1/workflows`, {
        method: 'POST',
        body: createPayload,
      });

      if (response.statusCode === 200 || response.statusCode === 201) {
        const newId = response.body?.id;
        console.log(`   ✅ ${file} → created as workflow #${newId} ("${createPayload.name}")`);
        imported++;
      } else {
        console.log(`   ❌ ${file} — HTTP ${response.statusCode}: ${response.raw.substring(0, 200)}`);
        failed++;
      }

    } catch (error) {
      if (error instanceof SyntaxError) {
        console.log(`   ❌ ${file} — Invalid JSON: ${error.message}`);
      } else {
        console.log(`   ❌ ${file} — Error: ${error.message}`);
      }
      failed++;
    }
  }

  // Step 4: Print summary
  console.log(`\n---`);
  console.log(`Imported: ${imported}, Failed: ${failed}`);

  if (imported > 0) {
    console.log('\nNote: Imported workflows are inactive by default.');
    console.log('Activate them in n8n or via:');
    console.log('  bash .claude/scripts/n8n.sh activate <workflow-id>');
  }
}


// ============================================================
// MAIN — Parse command and run
// ============================================================

async function main() {
  // Check for required environment variables
  if (!N8N_URL || !N8N_API_KEY) {
    console.log('❌ N8N_URL and N8N_API_KEY must be set.');
    console.log('');
    console.log('   Load your env file first:');
    console.log('     source .env && node scripts/sync-workflows.js export');
    console.log('');
    console.log('   Or set up your environment:');
    console.log('     bash .claude/scripts/setup-env.sh "" "" "" <N8N_URL> <N8N_API_KEY>');
    process.exit(1);
  }

  // Parse the command from the first argument
  const command = process.argv[2];

  switch (command) {
    case 'export':
      await exportWorkflows();
      break;

    case 'import':
      await importWorkflows();
      break;

    default:
      console.log('Usage: node scripts/sync-workflows.js <command>');
      console.log('');
      console.log('Commands:');
      console.log('  export   Download all workflows from n8n → workflows/exports/');
      console.log('  import   Upload workflows from workflows/examples/ → n8n');
      console.log('');
      console.log('Examples:');
      console.log('  source .env && node scripts/sync-workflows.js export');
      console.log('  source .env && node scripts/sync-workflows.js import');
      process.exit(1);
  }
}

main().catch((error) => {
  console.error('Unexpected error:', error);
  process.exit(1);
});
