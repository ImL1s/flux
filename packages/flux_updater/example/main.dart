/// Flux OTA Example
///
/// This example demonstrates the complete OTA update workflow:
/// 1. Compiling Flux source to bytecode
/// 2. Creating releases with signing
/// 3. Uploading to OTA server
/// 4. Checking for updates
/// 5. Downloading and applying patches
///
/// Run with: dart run example/main.dart
library;

import 'package:flux_compiler/flux_compiler.dart';
import 'package:flux_updater/flux_updater.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

const signingKey = 'example-secret-key';
const appId = 'com.example.flux_ota_demo';

Future<void> main() async {
  print('╔═══════════════════════════════════════════════════════════╗');
  print('║           Flux OTA System - Complete Example              ║');
  print('╚═══════════════════════════════════════════════════════════╝\n');

  // Step 1: Start OTA Server
  print('📡 Starting OTA Server...');
  final server = FluxOtaServer(signingKey: signingKey);
  final httpServer = await shelf_io.serve(server.handler, 'localhost', 0);
  final serverUrl = 'http://localhost:${httpServer.port}';
  print('   Server running at: $serverUrl\n');

  // Step 2: Compile Version 1.0.0
  print('🔨 Compiling Version 1.0.0...');
  final v1Source = '''
    widget Counter {
      state count = 0;
      build {
        Column {
          Text("Count: " + toString(count))
          Button("Increment", onPressed: fn() {
            count = count + 1;
          })
        }
      }
    }
  ''';
  final v1Chunk = compileSource(v1Source);
  final v1Bytes = ChunkSerializer.serialize(v1Chunk);
  print('   Compiled: ${v1Bytes.length} bytes\n');

  // Step 3: Upload Version 1.0.0
  print('📤 Uploading Version 1.0.0...');
  final v1Release = FluxRelease(
    appId: appId,
    version: '1.0.0',
    buildNumber: 1,
    chunk: v1Bytes,
    signature: SignatureUtils.sign(v1Bytes, signingKey),
    createdAt: DateTime.now(),
  );
  server.registerRelease(v1Release);
  print('   Uploaded successfully!\n');

  // Step 4: Compile Version 1.1.0 (with a small change)
  print('🔨 Compiling Version 1.1.0...');
  final v2Source = '''
    widget Counter {
      state count = 0;
      build {
        Column {
          Text("Count: " + toString(count))
          Text("v1.1.0 - Now with double increment!")
          Button("Increment x2", onPressed: fn() {
            count = count + 2;
          })
        }
      }
    }
  ''';
  final v2Chunk = compileSource(v2Source);
  final v2Bytes = ChunkSerializer.serialize(v2Chunk);
  print('   Compiled: ${v2Bytes.length} bytes\n');

  // Step 5: Upload Version 1.1.0
  print('📤 Uploading Version 1.1.0...');
  final v2Release = FluxRelease(
    appId: appId,
    version: '1.1.0',
    buildNumber: 2,
    chunk: v2Bytes,
    signature: SignatureUtils.sign(v2Bytes, signingKey),
    createdAt: DateTime.now(),
  );
  server.registerRelease(v2Release);
  print('   Uploaded successfully!\n');

  // Step 6: Generate diff patch
  print('🔧 Generating diff patch...');
  final patch = await FluxDiffManager.createPatchFromBytes(v1Bytes, v2Bytes);
  final compressionRatio = (patch.length / v2Bytes.length * 100).toStringAsFixed(1);
  print('   Full chunk: ${v2Bytes.length} bytes');
  print('   Patch size: ${patch.length} bytes');
  print('   Compression: $compressionRatio%\n');

  // Step 7: Simulate client-side update check
  print('📱 Simulating client update check...');
  final versionManager = VersionManager();
  versionManager.registerRelease(v1Release);
  versionManager.registerRelease(v2Release);

  Chunk? receivedUpdate;
  final updateManager = FluxUpdateManager(
    appId: appId,
    serverUrl: serverUrl,
    signingKey: signingKey,
    currentBuildNumber: 1, // Currently on v1.0.0
    currentChunk: v1Chunk,
    versionManager: versionManager,
    onChunkReady: (chunk) {
      receivedUpdate = chunk;
      print('   ✅ Received updated chunk!');
    },
  );

  // Listen to progress
  updateManager.progressStream.listen((progress) {
    print('   Status: ${progress.status.name} - ${progress.message ?? ""}');
  });

  // Check for updates
  final status = await updateManager.checkForUpdates();
  print('   Update available: ${status == UpdateStatus.updateAvailable}\n');

  // Download and apply
  print('⬇️  Downloading and applying update...');
  final applyResult = await updateManager.downloadAndApply();
  print('   Result: ${applyResult.name}');
  print('   New build: ${updateManager.currentBuildNumber}\n');

  // Step 8: Verify update
  print('✅ Verification:');
  print('   Update received: ${receivedUpdate != null}');
  if (receivedUpdate != null) {
    print('   New chunk constants: ${receivedUpdate!.constants.length}');
  }

  // Step 9: Demonstrate rollback
  print('\n⏪ Demonstrating rollback to v1.0.0...');
  final rollbackSuccess = await updateManager.rollback('1.0.0');
  print('   Rollback success: $rollbackSuccess');
  print('   Current build: ${updateManager.currentBuildNumber}');

  // Cleanup
  updateManager.dispose();
  await httpServer.close();

  print('\n╔═══════════════════════════════════════════════════════════╗');
  print('║                    Example Complete!                       ║');
  print('╚═══════════════════════════════════════════════════════════╝');
}

Chunk compileSource(String source) {
  final lexer = Lexer(source);
  final tokens = lexer.tokenize();
  final parser = Parser(tokens);
  final unit = parser.parse();
  if (parser.errors.isNotEmpty) {
    throw Exception('Compilation failed: ${parser.errors}');
  }
  final compiler = Compiler(unit: unit);
  return compiler.endCompiler().chunk;
}
