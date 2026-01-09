import 'dart:convert';
import 'dart:typed_data';

import 'flux_release.dart';

/// Manages version history and local storage of Flux releases.
class VersionManager {
  final Map<String, FluxRelease> _releases = {};
  final Map<String, String> _currentVersions = {}; // appId -> version

  /// Register a release in the version manager.
  void registerRelease(FluxRelease release) {
    final key = '${release.appId}:${release.version}';
    _releases[key] = release;
  }

  /// Get a specific release.
  FluxRelease? getRelease(String appId, String version) {
    return _releases['$appId:$version'];
  }

  /// Get the current version for an app.
  String? getCurrentVersion(String appId) {
    return _currentVersions[appId];
  }

  /// Set the current version for an app.
  void setCurrentVersion(String appId, String version) {
    _currentVersions[appId] = version;
  }

  /// Get all releases for an app.
  List<FluxRelease> getReleasesForApp(String appId) {
    return _releases.entries
        .where((e) => e.key.startsWith('$appId:'))
        .map((e) => e.value)
        .toList()
      ..sort((a, b) => b.buildNumber.compareTo(a.buildNumber));
  }

  /// Check if an update is available.
  bool hasUpdate(String appId, int currentBuildNumber) {
    final releases = getReleasesForApp(appId);
    if (releases.isEmpty) return false;
    return releases.first.buildNumber > currentBuildNumber;
  }

  /// Get the latest release for an app.
  FluxRelease? getLatestRelease(String appId) {
    final releases = getReleasesForApp(appId);
    return releases.isNotEmpty ? releases.first : null;
  }

  /// Compare two semantic versions.
  ///
  /// Returns:
  /// - negative if v1 < v2
  /// - zero if v1 == v2
  /// - positive if v1 > v2
  static int compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.tryParse).toList();
    final parts2 = v2.split('.').map(int.tryParse).toList();

    final maxLength =
        parts1.length > parts2.length ? parts1.length : parts2.length;

    for (int i = 0; i < maxLength; i++) {
      final p1 = i < parts1.length ? (parts1[i] ?? 0) : 0;
      final p2 = i < parts2.length ? (parts2[i] ?? 0) : 0;

      if (p1 != p2) {
        return p1 - p2;
      }
    }

    return 0;
  }

  /// Check if version is newer.
  static bool isNewer(String newVersion, String oldVersion) {
    return compareVersions(newVersion, oldVersion) > 0;
  }

  /// Export version state to JSON for persistence.
  String exportToJson() {
    return jsonEncode({
      'currentVersions': _currentVersions,
      'releases': _releases.map((k, v) => MapEntry(k, v.toVersionInfo())),
    });
  }

  /// Import version state from JSON.
  void importFromJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    _currentVersions.clear();
    _currentVersions.addAll(Map<String, String>.from(data['currentVersions']));

    if (data.containsKey('releases')) {
      final releases = data['releases'] as Map<String, dynamic>;
      releases.forEach((key, value) {
        // Reconstruct FluxRelease from metadata
        // Note: Chunk is not stored in metadata, so we use empty bytes.
        // The actual chunk is stored/loaded via CacheManager.
        _releases[key] = FluxRelease(
          appId: value['appId'],
          version: value['version'],
          buildNumber: value['buildNumber'],
          chunk: Uint8List(0), // Placeholder
          signature: value['signature'] ?? '',
          createdAt: DateTime.parse(value['createdAt']),
          patchBaseVersion: value['patchBaseVersion'],
          rollbackTo: value['rollbackTo'],
          minVmVersion: value['minVmVersion'],
        );
      });
    }
  }
}

/// Represents an update that can be applied.
class PendingUpdate {
  final FluxRelease release;
  final Uint8List? patchData;
  final bool usePatch;
  final int downloadSize;

  PendingUpdate({
    required this.release,
    this.patchData,
    required this.usePatch,
    required this.downloadSize,
  });
}
