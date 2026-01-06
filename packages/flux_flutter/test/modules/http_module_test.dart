import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flux_flutter/src/modules/http_module.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  late HttpModule httpModule;

  setUp(() {
    httpModule = HttpModule();
  });

  test('http.get returns standardized response map', () async {
    final args = ['https://example.com'];
    final fn = httpModule.get('get') as AsyncNativeFunction;

    final mockClient = MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.toString() == 'https://example.com') {
        return http.Response('{"foo": "bar"}', 200,
            headers: {'content-type': 'application/json'});
      }
      return http.Response('Not Found', 404);
    });

    await http.runWithClient(() async {
      final result = await fn.call(args);

      expect(result, isA<Map>());
      final map = result as Map;
      expect(map['statusCode'], 200);
      expect(map['body'], '{"foo": "bar"}');
      expect(map['headers'], containsPair('content-type', 'application/json'));
    }, () => mockClient);
  });

  test('http.post returns response', () async {
    final args = [
      'https://api.com',
      {'body': 'data'}
    ];
    final fn = httpModule.get('post') as AsyncNativeFunction;

    final mockClient = MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.toString() == 'https://api.com') {
        return http.Response('ok', 201);
      }
      return http.Response('Error', 500);
    });

    await http.runWithClient(() async {
      final result = await fn.call(args);

      expect(result, isA<Map>());
      expect((result as Map)['statusCode'], 201);
    }, () => mockClient);
  });
}
