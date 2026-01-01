import * as vscode from 'vscode';
import * as path from 'path';
import { spawn, ChildProcess } from 'child_process';
import {
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
    TransportKind
} from 'vscode-languageclient/node';

let client: LanguageClient | undefined;

export function activate(context: vscode.ExtensionContext) {
    console.log('Flux extension is now active!');

    // Get the path to the LSP server
    const config = vscode.workspace.getConfiguration('flux');
    let serverPath = config.get<string>('lspPath');

    if (!serverPath) {
        // Use bundled server - look for dart in PATH
        const lspPackagePath = path.join(context.extensionPath, '..', 'flux_lsp');
        serverPath = 'dart';

        // Server options - spawn the Dart LSP server
        const serverOptions: ServerOptions = {
            command: serverPath,
            args: ['run', path.join(lspPackagePath, 'bin', 'flux_lsp.dart')],
            options: {
                cwd: lspPackagePath
            }
        };

        // Client options
        const clientOptions: LanguageClientOptions = {
            documentSelector: [{ scheme: 'file', language: 'flux' }],
            synchronize: {
                fileEvents: vscode.workspace.createFileSystemWatcher('**/*.flux')
            },
            outputChannelName: 'Flux Language Server'
        };

        // Create the language client
        client = new LanguageClient(
            'fluxLanguageServer',
            'Flux Language Server',
            serverOptions,
            clientOptions
        );

        // Start the client (also starts the server)
        client.start();

        context.subscriptions.push({
            dispose: () => {
                if (client) {
                    client.stop();
                }
            }
        });
    }

    // Register commands
    context.subscriptions.push(
        vscode.commands.registerCommand('flux.restartServer', async () => {
            if (client) {
                await client.stop();
                await client.start();
                vscode.window.showInformationMessage('Flux Language Server restarted');
            }
        })
    );
}

export function deactivate(): Thenable<void> | undefined {
    if (!client) {
        return undefined;
    }
    return client.stop();
}
