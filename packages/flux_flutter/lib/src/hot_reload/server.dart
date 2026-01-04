import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// A WebSocket server/client handler for Hot Reload.
class HotReloadServer {
  HttpServer? _server;
  WebSocket? _socket;
  final void Function(Map<String, dynamic> data) onHotReload;

  // Track connected clients
  final List<WebSocket> _clients = [];

  HotReloadServer({required this.onHotReload});

  /// Starts a local WebSocket server (for Desktop/Simulators where CLI can connect directly)
  Future<void> startServer({int port = 8080}) async {
    if (kIsWeb) return; // Web cannot host server

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      debugPrint('🔥 Flux Hot Reload Server listening on port $port');

      _server!.transform(WebSocketTransformer()).listen((WebSocket webSocket) {
        debugPrint('🔥 Flux CLI connected!');
        _clients.add(webSocket);

        webSocket.listen(
          (message) {
            _handleMessage(message);
          },
          onDone: () {
            debugPrint('🔌 Flux CLI disconnected');
            _clients.remove(webSocket);
          },
          onError: (e) {
            debugPrint('❌ WebSocket error: $e');
            _clients.remove(webSocket);
          },
        );
      });
    } catch (e) {
      debugPrint('❌ Failed to start Hot Reload Server: $e');
    }
  }

  /// Connects to a remote CLI server (for Physical Devices/Web)
  Future<void> connectTo(String host) async {
    try {
      debugPrint('🔄 Connecting to Flux Hot Reload Server at $host...');
      _socket = await WebSocket.connect(host);
      debugPrint('✅ Connected to Flux Hot Reload Server!');

      _socket!.listen(
        (message) {
          _handleMessage(message);
        },
        onDone: () => debugPrint('🔌 Disconnected from Hot Reload Server'),
        onError: (e) => debugPrint('❌ WebSocket error: $e'),
      );
    } catch (e) {
      debugPrint('❌ Failed to connect to Hot Reload Server: $e');
    }
  }

  void _handleMessage(dynamic message) {
    if (message is String) {
      try {
        final data = jsonDecode(message) as Map<String, dynamic>;
        onHotReload(data);
      } catch (e) {
        debugPrint('❌ Failed to decode hot reload message: $e');
      }
    }
  }

  void dispose() {
    for (final client in _clients) {
      client.close();
    }
    _server?.close();
    _socket?.close();
  }
}
