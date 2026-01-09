import 'package:flutter/foundation.dart';

/// A WebSocket server/client handler for Hot Reload (Web Stub).
class HotReloadServer {
  final void Function(Map<String, dynamic> data) onHotReload;

  HotReloadServer({required this.onHotReload});

  /// Starts a local WebSocket server (Not supported on Web)
  Future<void> startServer({int port = 8080}) async {
    debugPrint('⚠️ Flux Hot Reload Server is not supported on Web (cannot bind port).');
  }

  /// Connects to a remote CLI server (Not yet implemented for Web)
  Future<void> connectTo(String host) async {
    debugPrint('⚠️ Flux Hot Reload Client not yet implemented for Web.');
    // TODO: Implement using dart:html WebSocket or web_socket_channel
  }

  void dispose() {}
}
