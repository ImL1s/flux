import 'dart:convert';
import 'package:cryptography/cryptography.dart';

/// Verifies Flux scripts using Ed25519 signatures
class FluxScriptVerifier {
  static const String _signaturePrefix = '// @flux-signature: ';

  /// Verify the signature of a script
  ///
  /// [scriptContent] is the full content of the script file.
  /// [publicKeyBytes] is the Ed25519 public key bytes (32 bytes).
  ///
  /// Returns check if the signature is valid for the content.
  Future<bool> verify(String scriptContent, List<int> publicKeyBytes) async {
    final lines = LineSplitter.split(scriptContent).toList();
    if (lines.isEmpty) return false;

    // Check for signature in the last line
    final lastLine = lines.last.trim();
    if (!lastLine.startsWith(_signaturePrefix)) {
      return false;
    }

    final signatureBase64 = lastLine.substring(_signaturePrefix.length);
    List<int> signatureBytes;
    try {
      signatureBytes = base64Decode(signatureBase64);
    } catch (e) {
      return false;
    }

    // Content to verify is everything excluding the signature line
    final contentToVerify = lines.sublist(0, lines.length - 1).join('\n');
    final contentBytes = utf8.encode(contentToVerify);

    final algorithm = Ed25519();
    final publicKey =
        SimplePublicKey(publicKeyBytes, type: KeyPairType.ed25519);
    final signature = Signature(signatureBytes, publicKey: publicKey);

    return algorithm.verify(
      contentBytes,
      signature: signature,
    );
  }
}

int min(int a, int b) => a < b ? a : b;
