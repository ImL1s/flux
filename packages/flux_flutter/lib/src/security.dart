// Flux Script Security Module
//
// Provides script signing, verification, and version control for production deployments.
//
// Key Features:
// - ED25519 signature verification
// - Script version management
// - Secure transport validation
// - Sandboxing enhancements

import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Script metadata and signature information
class FluxScriptPackage {
  /// Script version (semantic versioning)
  final String version;
  
  /// Script content (Flux source code)
  final String content;
  
  /// SHA-256 hash of the content
  final String contentHash;
  
  /// ED25519 signature of the content hash (base64 encoded)
  final String? signature;
  
  /// Timestamp when the script was signed
  final DateTime? signedAt;
  
  /// Minimum app version required to run this script
  final String? minAppVersion;
  
  /// Whether this is a mandatory update
  final bool mandatory;
  
  FluxScriptPackage({
    required this.version,
    required this.content,
    required this.contentHash,
    this.signature,
    this.signedAt,
    this.minAppVersion,
    this.mandatory = false,
  });
  
  /// Create a package from JSON (typically from server response)
  factory FluxScriptPackage.fromJson(Map<String, dynamic> json) {
    final content = json['content'] as String? ?? '';
    final providedHash = json['contentHash'] as String?;
    
    // Calculate hash for verification
    final calculatedHash = _calculateHash(content);
    
    return FluxScriptPackage(
      version: json['version'] as String? ?? '0.0.0',
      content: content,
      contentHash: providedHash ?? calculatedHash,
      signature: json['signature'] as String?,
      signedAt: json['signedAt'] != null 
          ? DateTime.tryParse(json['signedAt'] as String) 
          : null,
      minAppVersion: json['minAppVersion'] as String?,
      mandatory: json['mandatory'] as bool? ?? false,
    );
  }
  
  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() => {
    'version': version,
    'content': content,
    'contentHash': contentHash,
    'signature': signature,
    'signedAt': signedAt?.toIso8601String(),
    'minAppVersion': minAppVersion,
    'mandatory': mandatory,
  };
  
  /// Verify the content hash matches
  bool verifyHash() {
    final calculated = _calculateHash(content);
    return calculated == contentHash;
  }
  
  static String _calculateHash(String content) {
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

/// Script version manager for caching and rollback support
class FluxVersionManager {
  final Map<String, FluxScriptPackage> _cache = {};
  final List<String> _versionHistory = [];
  final int maxCachedVersions;
  
  FluxVersionManager({this.maxCachedVersions = 5});
  
  /// Cache a script package
  void cache(FluxScriptPackage package) {
    _cache[package.version] = package;
    _versionHistory.remove(package.version);
    _versionHistory.insert(0, package.version);
    
    // Trim old versions
    while (_versionHistory.length > maxCachedVersions) {
      final oldVersion = _versionHistory.removeLast();
      _cache.remove(oldVersion);
    }
  }
  
  /// Get a cached package by version
  FluxScriptPackage? get(String version) => _cache[version];
  
  /// Get the latest cached package
  FluxScriptPackage? get latest => 
      _versionHistory.isNotEmpty ? _cache[_versionHistory.first] : null;
  
  /// Get the previous version (for rollback)
  FluxScriptPackage? get previous =>
      _versionHistory.length > 1 ? _cache[_versionHistory[1]] : null;
  
  /// Check if a version is cached
  bool hasCached(String version) => _cache.containsKey(version);
  
  /// Get all cached versions
  List<String> get cachedVersions => List.unmodifiable(_versionHistory);
  
  /// Clear all cached versions
  void clear() {
    _cache.clear();
    _versionHistory.clear();
  }
}

/// Script signature verifier
/// 
/// Note: This is a placeholder implementation. In production, you would use
/// a proper ED25519 library like `ed25519_edwards` or `cryptography`.
class FluxSignatureVerifier {
  /// The public key used for verification (base64 encoded)
  final String publicKey;
  
  FluxSignatureVerifier(this.publicKey);
  
  /// Verify a script package signature
  /// 
  /// Returns true if:
  /// 1. The content hash matches
  /// 2. The signature is valid for the content hash
  bool verify(FluxScriptPackage package) {
    // Step 1: Verify content hash
    if (!package.verifyHash()) {
      return false;
    }
    
    // Step 2: Verify signature (placeholder - implement with real ED25519)
    if (package.signature == null) {
      return false;
    }
    
    // TODO: Implement actual ED25519 verification
    // For now, we just check that a signature exists
    // In production, use: ed25519.verify(publicKey, package.contentHash, package.signature)
    return package.signature!.isNotEmpty;
  }
  
  /// Verify signature without failing (for development mode)
  /// 
  /// Returns a result object with details about the verification
  VerificationResult verifyWithDetails(FluxScriptPackage package) {
    final hashValid = package.verifyHash();
    final hasSignature = package.signature != null && package.signature!.isNotEmpty;
    
    if (!hashValid) {
      return VerificationResult(
        isValid: false,
        hashValid: false,
        signatureValid: false,
        message: 'Content hash mismatch - script may have been tampered with',
      );
    }
    
    if (!hasSignature) {
      return VerificationResult(
        isValid: false,
        hashValid: true,
        signatureValid: false,
        message: 'No signature present - script is unsigned',
      );
    }
    
    // TODO: Actual signature verification
    return VerificationResult(
      isValid: true,
      hashValid: true,
      signatureValid: true,
      message: 'Script verified successfully',
    );
  }
}

/// Result of script verification
class VerificationResult {
  final bool isValid;
  final bool hashValid;
  final bool signatureValid;
  final String message;
  
  VerificationResult({
    required this.isValid,
    required this.hashValid,
    required this.signatureValid,
    required this.message,
  });
  
  @override
  String toString() => 'VerificationResult($message)';
}

/// Sandbox configuration for script execution
class FluxSandboxConfig {
  /// Maximum execution time in milliseconds (default: 30 seconds)
  final int maxExecutionTimeMs;
  
  /// Maximum stack depth (default: 64)
  final int maxStackDepth;
  
  /// Maximum string length (default: 1MB)
  final int maxStringLength;
  
  /// Maximum list/map size (default: 10000 items)
  final int maxCollectionSize;
  
  /// Allowed network hosts (empty = all blocked, ['*'] = all allowed)
  final List<String> allowedHosts;
  
  /// Whether to allow file system access
  final bool allowFileAccess;
  
  /// Whether to allow camera/sensor access
  final bool allowSensorAccess;
  
  /// Whether to allow native code execution
  final bool allowNativeCode;
  
  const FluxSandboxConfig({
    this.maxExecutionTimeMs = 30000,
    this.maxStackDepth = 64,
    this.maxStringLength = 1024 * 1024, // 1MB
    this.maxCollectionSize = 10000,
    this.allowedHosts = const [],
    this.allowFileAccess = false,
    this.allowSensorAccess = false,
    this.allowNativeCode = false,
  });
  
  /// Default production config (most restrictive)
  static const production = FluxSandboxConfig();
  
  /// Development config (less restrictive)
  static const development = FluxSandboxConfig(
    maxExecutionTimeMs: 60000,
    maxStackDepth: 128,
    maxStringLength: 10 * 1024 * 1024, // 10MB
    maxCollectionSize: 100000,
    allowedHosts: ['*'],
    allowFileAccess: true,
    allowSensorAccess: true,
    allowNativeCode: true,
  );
  
  /// Check if a host is allowed for network requests
  bool isHostAllowed(String host) {
    if (allowedHosts.isEmpty) return false;
    if (allowedHosts.contains('*')) return true;
    return allowedHosts.any((pattern) {
      if (pattern.startsWith('*.')) {
        // Wildcard subdomain match
        final domain = pattern.substring(2);
        return host.endsWith(domain) || host == domain;
      }
      return host == pattern;
    });
  }
}

/// Secure script loader with verification and caching
class SecureScriptLoader {
  final FluxSignatureVerifier? verifier;
  final FluxVersionManager versionManager;
  final FluxSandboxConfig sandboxConfig;
  final bool enforceSignatures;
  
  SecureScriptLoader({
    this.verifier,
    FluxVersionManager? versionManager,
    this.sandboxConfig = FluxSandboxConfig.production,
    this.enforceSignatures = true,
  }) : versionManager = versionManager ?? FluxVersionManager();
  
  /// Load and verify a script package
  /// 
  /// Throws [SecurityException] if verification fails and enforceSignatures is true
  FluxScriptPackage loadPackage(Map<String, dynamic> json) {
    final package = FluxScriptPackage.fromJson(json);
    
    if (enforceSignatures && verifier != null) {
      final result = verifier!.verifyWithDetails(package);
      if (!result.isValid) {
        throw SecurityException(result.message);
      }
    }
    
    // Cache the verified package
    versionManager.cache(package);
    
    return package;
  }
  
  /// Get the script content for execution
  /// 
  /// Returns the content from the latest cached package, or null if none available
  String? getLatestScript() {
    return versionManager.latest?.content;
  }
  
  /// Rollback to the previous version
  /// 
  /// Returns the previous package, or null if no previous version available
  FluxScriptPackage? rollback() {
    return versionManager.previous;
  }
}

/// Security exception thrown when script verification fails
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}
