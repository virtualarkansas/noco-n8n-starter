/**
 * ============================================================
 * ExampleNode — A Minimal Custom n8n Node
 * ============================================================
 *
 * This is a starter template for building custom n8n nodes.
 * It demonstrates the basic structure every node needs:
 *
 *   1. Import the required types from n8n-workflow
 *   2. Define the node class implementing INodeType
 *   3. Set up the `description` object (metadata, properties, etc.)
 *   4. Implement the `execute()` method (the node's logic)
 *
 * HOW CUSTOM NODES WORK:
 * - n8n loads your node based on the package.json "n8n.nodes" entry
 * - The `description` tells n8n how to render the node in the UI
 * - The `execute()` method runs when the workflow reaches this node
 * - Input data comes from the previous node via `this.getInputData()`
 * - Output data is returned as an array of arrays of INodeExecutionData
 *
 * TO CREATE YOUR OWN NODE:
 * 1. Copy this file and rename it (e.g., MyNode.node.ts)
 * 2. Update the class name and description
 * 3. Add your properties (inputs the user configures in the UI)
 * 4. Implement your logic in execute()
 * 5. Update package.json to register your new node
 * 6. Run `npm run build` to compile
 *
 * DOCS: https://docs.n8n.io/integrations/creating-nodes/
 * ============================================================
 */

import {
	IExecuteFunctions,
	INodeExecutionData,
	INodeType,
	INodeTypeDescription,
} from 'n8n-workflow';

/**
 * The ExampleNode class — implements INodeType.
 *
 * Every custom n8n node is a class that implements the INodeType interface.
 * This interface requires two things:
 *   - `description`: An object describing the node (name, properties, etc.)
 *   - `execute()`: A method containing the node's runtime logic
 */
export class ExampleNode implements INodeType {

	/**
	 * NODE DESCRIPTION
	 *
	 * This object tells n8n everything about your node:
	 * - How to display it in the UI (name, icon, color, category)
	 * - What version it is
	 * - What inputs/outputs it has
	 * - What properties (settings) the user can configure
	 *
	 * n8n reads this when loading the node and uses it to render
	 * the node in the workflow editor.
	 */
	description: INodeTypeDescription = {

		// --- IDENTITY ---

		// displayName: What the user sees in the n8n UI
		displayName: 'Example Node',

		// name: Internal identifier (camelCase, must be unique)
		// This is used in workflow JSON and API calls
		name: 'exampleNode',

		// group: Where this node appears in the node picker
		// Options: 'transform', 'input', 'output', 'trigger'
		group: ['transform'],

		// version: Increment when you make breaking changes
		version: 1,

		// description: Shown in the node picker and node settings
		description: 'A starter template for custom n8n nodes. Returns a configurable message.',

		// subtitle: Shown below the node name on the canvas
		// Uses expressions to show the current configuration
		subtitle: '={{$parameter["message"]}}',

		// --- APPEARANCE ---

		// icon: The node icon (use 'file:' for custom icons or 'fa:' for Font Awesome)
		icon: 'fa:code',

		// defaults: Default values when the node is first added to a workflow
		defaults: {
			name: 'Example Node',
		},

		// --- INPUTS & OUTPUTS ---

		// inputs: What connections this node accepts
		// 'main' = standard data connection (most nodes use this)
		inputs: ['main'],

		// outputs: What connections this node provides
		// 'main' = standard data connection
		outputs: ['main'],

		// --- PROPERTIES ---

		// properties: The configurable fields shown in the node's settings panel.
		// Each property becomes an input in the UI that the user can fill in.
		properties: [
			{
				// displayName: Label shown in the UI
				displayName: 'Message',

				// name: Internal name used in code (this.getNodeParameter('message', ...))
				name: 'message',

				// type: The input type
				// Options: 'string', 'number', 'boolean', 'options', 'collection', etc.
				type: 'string',

				// default: The default value
				default: 'Hello from NocoFlow!',

				// placeholder: Shown when the field is empty
				placeholder: 'Enter your message here',

				// description: Help text shown below the field
				description: 'The message to output. This is a simple example — replace with your own logic.',

				// required: Whether this field must be filled in
				required: true,
			},
		],
	};


	/**
	 * EXECUTE METHOD
	 *
	 * This is where your node's logic lives. It runs every time the
	 * workflow reaches this node during execution.
	 *
	 * HOW IT WORKS:
	 * 1. Get input data from the previous node
	 * 2. Loop through each input item
	 * 3. Process the data (your custom logic goes here)
	 * 4. Return the output data for the next node
	 *
	 * IMPORTANT CONCEPTS:
	 * - `this.getInputData()` returns items from the previous node
	 * - `this.getNodeParameter()` reads the user's configuration
	 * - Items are objects with a `json` property containing the data
	 * - You must return a 2D array: [[item1, item2, ...]] for single output
	 *
	 * @returns Array of arrays of INodeExecutionData (one array per output)
	 */
	async execute(this: IExecuteFunctions): Promise<INodeExecutionData[][]> {

		// --- STEP 1: Get input data ---
		// This returns all items from the previous node.
		// Each item has a `json` property with the actual data.
		const items = this.getInputData();

		// --- STEP 2: Prepare output array ---
		// We'll build our output items here.
		const returnData: INodeExecutionData[] = [];

		// --- STEP 3: Process each input item ---
		// In n8n, workflows process data as "items" (like rows in a table).
		// We loop through each item and apply our logic.
		for (let itemIndex = 0; itemIndex < items.length; itemIndex++) {

			// Read the "message" property from the node's settings.
			// The second argument (itemIndex) is needed because properties
			// can use expressions that reference the current item.
			const message = this.getNodeParameter('message', itemIndex, '') as string;

			// --- STEP 4: Build the output item ---
			// Create a new item with our processed data.
			// We spread the original item's JSON and add our message.
			returnData.push({
				json: {
					// Keep all data from the previous node
					...items[itemIndex].json,
					// Add our message
					message,
					// Add metadata about when this was processed
					processedAt: new Date().toISOString(),
					processedBy: 'ExampleNode',
				},
			});
		}

		// --- STEP 5: Return the results ---
		// The return value is a 2D array: one inner array per output.
		// Most nodes have one output, so we return [[...items]].
		// If your node had two outputs, you'd return [[output1Items], [output2Items]].
		return [returnData];
	}
}
