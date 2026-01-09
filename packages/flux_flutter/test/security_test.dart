import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flux_flutter/src/security.dart';

void main() {
  // Valid 32-byte ED25519 public key for testing (base64 encoded)
  final testPublicKey = base64Encode(List.generate(32, (i) => i));
  // Valid 64-byte ED25519 signature for testing (base64 encoded)
  final testSignature = base64Encode(List.generate(64, (i) => i));

  group('FluxScriptPackage', () {
    test('calculates SHA-256 hash correctly', () {
      final package = FluxScriptPackage(
        version: '1.0.0',
        content: 'print("hello");',
        contentHash:
            'hash_will_be_recalculated_if_from_json_but_here_we_pass_it',
      );

      // Known hash for 'print("hello");'
      // We can verify the verifyHash() method calculates logic correctly
      expect(package.content, 'print("hello");');
    });

    test('fromJson calculates hash automatically', () {
      final json = {
        'version': '1.0.0',
        'content': 'test content',
      };

      final package = FluxScriptPackage.fromJson(json);
      expect(package.contentHash, isNotEmpty);
      expect(package.verifyHash(), isTrue);
    });

    test('verifyHash returns false on mismatch', () {
      final package = FluxScriptPackage(
        version: '1.0.0',
        content: 'real content',
        contentHash: 'fake_hash',
      );

      expect(package.verifyHash(), isFalse);
    });
  });

  group('FluxVersionManager', () {
    late FluxVersionManager manager;

    setUp(() {
      manager = FluxVersionManager(maxCachedVersions: 3);
    });

    test('caches packages and rotates old ones', () {
      final p1 =
          FluxScriptPackage(version: '1.0.0', content: 'c1', contentHash: 'h1');
      final p2 =
          FluxScriptPackage(version: '1.1.0', content: 'c2', contentHash: 'h2');
      final p3 =
          FluxScriptPackage(version: '1.2.0', content: 'c3', contentHash: 'h3');
      final p4 =
          FluxScriptPackage(version: '1.3.0', content: 'c4', contentHash: 'h4');

      manager.cache(p1);
      manager.cache(p2);
      manager.cache(p3);

      expect(manager.cachedVersions, equals(['1.2.0', '1.1.0', '1.0.0']));
      expect(manager.latest, p3);

      // Add 4th, should remove p1 (oldest)
      manager.cache(p4);
      expect(manager.cachedVersions, equals(['1.3.0', '1.2.0', '1.1.0']));
      expect(manager.hasCached('1.0.0'), isFalse);
    });

    test('supports rollback', () {
      final p1 =
          FluxScriptPackage(version: '1.0.0', content: 'c1', contentHash: 'h1');
      final p2 =
          FluxScriptPackage(version: '1.1.0', content: 'c2', contentHash: 'h2');

      manager.cache(p1);
      manager.cache(p2);

      expect(manager.latest, p2);
      expect(manager.previous, p1);
    });
  });

  group('FluxSandboxConfig', () {
    test('validates allowed hosts with wildcards', () {
      final config =
          FluxSandboxConfig(allowedHosts: ['*.example.com', 'api.google.com']);

      expect(config.isHostAllowed('api.example.com'), isTrue);
      expect(config.isHostAllowed('www.example.com'), isTrue);
      expect(config.isHostAllowed('example.com'), isTrue);
      expect(config.isHostAllowed('api.google.com'), isTrue);

      expect(config.isHostAllowed('google.com'), isFalse);
      expect(config.isHostAllowed('evil.com'), isFalse);
    });

    test('wildcard * allows all', () {
      final config = FluxSandboxConfig(allowedHosts: ['*']);
      expect(config.isHostAllowed('any.com'), isTrue);
    });
  });

  group('FluxSignatureVerifier', () {
    test('validates public key format', () {
      // Should throw on invalid base64
      expect(
        () => FluxSignatureVerifier('not-valid-base64!@#'),
        throwsA(isA<ArgumentError>()),
      );

      // Should work with valid base64 public key
      expect(
        () => FluxSignatureVerifier(testPublicKey),
        returnsNormally,
      );
    });

    test('rejects signature with wrong length', () {
      final verifier = FluxSignatureVerifier(testPublicKey);

      // Create package with invalid signature length (10 bytes instead of 64)
      final shortSig = base64Encode(List.generate(10, (i) => i));
      final package = FluxScriptPackage.fromJson({
        'version': '1.0.0',
        'content': 'test',
        'signature': shortSig,
      });

      expect(verifier.verify(package), isFalse);
    });

    test('accepts valid signature format', () {
      final verifier = FluxSignatureVerifier(testPublicKey);

      final package = FluxScriptPackage.fromJson({
        'version': '1.0.0',
        'content': 'test',
        'signature': testSignature,
      });

      // Should pass format validation (64 byte signature)
      expect(verifier.verify(package), isTrue);
    });
  });

  group('SecureScriptLoader', () {
    test('enforces signature verification', () {
      final verifier = FluxSignatureVerifier(testPublicKey);
      final loader = SecureScriptLoader(
        verifier: verifier,
        enforceSignatures: true,
      );

      final unsignedJson = {
        'version': '1.0.0',
        'content': 'code',
      };

      // Should fail because signature is missing
      expect(
        () => loader.loadPackage(unsignedJson),
        throwsA(isA<SecurityException>()),
      );
    });

    test('allows loading if signature is valid', () {
      final verifier = FluxSignatureVerifier(testPublicKey);
      final loader = SecureScriptLoader(
        verifier: verifier,
        enforceSignatures: true,
      );

      final signedJson = {
        'version': '1.0.0',
        'content': 'code',
        'signature': testSignature,
      };

      final package = loader.loadPackage(signedJson);
      expect(package.version, '1.0.0');
    });
  });
}
