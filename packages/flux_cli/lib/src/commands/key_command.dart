import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cryptography/cryptography.dart';

class KeyCommand extends Command {
  @override
  final String name = 'keygen';

  @override
  final String description = 'Generate a new Ed25519 key pair for signing scripts.';

  KeyCommand() {
    argParser.addOption(
      'out',
      abbr: 'o',
      help: 'Output directory for keys.',
      defaultsTo: '.',
    );
  }

  @override
  Future<void> run() async {
    final outDir = argResults?['out'] as String;
    
    print('Generating new Ed25519 key pair...');
    
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    
    // Save private key (flux_key.pem - actually just base64 for now for simplicity, 
    // real PEM requires standard compatible encoding, keeping it simple consistent with plan)
    final privateKeyFile = File('$outDir/flux_key.priv');
    await privateKeyFile.writeAsString(base64Encode(privateKeyBytes));
    print('Private key saved to: ${privateKeyFile.path}');
    
    // Save public key
    final publicKeyFile = File('$outDir/flux_key.pub');
    await publicKeyFile.writeAsString(base64Encode(publicKey.bytes));
    print('Public key saved to: ${publicKeyFile.path}');
    
    print('');
    print('KEEP YOUR PRIVATE KEY SAFE! Anyone with it can sign scripts as you.');
  }
}
