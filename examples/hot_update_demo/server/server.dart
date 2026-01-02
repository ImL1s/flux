import 'dart:io';
import 'package:path/path.dart' as p;

void main() async {
  final port = 8081;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  
  // Find the scripts directory relative to this server script
  final baseDir = p.dirname(p.dirname(Platform.script.toFilePath()));
  final scriptsPath = p.join(baseDir, 'scripts');
  
  print('🚀 Flux Hot Update Server running on http://localhost:$port');
  print('📁 Serving scripts from: $scriptsPath');
  print('---');

  await for (HttpRequest request in server) {
    final path = request.uri.path;
    final fileName = p.basename(path);
    final file = File(p.join(scriptsPath, fileName));

    // Support CORS for web demo if needed
    request.response.headers.add('Access-Control-Allow-Origin', '*');

    if (await file.exists()) {
      print('📦 Serving: $fileName');
      final scriptContent = await file.readAsString();
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType('text', 'plain', charset: 'utf-8')
        ..write(scriptContent)
        ..close();
    } else {
      print('❌ Not Found: $path');
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Script not found')
        ..close();
    }
  }
}
