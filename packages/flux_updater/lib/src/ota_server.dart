import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../src/chunk_serializer.dart';
import '../src/diff_manager.dart';
import '../src/flux_release.dart';
import '../src/signature_utils.dart';

/// Simple in-memory OTA server for development and testing.
///
/// Endpoints:
/// - POST /releases - Upload a new release
/// - GET /releases/:appId/latest - Get latest version info
/// - GET /releases/:appId/:version - Get specific version info
/// - GET /patches/:appId/:fromVersion/:toVersion - Download patch
/// - GET /chunks/:appId/:version - Download full chunk
class FluxOtaServer {
  final String signingKey;
  final Map<String, Map<String, FluxRelease>> _releases = {};
  final Map<String, Uint8List> _patches = {}; // key: appId:from:to

  FluxOtaServer({this.signingKey = 'dev-secret-key'});

  Router get router {
    final router = Router();

    // Upload new release
    router.post('/releases', _handleUpload);

    // Get latest version
    router.get('/releases/<appId>/latest', _handleGetLatest);

    // Get specific version
    router.get('/releases/<appId>/<version>', _handleGetVersion);

    // Download patch
    router.get('/patches/<appId>/<fromVersion>/<toVersion>', _handleGetPatch);

    // Download full chunk
    router.get('/chunks/<appId>/<version>', _handleGetChunk);

    // Health check
    router.get('/health', (Request req) => Response.ok('OK'));

    return router;
  }

  Handler get handler => router.call;

  Future<Response> _handleUpload(Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final appId = json['appId'] as String;
      final version = json['version'] as String;
      final buildNumber = json['buildNumber'] as int;
      final chunkBytes = Uint8List.fromList(
        (json['chunk'] as List).cast<int>(),
      );

      // Generate signature
      final signature = SignatureUtils.sign(chunkBytes, signingKey);

      // Create release
      final release = FluxRelease(
        appId: appId,
        version: version,
        buildNumber: buildNumber,
        chunk: chunkBytes,
        signature: signature,
        createdAt: DateTime.now(),
      );

      // Store release
      _releases.putIfAbsent(appId, () => {});
      _releases[appId]![version] = release;

      // Generate patches from previous versions
      final versions = _releases[appId]!;
      for (final entry in versions.entries) {
        if (entry.key != version) {
          final patchKey = '$appId:${entry.key}:$version';
          final patch = await FluxDiffManager.createPatchFromBytes(
            entry.value.chunk,
            chunkBytes,
          );
          _patches[patchKey] = patch;
        }
      }

      return Response.ok(
        jsonEncode({
          'success': true,
          'version': version,
          'signature': signature,
          'patchesGenerated': _patches.keys
              .where((k) => k.startsWith(appId) && k.endsWith(version))
              .length,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _handleGetLatest(Request request, String appId) async {
    final versions = _releases[appId];
    if (versions == null || versions.isEmpty) {
      return Response.notFound(
        jsonEncode({'error': 'No releases for app: $appId'}),
        headers: {'content-type': 'application/json'},
      );
    }

    // Find latest by build number
    final latest = versions.values.reduce(
      (a, b) => a.buildNumber > b.buildNumber ? a : b,
    );

    return Response.ok(
      jsonEncode(latest.toVersionInfo()),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _handleGetVersion(
    Request request,
    String appId,
    String version,
  ) async {
    final release = _releases[appId]?[version];
    if (release == null) {
      return Response.notFound(
        jsonEncode({'error': 'Version not found: $appId@$version'}),
        headers: {'content-type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode(release.toVersionInfo()),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> _handleGetPatch(
    Request request,
    String appId,
    String fromVersion,
    String toVersion,
  ) async {
    final patchKey = '$appId:$fromVersion:$toVersion';
    final patch = _patches[patchKey];

    if (patch == null) {
      return Response.notFound(
        jsonEncode({'error': 'Patch not found: $patchKey'}),
        headers: {'content-type': 'application/json'},
      );
    }

    return Response.ok(
      patch,
      headers: {
        'content-type': 'application/octet-stream',
        'content-length': patch.length.toString(),
      },
    );
  }

  Future<Response> _handleGetChunk(
    Request request,
    String appId,
    String version,
  ) async {
    final release = _releases[appId]?[version];
    if (release == null) {
      return Response.notFound(
        jsonEncode({'error': 'Version not found: $appId@$version'}),
        headers: {'content-type': 'application/json'},
      );
    }

    return Response.ok(
      release.chunk,
      headers: {
        'content-type': 'application/octet-stream',
        'content-length': release.chunk.length.toString(),
      },
    );
  }

  /// Register a release directly (for testing)
  void registerRelease(FluxRelease release) {
    _releases.putIfAbsent(release.appId, () => {});
    _releases[release.appId]![release.version] = release;
  }

  /// Get all releases for an app
  List<FluxRelease> getReleases(String appId) {
    return _releases[appId]?.values.toList() ?? [];
  }
}
