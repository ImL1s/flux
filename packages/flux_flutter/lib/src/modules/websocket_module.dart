import 'dart:async';
import 'package:flux_vm/flux_vm.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// WebSocket module for Flux
///
/// Provides real-time bidirectional communication capabilities.
///
/// Usage in Flux:
/// ```flux
/// // Connect to WebSocket server
/// var ws = await websocket.connect("wss://echo.websocket.org");
///
/// // Listen for messages
/// websocket.listen(ws, fn(message) {
///   print("Received: " + message);
/// });
///
/// // Send message
/// websocket.send(ws, "Hello Server!");
///
/// // Close connection
/// websocket.close(ws);
/// ```
class WebSocketModule extends FluxModule {
  final Map<String, _WebSocketConnection> _connections = {};
  int _nextId = 0;

  WebSocketModule() : super('websocket') {
    _registerFunctions();
  }

  void _registerFunctions() {
    // Connection management
    register('connect', AsyncNativeFunction('websocket.connect', -1, _connect));
    register('close', NativeFunction('websocket.close', 1, _close));
    register('closeAll', NativeFunction('websocket.closeAll', 0, _closeAll));

    // Messaging
    register('send', NativeFunction('websocket.send', 2, _send));
    register('listen', NativeFunction('websocket.listen', 2, _listen));

    // State queries
    register('isConnected',
        NativeFunction('websocket.isConnected', 1, _isConnected));
    register('getState', NativeFunction('websocket.getState', 1, _getState));
  }

  // ==================== Connection Management ====================

  /// Connect to a WebSocket server
  ///
  /// Args:
  ///   - url: WebSocket URL (ws:// or wss://)
  ///   - options (optional): Map with:
  ///     - protocols: `List<String>` of subprotocols
  ///     - pingInterval: int (milliseconds) for keep-alive pings
  Future<Object?> _connect(List<Object?> args) async {
    final url = args[0] as String;
    final options = args.length > 1 ? args[1] as Map? : null;

    try {
      final uri = Uri.parse(url);

      // Extract options
      final protocols = options?['protocols'] as List?;
      final pingIntervalMs = options?['pingInterval'] as int?;

      // Create channel
      final channel = WebSocketChannel.connect(
        uri,
        protocols: protocols?.cast<String>(),
      );

      // Wait for connection to be established
      await channel.ready;

      // Generate unique ID for this connection
      final id = 'ws_${_nextId++}';

      // Create connection wrapper
      final connection = _WebSocketConnection(
        id: id,
        channel: channel,
        url: url,
        pingInterval: pingIntervalMs != null
            ? Duration(milliseconds: pingIntervalMs)
            : null,
      );

      _connections[id] = connection;

      // Start ping timer if configured
      if (connection.pingInterval != null) {
        connection.startPingTimer();
      }

      return {
        'id': id,
        'url': url,
        'state': 'connected',
      };
    } catch (e) {
      return {
        'error': true,
        'message': 'Failed to connect: $e',
      };
    }
  }

  /// Close a WebSocket connection
  Object? _close(List<Object?> args) {
    final connectionId = args[0] as String;
    final connection = _connections[connectionId];

    if (connection == null) {
      return {'error': true, 'message': 'Connection not found'};
    }

    connection.close();
    _connections.remove(connectionId);
    return null;
  }

  /// Close all active WebSocket connections
  Object? _closeAll(List<Object?> args) {
    for (final connection in _connections.values) {
      connection.close();
    }
    _connections.clear();
    return null;
  }

  // ==================== Messaging ====================

  /// Send a message through a WebSocket connection
  Object? _send(List<Object?> args) {
    final connectionId = args[0] as String;
    final message = args[1];

    final connection = _connections[connectionId];
    if (connection == null) {
      throw 'WebSocket connection not found: $connectionId';
    }

    try {
      connection.send(message);
      return null;
    } catch (e) {
      throw 'Failed to send message: $e';
    }
  }

  /// Listen for messages on a WebSocket connection
  ///
  /// The callback will be invoked for each incoming message.
  /// Note: This sets up a stream listener. Only one listener per connection.
  Object? _listen(List<Object?> args) {
    final connectionId = args[0] as String;
    final callback = args[1];

    final connection = _connections[connectionId];
    if (connection == null) {
      throw 'WebSocket connection not found: $connectionId';
    }

    if (callback is! Function) {
      throw 'Second argument must be a callback function';
    }

    // Set up stream listener
    connection.listen((message) {
      try {
        // Invoke Flux callback with the message
        callback([message]);
      } catch (e) {
        // Silently catch callback errors to prevent stream cancellation
        // In production, you might want to log this
      }
    });

    return null;
  }

  // ==================== State Queries ====================

  /// Check if a connection is still active
  Object? _isConnected(List<Object?> args) {
    final connectionId = args[0] as String;
    final connection = _connections[connectionId];

    if (connection == null) return false;
    return connection.isConnected;
  }

  /// Get the current state of a connection
  Object? _getState(List<Object?> args) {
    final connectionId = args[0] as String;
    final connection = _connections[connectionId];

    if (connection == null) {
      return {
        'exists': false,
        'state': 'not_found',
      };
    }

    return {
      'exists': true,
      'state': connection.isConnected ? 'connected' : 'disconnected',
      'url': connection.url,
    };
  }

  /// Cleanup all connections when module is disposed
  void dispose() {
    _closeAll([]);
  }
}

/// Internal wrapper for WebSocket connections
class _WebSocketConnection {
  final String id;
  final WebSocketChannel channel;
  final String url;
  final Duration? pingInterval;

  StreamSubscription? _subscription;
  Timer? _pingTimer;
  bool _isConnected = true;

  _WebSocketConnection({
    required this.id,
    required this.channel,
    required this.url,
    this.pingInterval,
  });

  bool get isConnected => _isConnected;

  /// Send a message through the channel
  void send(Object? message) {
    if (!_isConnected) {
      throw 'Cannot send message: connection is closed';
    }
    channel.sink.add(message);
  }

  /// Listen for incoming messages
  void listen(void Function(dynamic message) onMessage) {
    // Cancel existing subscription if any
    _subscription?.cancel();

    _subscription = channel.stream.listen(
      onMessage,
      onError: (error) {
        _isConnected = false;
        _pingTimer?.cancel();
      },
      onDone: () {
        _isConnected = false;
        _pingTimer?.cancel();
      },
      cancelOnError: false,
    );
  }

  /// Start periodic ping to keep connection alive
  void startPingTimer() {
    if (pingInterval == null) return;

    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval!, (timer) {
      if (_isConnected) {
        try {
          channel.sink.add('ping');
        } catch (e) {
          timer.cancel();
          _isConnected = false;
        }
      } else {
        timer.cancel();
      }
    });
  }

  /// Close the connection and cleanup resources
  void close() {
    _isConnected = false;
    _pingTimer?.cancel();
    _subscription?.cancel();
    channel.sink.close();
  }
}
