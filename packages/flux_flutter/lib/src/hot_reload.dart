import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flux_flutter/src/riverpod_integration.dart';

/// A wrapper widget that enables Hot Reload for Flux scripts.
/// 
/// It connects to a WebSocket server (default: ws://localhost:8080) to receive
/// updates to the Flux source code.
/// 
/// Usage:
/// ```dart
/// FluxHotReloadWidget(
///   initialSource: "...",
///   widgetName: "Counter",
///   hotReloadUrl: "ws://10.0.2.2:8080", // Use 10.0.2.2 for Android Emulator
/// )
/// ```
class FluxHotReloadWidget extends StatefulWidget {
  final String initialSource;
  final String widgetName;
  final Map<String, dynamic> props;
  final Map<String, NotifierProvider<Notifier<Object?>, Object?>> notifierProviders;
  final String hotReloadUrl;

  const FluxHotReloadWidget({
    super.key,
    required this.initialSource,
    required this.widgetName,
    this.props = const {},
    this.notifierProviders = const {},
    this.hotReloadUrl = 'ws://localhost:8080',
  });

  @override
  State<FluxHotReloadWidget> createState() => _FluxHotReloadWidgetState();
}

class _FluxHotReloadWidgetState extends State<FluxHotReloadWidget> {
  late String _currentSource;
  WebSocketChannel? _channel;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _currentSource = widget.initialSource;
    _connect();
  }

  void _connect() {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(widget.hotReloadUrl));
      _connected = true;
      debugPrint('Flux Hot Reload: Connected to ${widget.hotReloadUrl}');

      _channel!.stream.listen(
        (data) {
          if (data is String) {
            debugPrint('Flux Hot Reload: Received update (${data.length} bytes)');
            setState(() {
              _currentSource = data;
            });
          }
        },
        onError: (error) {
          debugPrint('Flux Hot Reload Error: $error');
          _reconnectLater();
        },
        onDone: () {
          debugPrint('Flux Hot Reload: Disconnected');
          _reconnectLater();
        },
      );
    } catch (e) {
      debugPrint('Flux Hot Reload Connection Failed: $e');
      _reconnectLater();
    }
  }

  void _reconnectLater() {
    if (!mounted) return;
    setState(() => _connected = false);
    // Simple retry strategy
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _connect();
    });
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_connected)
          Container(
            color: const Color(0xFFFFF3E0), // Orange 50
            padding: const EdgeInsets.all(4),
            width: double.infinity,
            child: Text(
              'Flux Hot Reload: Disconnected (Retrying...)',
              style: TextStyle(color: const Color(0xFFE65100), fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: FluxRiverpodWidget(
            source: _currentSource,
            widgetName: widget.widgetName,
            props: widget.props,
            notifierProviders: widget.notifierProviders,
          ),
        ),
      ],
    );
  }
}
