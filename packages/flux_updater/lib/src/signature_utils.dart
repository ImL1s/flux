import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Utilities for cryptographic signing and verification of Flux releases.
///
/// Uses SHA-256 for hashing. For production, consider using RSA or ECDSA
/// for asymmetric signing.
class SignatureUtils {
  /// Generate a SHA-256 signature for the given bytes.
  ///
  /// For production, this should use a private key for signing.
  /// This implementation uses HMAC-SHA256 with a secret key.
  static String sign(Uint8List data, String secretKey) {
    final key = utf8.encode(secretKey);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(data);
    return digest.toString();
  }

  /// Verify a signature against the data.
  static bool verify(Uint8List data, String signature, String secretKey) {
    final expected = sign(data, secretKey);
    return _constantTimeEquals(signature, expected);
  }

  /// Generate a simple hash of the data (without key).
  static String hash(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  /// Generate a version fingerprint for quick comparison.
  ///
  /// This is a shorter hash suitable for display and quick checks.
  static String fingerprint(Uint8List data) {
    final fullHash = hash(data);
    // Return first 16 characters for brevity
    return fullHash.substring(0, 16);
  }

  /// Constant-time string comparison to prevent timing attacks.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
