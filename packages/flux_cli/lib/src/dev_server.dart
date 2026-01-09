import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore_for_file: unused_import
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:watcher/watcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flux_compiler/flux_compiler.dart';

/// Development server for Flux hot-reload.
///
/// Watches `.flux` files in a directory and broadcasts recompiled bytecode
/// to connected clients via WebSocket.
class FluxDevServer {
  final String watchDirectory;
  final int port;
  final List<WebSocketChannel> _clients = [];

  DirectoryWatcher? _watcher;
  HttpServer? _server;

  FluxDevServer({
    required this.watchDirectory,
    this.port = 8765,
  });

  /// Starts the dev server.
  Future<void> start() async {
    // 1. Setup WebSocket handler
    final handler =
        webSocketHandler((WebSocketChannel channel, String? subprotocol) {
      print('[DevServer] Client connected (subprotocol: $subprotocol)');
      _clients.add(channel);

      channel.stream.listen(
        (message) => _handleClientMessage(channel, message),
        onDone: () {
          print('[DevServer] Client disconnected');
          _clients.remove(channel);
        },
        onError: (e) {
          print('[DevServer] Client error: $e');
          _clients.remove(channel);
        },
      );

      // Send initial script list
      _sendScriptList(channel);
    });

    // 2. Start HTTP server
    _server = await shelf_io.serve(handler, 'localhost', port);
    print('[DevServer] Running at ws://localhost:$port');

    // 3. Start file watcher
    _watcher = DirectoryWatcher(watchDirectory);
    _watcher!.events.listen((event) {
      if (event.path.endsWith('.flux')) {
        print('[DevServer] File changed: ${event.path}');
        _recompileAndBroadcast(event.path);
      }
    });

    print('[DevServer] Watching: $watchDirectory');
  }

  /// Stops the dev server.
  Future<void> stop() async {
    await _server?.close();
    for (final client in _clients) {
      await client.sink.close();
    }
    _clients.clear();
    print('[DevServer] Stopped');
  }

  void _handleClientMessage(WebSocketChannel channel, dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'];

      switch (type) {
        case 'compile':
          final scriptPath = data['path'] as String;
          _compileAndSend(channel, scriptPath);
          break;
        case 'ping':
          channel.sink.add(jsonEncode({'type': 'pong'}));
          break;
      }
    } catch (e) {
      print('[DevServer] Error handling message: $e');
    }
  }

  void _sendScriptList(WebSocketChannel channel) {
    final dir = Directory(watchDirectory);
    final fluxFiles = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.flux'))
        .map((f) => f.path)
        .toList();

    channel.sink.add(jsonEncode({
      'type': 'scripts',
      'scripts': fluxFiles,
    }));
  }

  void _recompileAndBroadcast(String path) {
    try {
      final file = File(path);
      final source = file.readAsStringSync();
      final scriptName =
          path.split(Platform.pathSeparator).last.replaceAll('.flux', '');

      // Compile
      final lexer = Lexer(source);
      final parser = Parser(lexer.tokenize());
      final compilationUnit = parser.parse();
      final compiler = Compiler(moduleName: scriptName);

      for (final decl in compilationUnit.declarations) {
        compiler.compile(decl);
      }

      final function = compiler.endCompiler();

      // Serialize bytecode
      final bytecode = _serializeFunction(function);

      // Broadcast to all clients
      final message = jsonEncode({
        'type': 'reload',
        'script': scriptName,
        'path': path,
        'bytecode': bytecode,
        'timestamp': DateTime.now().toIso8601String(),
      });

      for (final client in _clients) {
        client.sink.add(message);
      }

      print('[DevServer] Broadcasted update for: $scriptName');
    } catch (e, stack) {
      // Send error to clients
      final message = jsonEncode({
        'type': 'error',
        'path': path,
        'error': e.toString(),
        'stack': stack.toString(),
      });

      for (final client in _clients) {
        client.sink.add(message);
      }

      print('[DevServer] Compilation error: $e');
    }
  }

  void _compileAndSend(WebSocketChannel channel, String path) {
    try {
      final file = File(path);
      final source = file.readAsStringSync();
      final scriptName =
          path.split(Platform.pathSeparator).last.replaceAll('.flux', '');

      final lexer = Lexer(source);
      final parser = Parser(lexer.tokenize());
      final compilationUnit = parser.parse();
      final compiler = Compiler(moduleName: scriptName);

      for (final decl in compilationUnit.declarations) {
        compiler.compile(decl);
      }

      final function = compiler.endCompiler();
      final bytecode = _serializeFunction(function);

      channel.sink.add(jsonEncode({
        'type': 'compiled',
        'script': scriptName,
        'path': path,
        'bytecode': bytecode,
      }));
    } catch (e) {
      channel.sink.add(jsonEncode({
        'type': 'error',
        'path': path,
        'error': e.toString(),
      }));
    }
  }

  /// Serializes a CompiledFunction to a transferable format.
  Map<String, dynamic> _serializeFunction(CompiledFunction fn) {
    return {
      'name': fn.name,
      'arity': fn.arity,
      'isAsync': fn.isAsync,
      'moduleName': fn.moduleName,
      'paramNames': fn.paramNames,
      'localNames': fn.localNames,
      'chunk': {
        'code': fn.chunk.code,
        'constants': fn.chunk.constants.map(_serializeConstant).toList(),
        'lines': fn.chunk.lines,
      },
    };
  }

  dynamic _serializeConstant(Object? value) {
    if (value == null) return null;
    if (value is num || value is String || value is bool) return value;
    if (value is CompiledFunction) {
      return {'type': 'function', 'data': _serializeFunction(value)};
    }
    return value.toString();
  }
}

/// CLI entry point for the dev server.
Future<void> runDevServer(List<String> args) async {
  final watchDir = args.isNotEmpty ? args[0] : '.';
  final port = args.length > 1 ? int.tryParse(args[1]) ?? 8765 : 8765;

  final server = FluxDevServer(watchDirectory: watchDir, port: port);
  await server.start();

  // Handle Ctrl+C
  ProcessSignal.sigint.watch().listen((_) async {
    await server.stop();
    exit(0);
  });

  // Keep running
  await Completer<void>().future;
}
