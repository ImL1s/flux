import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors/shelf_cors.dart' as cors;
import 'package:path/path.dart' as p;

void main() async {
  final app = Router();

  // Middleware pipeline
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(cors.corsHeaders())
      .addHandler(app.call);

  // 1. Serve Flux Scripts
  app.get('/scripts/<name>', (Request request, String name) async {
    final scriptPath = p.join(Directory.current.parent.path, 'scripts', name);
    final file = File(scriptPath);
    
    if (await file.exists()) {
      return Response.ok(await file.readAsString(), headers: {'content-type': 'text/plain'});
    } else {
      return Response.notFound('Script not found: $name');
    }
  });

  // 2. Mock API: Dashboard Data
  app.get('/api/dashboard', (Request request) {
    final rng = Random();
    final data = {
      'visitors': rng.nextInt(5000) + 1000,
      'sales': rng.nextInt(50000) + 5000,
      'orders': rng.nextInt(200) + 10,
    };
    // Simulate network delay manually handled by client or here? 
    // Shelf uses async handlers so we can delay.
    return Future.delayed(
      const Duration(milliseconds: 500), 
      () => Response.ok(jsonEncode(data), headers: {'content-type': 'application/json'})
    );
  });

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 8082);
  print('🚀 Showcase API Server running at http://localhost:${server.port}');
  print('📂 Serving scripts from ../scripts/');
  print('📊 API endpoint available at /api/dashboard');
}
