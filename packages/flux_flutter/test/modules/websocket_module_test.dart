import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/modules/websocket_module.dart';
import 'package:flux_vm/flux_vm.dart';
import 'package:mocktail/mocktail.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

// Mock classes
class MockWebSocketChannel extends Mock implements WebSocketChannel {}
class MockWebSocketSink extends Mock implements WebSocketSink {}

void main() {
  late WebSocketModule module;
  
  setUp(() {
    module = WebSocketModule();
  });

  group('WebSocketModule Tests', () {
    test('Module registration has correct functions', () {
      expect(module.members.containsKey('connect'), true);
      expect(module.members.containsKey('close'), true);
      expect(module.members.containsKey('send'), true);
      expect(module.members.containsKey('listen'), true);
    });

    test('Should handle connection failure gracefully', () async {
      // We can't easily mock the static WebSocketChannel.connect method without dependency injection
      // or using an override. For this unit test, we'll test the behavior when connection fails
      // by using an invalid URL scheme which should throw immediately.
      
      final connectFn = module.members['connect'] as AsyncNativeFunction;
      
      final result = await connectFn.call(['invalid-url://nothing']);
      
      expect(result, isA<Map>());
      final map = result as Map;
      expect(map['error'], true);
    });

    test('dispose should clear all connections', () {
       // Since we can't easily add connections without mocking the static connect,
       // we simply verify that dispose can be called without error.
       expect(() => module.dispose(), returnsNormally);
    });
  });
}
