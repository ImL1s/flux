import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_updater/flux_updater.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

void main() {
  group('Flux OTA E2E Tests', () {
    late FluxOtaServer server;
    late HttpServer httpServer;
    late String serverUrl;

    setUpAll(() async {
      server = FluxOtaServer(signingKey: 'test-secret-key');
      httpServer = await shelf_io.serve(server.handler, 'localhost', 0);
      serverUrl = 'http://localhost:${httpServer.port}';
    });

    tearDownAll(() async {
      await httpServer.close();
    });

    test('health check works', () async {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('$serverUrl/health'));
      final response = await request.close();
      expect(response.statusCode, equals(200));
      client.close();
    });

    test('upload and retrieve release', () async {
      final client = HttpClient();

      // Compile a simple Flux program
      final source = '''
        widget HelloWorld {
          build {
            Text("Hello, World!")
          }
        }
      ''';

      final lexer = Lexer(source);
      final tokens = lexer.tokenize();
      final parser = Parser(tokens);
      final unit = parser.parse();
      final compiler = Compiler(unit: unit);
      final func = compiler.endCompiler();
      final chunkBytes = ChunkSerializer.serialize(func.chunk);

      // Upload release
      final uploadRequest = await client.postUrl(Uri.parse('$serverUrl/releases'));
      uploadRequest.headers.contentType = ContentType.json;
      uploadRequest.write(jsonEncode({
        'appId': 'com.example.test',
        'version': '1.0.0',
        'buildNumber': 1,
        'chunk': chunkBytes.toList(),
      }));
      final uploadResponse = await uploadRequest.close();
      expect(uploadResponse.statusCode, equals(200));

      // Get latest version
      final latestRequest = await client.getUrl(
        Uri.parse('$serverUrl/releases/com.example.test/latest'),
      );
      final latestResponse = await latestRequest.close();
      expect(latestResponse.statusCode, equals(200));

      final latestBody = await latestResponse.transform(utf8.decoder).join();
      final latestJson = jsonDecode(latestBody) as Map<String, dynamic>;
      expect(latestJson['version'], equals('1.0.0'));
      expect(latestJson['buildNumber'], equals(1));

      client.close();
    });

    test('generates and downloads patch between versions', () async {
      final client = HttpClient();

      // Create v1.0.0
      final v1Source = '''
        widget TestWidget {
          build {
            Text("Version 1")
          }
        }
      ''';
      final v1Chunk = _compileSource(v1Source);

      // Create v1.1.0 (small change)
      final v2Source = '''
        widget TestWidget {
          build {
            Text("Version 2")
          }
        }
      ''';
      final v2Chunk = _compileSource(v2Source);

      // Upload v1.0.0
      await _uploadRelease(client, serverUrl, 'patch-test-app', '1.0.0', 1, v1Chunk);

      // Upload v1.1.0
      await _uploadRelease(client, serverUrl, 'patch-test-app', '1.1.0', 2, v2Chunk);

      // Download patch 1.0.0 -> 1.1.0
      final patchRequest = await client.getUrl(
        Uri.parse('$serverUrl/patches/patch-test-app/1.0.0/1.1.0'),
      );
      final patchResponse = await patchRequest.close();
      expect(patchResponse.statusCode, equals(200));

      final patchBytes = await patchResponse.fold<List<int>>(
        [],
        (prev, chunk) => [...prev, ...chunk],
      );

      // Patch should be smaller than full chunk
      print('V1 size: ${v1Chunk.length}');
      print('V2 size: ${v2Chunk.length}');
      print('Patch size: ${patchBytes.length}');
      expect(patchBytes.length, lessThan(v2Chunk.length));

      // Apply patch and verify result
      final restoredBytes = await FluxDiffManager.applyPatchToBytes(
        v1Chunk,
        Uint8List.fromList(patchBytes),
      );
      expect(restoredBytes, equals(v2Chunk));

      client.close();
    });

    test('UpdateManager integrates with server', () async {
      // Compile and upload a release
      final source = '''
        widget UpdateTest {
          build {
            Text("Managed Update")
          }
        }
      ''';
      _compileSource(source);
      final chunkBytes = _compileSource(source);

      // Register release directly in server
      final release = FluxRelease(
        appId: 'update-manager-test',
        version: '2.0.0',
        buildNumber: 100,
        chunk: chunkBytes,
        signature: SignatureUtils.sign(chunkBytes, 'test-secret-key'),
        createdAt: DateTime.now(),
      );
      server.registerRelease(release);

      // Create UpdateManager
      final versionManager = VersionManager();
      versionManager.registerRelease(release);

      Chunk? receivedChunk;
      final updateManager = FluxUpdateManager(
        appId: 'update-manager-test',
        serverUrl: serverUrl,
        signingKey: 'test-secret-key',
        currentBuildNumber: 1, // Old version
        versionManager: versionManager,
        onChunkReady: (newChunk) {
          receivedChunk = newChunk;
        },
      );

      // Check for updates
      final status = await updateManager.checkForUpdates();
      expect(status, equals(UpdateStatus.updateAvailable));

      // Download and apply
      final applyStatus = await updateManager.downloadAndApply();
      expect(applyStatus, equals(UpdateStatus.applied));
      expect(receivedChunk, isNotNull);
      expect(receivedChunk!.constants.isNotEmpty, isTrue);

      updateManager.dispose();
    });

    test('version comparison works correctly', () {
      expect(VersionManager.compareVersions('1.0.0', '1.0.0'), equals(0));
      expect(VersionManager.compareVersions('1.0.1', '1.0.0'), greaterThan(0));
      expect(VersionManager.compareVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(VersionManager.compareVersions('2.0.0', '1.9.9'), greaterThan(0));
      expect(VersionManager.compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(VersionManager.isNewer('1.1.0', '1.0.0'), isTrue);
      expect(VersionManager.isNewer('1.0.0', '1.1.0'), isFalse);
    });

    test('signature verification detects tampering', () {
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      final signature = SignatureUtils.sign(data, 'secret');

      // Valid signature
      expect(SignatureUtils.verify(data, signature, 'secret'), isTrue);

      // Wrong key
      expect(SignatureUtils.verify(data, signature, 'wrong-key'), isFalse);

      // Tampered data
      final tampered = Uint8List.fromList([1, 2, 3, 4, 6]);
      expect(SignatureUtils.verify(tampered, signature, 'secret'), isFalse);
    });

    test('rollback mechanism works', () async {
      final versionManager = VersionManager();

      // Create two versions
      final v1Chunk = _compileSource('widget V1 { build { Text("v1") } }');
      final v2Chunk = _compileSource('widget V2 { build { Text("v2") } }');

      final v1 = FluxRelease(
        appId: 'rollback-test',
        version: '1.0.0',
        buildNumber: 1,
        chunk: v1Chunk,
        signature: SignatureUtils.sign(v1Chunk, 'test'),
        createdAt: DateTime.now(),
      );
      final v2 = FluxRelease(
        appId: 'rollback-test',
        version: '2.0.0',
        buildNumber: 2,
        chunk: v2Chunk,
        signature: SignatureUtils.sign(v2Chunk, 'test'),
        createdAt: DateTime.now(),
      );

      versionManager.registerRelease(v1);
      versionManager.registerRelease(v2);

      Chunk? currentChunk;
      final updateManager = FluxUpdateManager(
        appId: 'rollback-test',
        serverUrl: serverUrl,
        signingKey: 'test',
        currentBuildNumber: 2,
        currentChunk: ChunkSerializer.deserialize(v2Chunk),
        versionManager: versionManager,
        onChunkReady: (chunk) {
          currentChunk = chunk;
        },
      );

      // Rollback to v1
      final success = await updateManager.rollback('1.0.0');
      expect(success, isTrue);
      expect(currentChunk, isNotNull);

      updateManager.dispose();
    });
  });
}

Uint8List _compileSource(String source) {
  final lexer = Lexer(source);
  final tokens = lexer.tokenize();
  final parser = Parser(tokens);
  final unit = parser.parse();
  final compiler = Compiler(unit: unit);
  final func = compiler.endCompiler();
  return ChunkSerializer.serialize(func.chunk);
}

Future<void> _uploadRelease(
  HttpClient client,
  String serverUrl,
  String appId,
  String version,
  int buildNumber,
  Uint8List chunk,
) async {
  final request = await client.postUrl(Uri.parse('$serverUrl/releases'));
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode({
    'appId': appId,
    'version': version,
    'buildNumber': buildNumber,
    'chunk': chunk.toList(),
  }));
  await request.close();
}
