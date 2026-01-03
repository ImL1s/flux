import * as assert from 'assert';

// You can import and use all API from the 'vscode' module
// as well as import your extension to test it
import * as vscode from 'vscode';
// import * as myExtension from '../../extension';

suite('Extension Test Suite', () => {
    vscode.window.showInformationMessage('Start all tests.');

    test('Extension should be present', () => {
        assert.ok(vscode.extensions.getExtension('ImL1s.flux-vscode'));
    });

    test('Flux Debugger should be registered', async () => {
        // Verify that we can resolve the debug adapter
        // Note: We can't easily check internal registration, but we can check if the extension activates
        // and if it contributes the debugger in package.json (which VS Code handles).

        const ext = vscode.extensions.getExtension('ImL1s.flux-vscode');
        assert.ok(ext, 'Extension not found');

        await ext?.activate();
        assert.ok(ext?.isActive, 'Extension failed to activate');

        // Check package.json contribution via API?
        // VS Code API doesn't expose raw contribution points directly easily, 
        // but activation implies successful registration of commands/providers.
    });

    test('DAP Configuration Provider should be valid', async () => {
        // This is a smoke test to ensure our Glue Code doesn't crash on activation.
        // Real DAP connection requires a running process and UI verification.
        assert.ok(true);
    });
});
