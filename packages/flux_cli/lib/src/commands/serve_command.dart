import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:watcher/watcher.dart';

class ServeCommand {
  final List<WebSocketChannel> _clients = [];

  Future<void> run(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('Error: File not found: $filePath');
      exit(1);
    }

    print('Flux Hot Reload Server');
    print('Watching: $filePath');

    // Setup WebSocket handler
    final handler = webSocketHandler((WebSocketChannel webSocket, String? protocol) {
      _clients.add(webSocket);
      print('Client connected (Total: ${_clients.length})');
      
      // Send current content immediately on connection
      try {
        final content = file.readAsStringSync();
        webSocket.sink.add(content);
      } catch (e) {
        print('Error reading file: $e');
      }

      webSocket.stream.listen(
        (message) {
          // Ignore incoming messages for now, this is a one-way push
        },
        onDone: () {
          _clients.remove(webSocket);
          print('Client disconnected (Total: ${_clients.length})');
        },
        onError: (error) {
          _clients.remove(webSocket);
          print('Client error: $error');
        },
      );
    });

    // Start Server
    final server = await shelf_io.serve(handler, '0.0.0.0', 8080);
    print('Serving at ws://${server.address.host}:${server.port}');

    // Watch File
    final watcher = FileWatcher(filePath);
    watcher.events.listen((event) {
      if (event.type == ChangeType.MODIFY) {
        print('File changed: ${event.path}');
        _broadcastFile(file);
      }
    });

    // Keep process alive
    await ProcessSignal.sigint.watch().first;
    server.close();
    exit(0);
  }

  void _broadcastFile(File file) {
    try {
      // Small delay to ensure write is complete
      Future.delayed(const Duration(milliseconds: 100), () {
        final content = file.readAsStringSync();
        print('Broadcasting update to ${_clients.length} clients...');
        for (final client in _clients) {
          client.sink.add(content);
        }
      });
    } catch (e) {
      print('Error broadcasting update: $e');
    }
  }
}
