import 'dart:typed_data';

/// Represents a versioned release of Flux bytecode.
class FluxRelease {
  /// Unique identifier for the app.
  final String appId;

  /// Semantic version string (e.g., "1.2.3").
  final String version;

  /// Incrementing build number for comparison.
  final int buildNumber;

  /// Full serialized bytecode chunk.
  final Uint8List chunk;

  /// Optional diff patch from previous version.
  /// If null, the full [chunk] should be used.
  final Uint8List? patch;

  /// Previous version this patch is based on.
  /// Required when [patch] is not null.
  final String? patchBaseVersion;

  /// Cryptographic signature for verification.
  final String signature;

  /// When this release was created.
  final DateTime createdAt;

  /// Version to rollback to if this release fails.
  final String? rollbackTo;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  /// Minimum VM version required to run this release.
  final String? minVmVersion;

  FluxRelease({
    required this.appId,
    required this.version,
    required this.buildNumber,
    required this.chunk,
    this.patch,
    this.patchBaseVersion,
    required this.signature,
    required this.createdAt,
    this.rollbackTo,
    this.metadata = const {},
    this.minVmVersion,
  });

  /// Whether this release has a diff patch available.
  bool get hasPatch => patch != null && patchBaseVersion != null;

  /// Size of the full chunk in bytes.
  int get chunkSize => chunk.length;

  /// Size of the patch in bytes, or null if no patch.
  int? get patchSize => patch?.length;

  /// Compression ratio if patch is available.
  double? get compressionRatio {
    if (patch == null || chunk.isEmpty) return null;
    return patch!.length / chunk.length;
  }

  /// Create from JSON map (for API responses).
  factory FluxRelease.fromJson(Map<String, dynamic> json) {
    return FluxRelease(
      appId: json['appId'] as String,
      version: json['version'] as String,
      buildNumber: json['buildNumber'] as int,
      chunk: _decodeBytes(json['chunk']),
      patch: json['patch'] != null ? _decodeBytes(json['patch']) : null,
      patchBaseVersion: json['patchBaseVersion'] as String?,
      signature: json['signature'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      rollbackTo: json['rollbackTo'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      minVmVersion: json['minVmVersion'] as String?,
    );
  }

  /// Convert to JSON map (for API requests).
  Map<String, dynamic> toJson() {
    return {
      'appId': appId,
      'version': version,
      'buildNumber': buildNumber,
      'chunk': _encodeBytes(chunk),
      if (patch != null) 'patch': _encodeBytes(patch!),
      if (patchBaseVersion != null) 'patchBaseVersion': patchBaseVersion,
      'signature': signature,
      'createdAt': createdAt.toIso8601String(),
      if (rollbackTo != null) 'rollbackTo': rollbackTo,
      if (metadata.isNotEmpty) 'metadata': metadata,
      if (minVmVersion != null) 'minVmVersion': minVmVersion,
    };
  }

  /// Minimal JSON for version checking (without chunk/patch data).
  Map<String, dynamic> toVersionInfo() {
    return {
      'appId': appId,
      'version': version,
      'buildNumber': buildNumber,
      'chunkSize': chunkSize,
      'patchSize': patchSize,
      'hasPatch': hasPatch,
      'patchBaseVersion': patchBaseVersion,
      'createdAt': createdAt.toIso8601String(),
      'signature': signature,
    };
  }

  static Uint8List _decodeBytes(dynamic value) {
    if (value is List<int>) {
      return Uint8List.fromList(value);
    }
    if (value is String) {
      // Assume base64 encoded
      return Uint8List.fromList(
        value.codeUnits, // Simple encoding for now
      );
    }
    throw ArgumentError('Cannot decode bytes from $value');
  }

  static List<int> _encodeBytes(Uint8List bytes) {
    return bytes.toList();
  }

  @override
  String toString() {
    return 'FluxRelease($appId v$version build$buildNumber)';
  }
}

/// Version info response from server.
class VersionInfo {
  final String appId;
  final String version;
  final int buildNumber;
  final int chunkSize;
  final int? patchSize;
  final bool hasPatch;
  final String? patchBaseVersion;
  final DateTime createdAt;

  VersionInfo({
    required this.appId,
    required this.version,
    required this.buildNumber,
    required this.chunkSize,
    this.patchSize,
    required this.hasPatch,
    this.patchBaseVersion,
    required this.createdAt,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      appId: json['appId'] as String,
      version: json['version'] as String,
      buildNumber: json['buildNumber'] as int,
      chunkSize: json['chunkSize'] as int,
      patchSize: json['patchSize'] as int?,
      hasPatch: json['hasPatch'] as bool,
      patchBaseVersion: json['patchBaseVersion'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
