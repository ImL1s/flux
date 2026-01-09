import 'dart:convert';
import 'dart:io';

import 'package:flux_compiler/flux_compiler.dart';
import 'package:path/path.dart' as p;

import 'package:flux_updater/src/chunk_serializer.dart';
import 'package:flux_updater/src/signature_utils.dart';

/// CLI tool for managing Flux OTA releases.
///
/// Commands:
/// - flux_updater compile <source.flux> -o <output.fluxc>
/// - flux_updater release --app-id <id> --version <ver> --build <num> <file.fluxc>
/// - flux_updater push --server <url> <file.fluxc>
Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    _printUsage();
    exit(1);
  }

  final command = args[0];
  final rest = args.sublist(1);

  switch (command) {
    case 'compile':
      await _handleCompile(rest);
      break;
    case 'release':
      await _handleRelease(rest);
      break;
    case 'push':
      await _handlePush(rest);
      break;
    case 'info':
      await _handleInfo(rest);
      break;
    case 'help':
    case '--help':
    case '-h':
      _printUsage();
      break;
    default:
      print('Unknown command: $command');
      _printUsage();
      exit(1);
  }
}

void _printUsage() {
  print('''
Flux Updater CLI

Usage: flux_updater <command> [options]

Commands:
  compile <source.flux> -o <output.fluxc>
      Compile a Flux source file to bytecode.

  release --app-id <id> --version <ver> --build <num> <file.fluxc>
      Create a signed release package.

  push --server <url> <file.fluxc>
      Upload a compiled file to the OTA server.

  info <file.fluxc>
      Show information about a compiled file.

  help
      Show this help message.

Environment:
  FLUX_SIGNING_KEY  Secret key for signing releases (default: dev-secret-key)
''');
}

Future<void> _handleCompile(List<String> args) async {
  if (args.isEmpty) {
    print('Error: No input file specified');
    exit(1);
  }

  String? inputFile;
  String? outputFile;

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '-o' && i + 1 < args.length) {
      outputFile = args[++i];
    } else if (!args[i].startsWith('-')) {
      inputFile = args[i];
    }
  }

  if (inputFile == null) {
    print('Error: No input file specified');
    exit(1);
  }

  outputFile ??= p.setExtension(inputFile, '.fluxc');

  print('Compiling $inputFile -> $outputFile');

  try {
    final source = await File(inputFile).readAsString();
    final lexer = Lexer(source);
    final tokens = lexer.tokenize();
    final parser = Parser(tokens);
    final unit = parser.parse();

    if (parser.errors.isNotEmpty) {
      print('Compilation errors:');
      for (final error in parser.errors) {
        print('  $error');
      }
      exit(1);
    }

    final compiler = Compiler(unit: unit);
    final func = compiler.endCompiler();
    final bytes = ChunkSerializer.serialize(func.chunk);

    await File(outputFile).writeAsBytes(bytes);
    print('✅ Compiled successfully (${bytes.length} bytes)');
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

Future<void> _handleRelease(List<String> args) async {
  String? appId;
  String? version;
  int? buildNumber;
  String? inputFile;

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--app-id' && i + 1 < args.length) {
      appId = args[++i];
    } else if (args[i] == '--version' && i + 1 < args.length) {
      version = args[++i];
    } else if (args[i] == '--build' && i + 1 < args.length) {
      buildNumber = int.parse(args[++i]);
    } else if (!args[i].startsWith('-')) {
      inputFile = args[i];
    }
  }

  if (appId == null ||
      version == null ||
      buildNumber == null ||
      inputFile == null) {
    print('Error: Missing required arguments');
    print(
        'Usage: flux_updater release --app-id <id> --version <ver> --build <num> <file.fluxc>');
    exit(1);
  }

  final signingKey =
      Platform.environment['FLUX_SIGNING_KEY'] ?? 'dev-secret-key';

  try {
    final bytes = await File(inputFile).readAsBytes();
    final signature = SignatureUtils.sign(bytes, signingKey);
    final fingerprint = SignatureUtils.fingerprint(bytes);

    print('Release Info:');
    print('  App ID: $appId');
    print('  Version: $version');
    print('  Build: $buildNumber');
    print('  Size: ${bytes.length} bytes');
    print('  Fingerprint: $fingerprint');
    print('  Signature: ${signature.substring(0, 16)}...');

    // Create release manifest
    final manifest = {
      'appId': appId,
      'version': version,
      'buildNumber': buildNumber,
      'chunkSize': bytes.length,
      'fingerprint': fingerprint,
      'signature': signature,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final manifestFile = p.setExtension(inputFile, '.manifest.json');
    await File(manifestFile).writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
    );
    print('✅ Created manifest: $manifestFile');
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

Future<void> _handlePush(List<String> args) async {
  String? serverUrl;
  String? inputFile;

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--server' && i + 1 < args.length) {
      serverUrl = args[++i];
    } else if (!args[i].startsWith('-')) {
      inputFile = args[i];
    }
  }

  serverUrl ??= 'http://localhost:8080';

  if (inputFile == null) {
    print('Error: No input file specified');
    exit(1);
  }

  // Check for manifest
  final manifestFile = p.setExtension(inputFile, '.manifest.json');
  if (!await File(manifestFile).exists()) {
    print('Error: Manifest not found. Run "flux_updater release" first.');
    exit(1);
  }

  try {
    final bytes = await File(inputFile).readAsBytes();
    final manifestJson = await File(manifestFile).readAsString();
    final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;

    print('Pushing to $serverUrl...');

    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('$serverUrl/releases'));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({
      'appId': manifest['appId'],
      'version': manifest['version'],
      'buildNumber': manifest['buildNumber'],
      'chunk': bytes.toList(),
    }));

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      final result = jsonDecode(responseBody);
      print('✅ Pushed successfully!');
      print('  Version: ${result['version']}');
      print('  Patches generated: ${result['patchesGenerated']}');
    } else {
      print('❌ Push failed: $responseBody');
      exit(1);
    }

    client.close();
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

Future<void> _handleInfo(List<String> args) async {
  if (args.isEmpty) {
    print('Error: No input file specified');
    exit(1);
  }

  final inputFile = args[0];

  try {
    final bytes = await File(inputFile).readAsBytes();
    final chunk = ChunkSerializer.deserialize(bytes);
    final fingerprint = SignatureUtils.fingerprint(bytes);

    print('File: $inputFile');
    print('Size: ${bytes.length} bytes');
    print('Fingerprint: $fingerprint');
    print('Code: ${chunk.code.length} instructions');
    print('Constants: ${chunk.constants.length}');
    print('Lines: ${chunk.lines.length ~/ 2} entries (RLE)');
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
