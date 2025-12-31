import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flux_flutter/src/utils/flux_cast.dart';

/// Bindings for standard HTTP networking library
class HttpBindings {
  static Map<String, dynamic> get functions => {
    'http_get': _get,
    'http_post': _post,
  };

  /// http_get(url, [headers])
  static Future<Map<String, dynamic>> _get(List<Object?> args) async {
    if (args.isEmpty) {
      throw 'http_get requires at least 1 argument: url';
    }
    
    final url = FluxCast.toStr(args[0]);
    final headers = args.length > 1 ? _castHeaders(args[1]) : null;
    
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      return _responseToMap(response);
    } catch (e) {
      return {
        'statusCode': 0,
        'body': '',
        'error': e.toString(),
      };
    }
  }

  /// http_post(url, [body, headers])
  static Future<Map<String, dynamic>> _post(List<Object?> args) async {
    if (args.isEmpty) {
      throw 'http_post requires at least 1 argument: url';
    }
    
    final url = FluxCast.toStr(args[0]);
    final body = args.length > 1 ? args[1] : null;
    final headers = args.length > 2 ? _castHeaders(args[2]) : null;
    
    try {
      // Encode body as JSON if it's a Map/List and content-type is json
      Object? finalBody = body;
      Map<String, String>? finalHeaders = headers;

      if (body is Map || body is List) {
          // If body is structured, default to JSON unless specified otherwise
          finalHeaders ??= {};
          if (!finalHeaders.containsKey('Content-Type')) {
               finalHeaders['Content-Type'] = 'application/json';
          }
          
          if (finalHeaders['Content-Type']?.contains('application/json') == true) {
              finalBody = jsonEncode(body);
          }
      }

      final response = await http.post(
        Uri.parse(url), 
        headers: finalHeaders, 
        body: finalBody,
      );
      return _responseToMap(response);
    } catch (e) {
      return {
        'statusCode': 0,
        'body': '',
        'error': e.toString(),
      };
    }
  }

  static Map<String, String>? _castHeaders(Object? headers) {
    if (headers == null) return null;
    if (headers is Map) {
      return headers.map((key, value) => MapEntry(FluxCast.toStr(key), FluxCast.toStr(value)));
    }
    return null;
  }

  static Map<String, dynamic> _responseToMap(http.Response response) {
    // Try parse body as JSON if possible
    dynamic parsedBody = response.body;
    try {
        if (response.headers['content-type']?.contains('application/json') == true) {
             parsedBody = jsonDecode(response.body);
        }
    } catch (_) {
        // Keep string if parsing fails
    }

    return {
      'statusCode': response.statusCode,
      'body': parsedBody,
      'headers': response.headers,
    };
  }
}
