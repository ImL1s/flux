/// Flux Language Server CLI entry point
///
/// Starts the Flux LSP server, listening on stdin/stdout

import 'dart:io';
import 'package:flux_lsp/flux_lsp.dart';

void main(List<String> args) async {
  // Check for version flag
  if (args.contains('--version') || args.contains('-v')) {
    print('Flux Language Server 0.1.0');
    exit(0);
  }

  // Check for help flag
  if (args.contains('--help') || args.contains('-h')) {
    print('''
Flux Language Server

Usage: flux_lsp [options]

Options:
  --version, -v    Show version
  --help, -h       Show this help

The server communicates via JSON-RPC over stdin/stdout.
''');
    exit(0);
  }

  // Start the server
  final server = FluxLanguageServer();
  await server.start();
}
