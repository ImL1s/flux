import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'chunk_serializer.dart';
import 'diff_manager.dart';
import 'flux_release.dart';

/// HTTP client for communicating with the Flux OTA server.
class FluxOtaClient {
  final String serverUrl;
  final http.Client _client;

  FluxOtaClient({
    required this.serverUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Check for the latest version of an app.
  Future<VersionInfo?> getLatestVersion(String appId) async {
    try {
      final response = await _client.get(
        Uri.parse('$serverUrl/releases/$appId/latest'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return VersionInfo.fromJson(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Download a patch between two versions.
  Future<Uint8List?> downloadPatch(
    String appId,
    String fromVersion,
    String toVersion,
  ) async {
    try {
      final response = await _client.get(
        Uri.parse('$serverUrl/patches/$appId/$fromVersion/$toVersion'),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Download a full chunk for a specific version.
  Future<Uint8List?> downloadChunk(String appId, String version) async {
    try {
      final response = await _client.get(
        Uri.parse('$serverUrl/chunks/$appId/$version'),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Upload a new release.
  Future<bool> uploadRelease({
    required String appId,
    required String version,
    required int buildNumber,
    required Uint8List chunk,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$serverUrl/releases'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'appId': appId,
          'version': version,
          'buildNumber': buildNumber,
          'chunk': chunk.toList(),
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Check server health.
  Future<bool> healthCheck() async {
    try {
      final response = await _client.get(Uri.parse('$serverUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void close() {
    _client.close();
  }
}
