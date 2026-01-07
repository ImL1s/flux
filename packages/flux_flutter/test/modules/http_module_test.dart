import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:flux_flutter/src/modules/http_module.dart';
import 'package:flux_vm/flux_vm.dart';

void main() {
  late HttpModule httpModule;
  late Dio dio;
  late DioAdapter dioAdapter;

  setUp(() {
    dio = Dio();
    dioAdapter = DioAdapter(dio: dio);
    httpModule = HttpModule(dio: dio);
  });

  test('http.get returns standardized response map', () async {
    final url = 'https://example.com';
    final args = [url];
    final fn = httpModule.get('get') as AsyncNativeFunction;

    dioAdapter.onGet(
      url,
      (server) => server.reply(
        200,
        '{"foo": "bar"}',
        headers: {'content-type': ['application/json']},
      ),
    );

    final result = await fn.call(args);

    expect(result, isA<Map<String, dynamic>>());
    final map = result! as Map<String, dynamic>;
    expect(map['statusCode'], 200);
    expect(map['body'], {'foo': 'bar'});
    expect(map['headers'], containsPair('content-type', 'application/json'));
    expect(map['ok'], true);
  });

  test('http.post returns response', () async {
    final url = 'https://api.com';
    final args = [
      url,
      {'body': 'data'}
    ];
    final fn = httpModule.get('post') as AsyncNativeFunction;

    dioAdapter.onPost(
      url,
      (server) => server.reply(201, 'ok'),
      data: 'data',
    );

    final result = await fn.call(args);

    expect(result, isA<Map<String, dynamic>>());
    final map = result! as Map<String, dynamic>;
    expect(map['statusCode'], 201);
    expect(map['ok'], true);
  });
}
