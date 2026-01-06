"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.activate = activate;
exports.deactivate = deactivate;
const vscode = __importStar(require("vscode"));
const path = __importStar(require("path"));
const node_1 = require("vscode-languageclient/node");
let client;
function activate(context) {
    console.log('Flux extension is now active!');
    // Get the path to the LSP server
    const config = vscode.workspace.getConfiguration('flux');
    let serverPath = config.get('lspPath');
    if (!serverPath) {
        // Use bundled server - look for dart in PATH
        const lspPackagePath = path.join(context.extensionPath, '..', 'flux_lsp');
        serverPath = 'dart';
        // Server options - spawn the Dart LSP server
        const serverOptions = {
            command: serverPath,
            args: ['run', path.join(lspPackagePath, 'bin', 'flux_lsp.dart')],
            options: {
                cwd: lspPackagePath
            }
        };
        // Client options
        const clientOptions = {
            documentSelector: [{ scheme: 'file', language: 'flux' }],
            synchronize: {
                fileEvents: vscode.workspace.createFileSystemWatcher('**/*.flux')
            },
            outputChannelName: 'Flux Language Server'
        };
        // Create the language client
        client = new node_1.LanguageClient('fluxLanguageServer', 'Flux Language Server', serverOptions, clientOptions);
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
    context.subscriptions.push(vscode.commands.registerCommand('flux.restartServer', async () => {
        if (client) {
            await client.stop();
            await client.start();
            vscode.window.showInformationMessage('Flux Language Server restarted');
        }
    }));
    // Register Debug Adapter
    const factory = new FluxDebugAdapterDescriptorFactory(context);
    context.subscriptions.push(vscode.debug.registerDebugAdapterDescriptorFactory('flux', factory));
}
class FluxDebugAdapterDescriptorFactory {
    constructor(context) {
        this.context = context;
    }
    createDebugAdapterDescriptor(session, executable) {
        // Use DAP path from config if available
        const config = vscode.workspace.getConfiguration('flux');
        let dapPath = config.get('dapPath');
        // Fallback to bundled dap in dev environment
        if (!dapPath) {
            const dapPackagePath = path.join(this.context.extensionPath, '..', 'flux_dap');
            dapPath = path.join(dapPackagePath, 'bin', 'flux_dap.dart');
        }
        // Spawn 'dart run flux_dap_path'
        // Actually 'dart run' expects a package or file. If file, just 'dart file'.
        // But 'flux_dap.dart' is a script.
        return new vscode.DebugAdapterExecutable('dart', ['run', dapPath], {
            cwd: path.dirname(dapPath)
        });
    }
}
function deactivate() {
    if (!client) {
        return undefined;
    }
    return client.stop();
}
//# sourceMappingURL=extension.js.map