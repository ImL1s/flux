import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'ota_server.dart';

/// Starts the Flux OTA development server.
///
/// Usage:
/// ```
/// dart run bin/ota_server.dart [port]
/// ```
Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.parse(args[0]) : 8080;
  final signingKey = Platform.environment['FLUX_SIGNING_KEY'] ?? 'dev-secret-key';

  final server = FluxOtaServer(signingKey: signingKey);
  final httpServer = await shelf_io.serve(server.handler, 'localhost', port);

  print('''
╔═══════════════════════════════════════════════════════════╗
║              Flux OTA Development Server                  ║
╠═══════════════════════════════════════════════════════════╣
║  Port: $port                                              
║  Signing Key: ${signingKey.substring(0, 3)}***            
╠═══════════════════════════════════════════════════════════╣
║  Endpoints:                                               ║
║  POST   /releases                    - Upload release     ║
║  GET    /releases/:appId/latest      - Latest version     ║
║  GET    /releases/:appId/:version    - Specific version   ║
║  GET    /patches/:appId/:from/:to    - Download patch     ║
║  GET    /chunks/:appId/:version      - Download chunk     ║
║  GET    /health                      - Health check       ║
╚═══════════════════════════════════════════════════════════╝
''');

  print('Serving at http://${httpServer.address.host}:${httpServer.port}');

  // Handle shutdown
  ProcessSignal.sigint.watch().listen((_) {
    print('\nShutting down...');
    httpServer.close();
    exit(0);
  });
}
