import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flux_compiler/flux_compiler.dart';

/// Callback signature for hot-reload events.
typedef HotReloadCallback = void Function(String scriptName, CompiledFunction newFunction);

/// Hot-reload service that connects to the Flux dev server.
/// 
/// Usage:
/// ```dart
/// final service = HotReloadService(
///   serverUrl: 'ws://localhost:8765',
///   onReload: (scriptName, fn) => vm.hotSwap(scriptName, fn),
/// );
/// await service.connect();
/// ```
class HotReloadService {
  final String serverUrl;
  final HotReloadCallback onReload;
  final void Function(String error)? onError;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  bool _disposed = false;
  
  HotReloadService({
    required this.serverUrl,
    required this.onReload,
    this.onError,
    this.onConnected,
    this.onDisconnected,
  });

  /// Connects to the dev server.
  Future<bool> connect() async {
    if (_disposed) return false;
    
    try {
      _channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      await _channel!.ready;
      
      debugPrint('[HotReload] Connected to $serverUrl');
      onConnected?.call();
      
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onDone: _handleDisconnect,
        onError: (e) {
          debugPrint('[HotReload] Error: $e');
          onError?.call(e.toString());
          _handleDisconnect();
        },
      );
      
      return true;
    } catch (e) {
      debugPrint('[HotReload] Connection failed: $e');
      onError?.call('Connection failed: $e');
      _scheduleReconnect();
      return false;
    }
  }

  /// Disconnects from the dev server.
  Future<void> disconnect() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    debugPrint('[HotReload] Disconnected');
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String;
      
      switch (type) {
        case 'reload':
          _handleReload(data);
          break;
        case 'error':
          final error = data['error'] as String?;
          debugPrint('[HotReload] Server error: $error');
          onError?.call(error ?? 'Unknown error');
          break;
        case 'scripts':
          debugPrint('[HotReload] Available scripts: ${data['scripts']}');
          break;
        case 'pong':
          // Heartbeat response, ignore
          break;
      }
    } catch (e) {
      debugPrint('[HotReload] Message parse error: $e');
    }
  }

  void _handleReload(Map<String, dynamic> data) {
    try {
      final scriptName = data['script'] as String;
      final bytecodeData = data['bytecode'] as Map<String, dynamic>;
      
      // Deserialize the compiled function
      final function = _deserializeFunction(bytecodeData);
      
      debugPrint('[HotReload] Reloading: $scriptName');
      onReload(scriptName, function);
      
    } catch (e) {
      debugPrint('[HotReload] Reload error: $e');
      onError?.call('Failed to apply reload: $e');
    }
  }

  CompiledFunction _deserializeFunction(Map<String, dynamic> data) {
    final name = data['name'] as String? ?? '';
    final arity = data['arity'] as int? ?? 0;
    final isAsync = data['isAsync'] as bool? ?? false;
    final moduleName = data['moduleName'] as String?;
    final paramNames = (data['paramNames'] as List?)?.cast<String>() ?? [];
    final localNames = (data['localNames'] as List?)?.cast<String>() ?? [];
    final chunkData = data['chunk'] as Map<String, dynamic>;
    
    final chunk = Chunk();
    
    // Deserialize bytecode
    final code = (chunkData['code'] as List).cast<int>();
    for (final byte in code) {
      chunk.code.add(byte);
    }
    
    // Deserialize lines
    final lines = (chunkData['lines'] as List).cast<int>();
    for (final line in lines) {
      chunk.lines.add(line);
    }
    
    // Deserialize constants
    final constants = chunkData['constants'] as List;
    for (final constant in constants) {
      if (constant == null) {
        chunk.addConstant(null);
      } else if (constant is num || constant is String || constant is bool) {
        chunk.addConstant(constant);
      } else if (constant is Map && constant['type'] == 'function') {
        // Recursively deserialize nested functions
        chunk.addConstant(_deserializeFunction(constant['data'] as Map<String, dynamic>));
      } else {
        chunk.addConstant(constant.toString());
      }
    }
    
    return CompiledFunction(
      name,
      chunk,
      arity: arity,
      isAsync: isAsync,
      moduleName: moduleName,
      paramNames: paramNames,
      localNames: localNames,
    );
  }

  void _handleDisconnect() {
    debugPrint('[HotReload] Connection closed');
    onDisconnected?.call();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      debugPrint('[HotReload] Attempting to reconnect...');
      connect();
    });
  }

  /// Sends a ping to keep connection alive.
  void ping() {
    _channel?.sink.add(jsonEncode({'type': 'ping'}));
  }
}
