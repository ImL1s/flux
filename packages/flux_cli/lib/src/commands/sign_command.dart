import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cryptography/cryptography.dart';

class SignCommand extends Command {
  @override
  final String name = 'sign';

  @override
  final String description = 'Sign a Flux script file using a private key.';

  SignCommand() {
    argParser.addOption(
      'key',
      abbr: 'k',
      help: 'Path to private key file.',
      defaultsTo: 'flux_key.priv',
    );
  }

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      print('Usage: flux sign <script_file> [options]');
      exit(1);
    }

    final scriptPath = argResults!.rest.first;
    final scriptFile = File(scriptPath);

    if (!scriptFile.existsSync()) {
      print('Error: Script file not found: $scriptPath');
      exit(1);
    }

    final keyPath = argResults?['key'];
    final keyFile = File(keyPath);

    if (!keyFile.existsSync()) {
      print('Error: Private key not found: $keyPath');
      print('Run "flux keygen" to generate a key pair.');
      exit(1);
    }

    // Read and decode private key
    final privateKeyBase64 = keyFile.readAsStringSync().trim();
    final privateKeyBytes = base64Decode(privateKeyBase64);

    // Read script content
    final lines = scriptFile.readAsLinesSync();

    // Remove existing signature if present
    if (lines.isNotEmpty &&
        lines.last.trim().startsWith('// @flux-signature: ')) {
      lines.removeLast();
    }

    // Content to sign (joined by \n to ensure consistency)
    final contentToSign = lines.join('\n');
    final contentBytes = utf8.encode(contentToSign);

    // Sign
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes);
    final signature = await algorithm.sign(
      contentBytes,
      keyPair: keyPair,
    );

    final signatureBase64 = base64Encode(signature.bytes);

    // Append signature to file
    final signedContent =
        contentToSign + '\n// @flux-signature: $signatureBase64';
    await scriptFile.writeAsString(signedContent);

    print('Successfully signed $scriptPath');
    print('Signature appended to file footer.');
  }
}
