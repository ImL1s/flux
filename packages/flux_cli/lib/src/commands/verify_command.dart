import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:flux_vm/flux_vm.dart';

class VerifyCommand extends Command {
  @override
  final String name = 'verify';

  @override
  final String description =
      'Verify a Flux script signature using a public key.';

  VerifyCommand() {
    argParser.addOption(
      'key',
      abbr: 'k',
      help: 'Path to public key file.',
      defaultsTo: 'flux_key.pub',
    );
  }

  @override
  Future<void> run() async {
    if (argResults!.rest.isEmpty) {
      print('Usage: flux verify <script_file> [options]');
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
      print('Error: Public key not found: $keyPath');
      exit(1);
    }

    // Read and decode public key
    final publicKeyBase64 = keyFile.readAsStringSync().trim();
    final publicKeyBytes = base64Decode(publicKeyBase64);

    // Read script
    final scriptContent = scriptFile.readAsStringSync();

    // Verify
    final verifier = FluxScriptVerifier();
    final isValid = await verifier.verify(scriptContent, publicKeyBytes);

    if (isValid) {
      print(
          'VERIFIED: The script signature is valid and content is untampered.');
      exit(0);
    } else {
      stderr.writeln(
          'FAILED: Verification failed. The script may be tampered or signature invalid.');
      exit(1);
    }
  }
}
