import 'dart:async';
import 'dart:typed_data';

import 'package:flux_compiler/flux_compiler.dart';

import 'chunk_serializer.dart';
import 'diff_manager.dart';
import 'flux_release.dart';
import 'signature_utils.dart';
import 'version_manager.dart';

/// Status of an update check or download.
enum UpdateStatus {
  /// No update available.
  upToDate,

  /// Update available for download.
  updateAvailable,

  /// Update is being downloaded.
  downloading,

  /// Update downloaded and ready to apply.
  readyToApply,

  /// Update applied successfully.
  applied,

  /// Error occurred during update.
  error,
}

/// Progress information for update operations.
class UpdateProgress {
  final UpdateStatus status;
  final double progress; // 0.0 to 1.0
  final String? message;
  final Object? error;

  UpdateProgress({
    required this.status,
    this.progress = 0.0,
    this.message,
    this.error,
  });
}

/// Callback type for when a new chunk is ready to apply.
typedef OnChunkReady = void Function(Chunk newChunk);

/// Manages OTA updates for Flux applications.
///
/// Example usage:
/// ```dart
/// final manager = FluxUpdateManager(
///   appId: 'com.example.myapp',
///   serverUrl: 'https://ota.example.com',
///   signingKey: 'your-secret-key',
///   onChunkReady: (chunk) {
///     // Apply chunk via FluxRuntime.hotReload
///     runtime.hotReload(chunk);
///   },
/// );
///
/// // Check for updates
/// final status = await manager.checkForUpdates();
/// if (status == UpdateStatus.updateAvailable) {
///   await manager.downloadAndApply();
/// }
/// ```
class FluxUpdateManager {
  /// Unique app identifier.
  final String appId;

  /// Base URL of the OTA server.
  final String serverUrl;

  /// Secret key for signature verification.
  final String signingKey;

  /// Callback when new chunk is ready.
  final OnChunkReady? onChunkReady;

  /// Version manager for tracking releases.
  final VersionManager versionManager;

  /// Current build number.
  int _currentBuildNumber;

  /// Current chunk (for diff patching).
  Chunk? _currentChunk;

  /// Progress stream controller.
  final _progressController = StreamController<UpdateProgress>.broadcast();

  /// Pending update waiting to be applied.
  PendingUpdate? _pendingUpdate;

  FluxUpdateManager({
    required this.appId,
    required this.serverUrl,
    required this.signingKey,
    required int currentBuildNumber,
    this.onChunkReady,
    Chunk? currentChunk,
    VersionManager? versionManager,
  })  : _currentBuildNumber = currentBuildNumber,
        _currentChunk = currentChunk,
        versionManager = versionManager ?? VersionManager();

  /// Stream of update progress.
  Stream<UpdateProgress> get progressStream => _progressController.stream;

  /// Current build number.
  int get currentBuildNumber => _currentBuildNumber;

  /// Whether an update is pending.
  bool get hasPendingUpdate => _pendingUpdate != null;

  /// Check for available updates.
  Future<UpdateStatus> checkForUpdates() async {
    _emitProgress(UpdateStatus.upToDate, message: 'Checking for updates...');

    try {
      // In a real implementation, this would make an HTTP request
      // For now, check local version manager
      if (versionManager.hasUpdate(appId, _currentBuildNumber)) {
        _emitProgress(UpdateStatus.updateAvailable,
            message: 'Update available');
        return UpdateStatus.updateAvailable;
      }

      _emitProgress(UpdateStatus.upToDate, message: 'Up to date');
      return UpdateStatus.upToDate;
    } catch (e) {
      _emitProgress(UpdateStatus.error, error: e, message: 'Check failed: $e');
      return UpdateStatus.error;
    }
  }

  /// Download and apply the latest update.
  Future<UpdateStatus> downloadAndApply() async {
    try {
      final latest = versionManager.getLatestRelease(appId);
      if (latest == null) {
        _emitProgress(UpdateStatus.upToDate, message: 'No update available');
        return UpdateStatus.upToDate;
      }

      if (latest.buildNumber <= _currentBuildNumber) {
        _emitProgress(UpdateStatus.upToDate, message: 'Already up to date');
        return UpdateStatus.upToDate;
      }

      _emitProgress(UpdateStatus.downloading,
          progress: 0.1, message: 'Downloading update...');

      // Verify signature
      if (!SignatureUtils.verify(latest.chunk, latest.signature, signingKey)) {
        throw Exception('Invalid signature - update rejected');
      }

      _emitProgress(UpdateStatus.downloading,
          progress: 0.5, message: 'Verifying...');

      // Determine if we should use patch or full chunk
      Chunk newChunk;
      if (latest.hasPatch && _currentChunk != null) {
        // Try to apply patch
        try {
          _emitProgress(UpdateStatus.downloading,
              progress: 0.7, message: 'Applying patch...');
          newChunk = await FluxDiffManager.applyPatch(
            _currentChunk!,
            latest.patch!,
          );
        } catch (e) {
          // Fallback to full chunk
          newChunk = ChunkSerializer.deserialize(latest.chunk);
        }
      } else {
        // Use full chunk
        newChunk = ChunkSerializer.deserialize(latest.chunk);
      }

      _emitProgress(UpdateStatus.readyToApply,
          progress: 0.9, message: 'Ready to apply');

      // Apply the update
      if (onChunkReady != null) {
        onChunkReady!(newChunk);
      }

      // Update state
      _currentChunk = newChunk;
      _currentBuildNumber = latest.buildNumber;
      versionManager.setCurrentVersion(appId, latest.version);

      _emitProgress(UpdateStatus.applied,
          progress: 1.0, message: 'Update applied successfully');

      return UpdateStatus.applied;
    } catch (e) {
      _emitProgress(UpdateStatus.error, error: e, message: 'Update failed: $e');
      return UpdateStatus.error;
    }
  }

  /// Stage an update for later application.
  Future<void> stageUpdate(FluxRelease release) async {
    final usePatch = release.hasPatch && _currentChunk != null;
    _pendingUpdate = PendingUpdate(
      release: release,
      patchData: release.patch,
      usePatch: usePatch,
      downloadSize: usePatch ? release.patch!.length : release.chunk.length,
    );
  }

  /// Apply a staged update.
  Future<UpdateStatus> applyPendingUpdate() async {
    if (_pendingUpdate == null) {
      return UpdateStatus.upToDate;
    }

    versionManager.registerRelease(_pendingUpdate!.release);
    final status = await downloadAndApply();
    _pendingUpdate = null;
    return status;
  }

  /// Rollback to a previous version.
  Future<bool> rollback(String targetVersion) async {
    final release = versionManager.getRelease(appId, targetVersion);
    if (release == null) {
      return false;
    }

    try {
      final chunk = ChunkSerializer.deserialize(release.chunk);
      if (onChunkReady != null) {
        onChunkReady!(chunk);
      }
      _currentChunk = chunk;
      _currentBuildNumber = release.buildNumber;
      versionManager.setCurrentVersion(appId, release.version);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _emitProgress(
    UpdateStatus status, {
    double progress = 0.0,
    String? message,
    Object? error,
  }) {
    _progressController.add(UpdateProgress(
      status: status,
      progress: progress,
      message: message,
      error: error,
    ));
  }

  /// Clean up resources.
  void dispose() {
    _progressController.close();
  }
}
