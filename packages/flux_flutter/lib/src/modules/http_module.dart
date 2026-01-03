import 'package:flux_vm/flux_vm.dart';
import 'package:http/http.dart' as http;

/// HTTP client module for Flux
/// 
/// Usage:
/// var res = await http.get("https://example.com");
/// print(res["statusCode"]);
/// print(res["body"]);
class HttpModule extends FluxModule {
  HttpModule() : super('http') {
    register('get', AsyncNativeFunction('http.get', 1, _get));
    register('post', AsyncNativeFunction('http.post', 2, _post));
    register('put', AsyncNativeFunction('http.put', 2, _put));
    register('delete', AsyncNativeFunction('http.delete', 1, _delete));
  }

  Future<Object?> _get(List<Object?> args) async {
    final url = args[0] as String;
    try {
      final response = await http.get(Uri.parse(url));
      return _formatResponse(response);
    } catch (e) {
      throw 'http.get error: $e';
    }
  }

  Future<Object?> _post(List<Object?> args) async {
    final url = args[0] as String;
    final options = args[1] as Map;
    
    final headers = (options['headers'] as Map?)?.cast<String, String>() ?? {};
    final body = options['body'];

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      return _formatResponse(response);
    } catch (e) {
      throw 'http.post error: $e';
    }
  }

  Map<String, dynamic> _formatResponse(http.Response response) {
    return {
      'statusCode': response.statusCode,
      'body': response.body,
      'headers': response.headers,
    };
  }

  Future<Object?> _put(List<Object?> args) async {
    final url = args[0] as String;
    final options = args.length > 1 ? args[1] as Map : {};
    
    final headers = (options['headers'] as Map?)?.cast<String, String>() ?? {};
    final body = options['body'];

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
      return _formatResponse(response);
    } catch (e) {
      throw 'http.put error: $e';
    }
  }

  Future<Object?> _delete(List<Object?> args) async {
    final url = args[0] as String;
    try {
      final response = await http.delete(Uri.parse(url));
      return _formatResponse(response);
    } catch (e) {
      throw 'http.delete error: $e';
    }
  }
}
