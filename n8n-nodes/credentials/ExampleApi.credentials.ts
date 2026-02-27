/**
 * ============================================================
 * ExampleApi Credentials — Custom Credential Type for n8n
 * ============================================================
 *
 * Credentials in n8n store sensitive information (API keys, tokens,
 * passwords) securely. They are:
 *   - Encrypted at rest in n8n's database
 *   - Never exposed in workflow JSON exports
 *   - Shared across workflows (configure once, use everywhere)
 *
 * HOW CREDENTIALS WORK:
 * 1. You define a credential type (this file)
 * 2. Register it in package.json under "n8n.credentials"
 * 3. In your node, reference it via the `credentials` property
 * 4. Users configure credentials in n8n's Settings → Credentials
 * 5. Your node accesses them via `this.getCredentials('exampleApi')`
 *
 * TO CREATE YOUR OWN CREDENTIALS:
 * 1. Copy this file and rename it (e.g., MyApi.credentials.ts)
 * 2. Update the class name, `name`, and `displayName`
 * 3. Define the properties (fields) your API needs
 * 4. Update package.json to register the new credential type
 * 5. Reference it in your node's description.credentials array
 *
 * DOCS: https://docs.n8n.io/integrations/creating-nodes/build/reference/credentials-files/
 * ============================================================
 */

import {
	ICredentialType,
	INodeProperties,
} from 'n8n-workflow';

/**
 * The ExampleApi class — implements ICredentialType.
 *
 * Every credential type is a class that implements ICredentialType.
 * It defines:
 *   - `name`: Internal identifier (used in code)
 *   - `displayName`: What the user sees in the n8n UI
 *   - `properties`: The fields the user fills in (API key, URL, etc.)
 */
export class ExampleApi implements ICredentialType {

	// --- IDENTITY ---

	// name: Internal identifier (camelCase)
	// This is what you use in your node code:
	//   this.getCredentials('exampleApi')
	name = 'exampleApi';

	// displayName: Shown in the n8n Credentials UI
	displayName = 'Example API';

	// documentationUrl: Link to docs about getting these credentials
	// n8n shows this as a help link in the credentials dialog
	documentationUrl = 'https://docs.n8n.io/integrations/creating-nodes/';

	// --- PROPERTIES ---

	// properties: The fields the user fills in when configuring credentials.
	// These are similar to node properties but specifically for sensitive data.
	//
	// Common property types:
	//   'string'  — text input (use typeOptions.password for secrets)
	//   'number'  — numeric input
	//   'boolean' — checkbox
	//   'options' — dropdown select
	properties: INodeProperties[] = [
		{
			// API KEY — the authentication token
			displayName: 'API Key',
			name: 'apiKey',
			type: 'string',

			// IMPORTANT: typeOptions.password = true hides the value
			// in the UI (shows dots instead of the actual key).
			// Always use this for sensitive values like API keys and tokens.
			typeOptions: {
				password: true,
			},

			default: '',

			// placeholder: Example text shown when the field is empty
			placeholder: 'Enter your API key',

			// description: Help text explaining where to find this value
			description: 'The API key for authenticating with the service. Find this in your account settings.',

			// required: The user must fill this in
			required: true,
		},
		{
			// BASE URL — the API endpoint
			displayName: 'Base URL',
			name: 'baseUrl',
			type: 'string',

			default: 'https://api.example.com',

			placeholder: 'https://api.example.com',

			description: 'The base URL of the API. Change this if using a self-hosted instance.',

			required: true,
		},
	];
}
