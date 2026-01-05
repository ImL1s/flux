import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'chunk_serializer.dart';
import 'package:flux_compiler/flux_compiler.dart';

/// Manages bytecode diffing and patching for efficient updates.
///
/// Uses a simple XOR-based diff with gzip compression as a lightweight
/// alternative to bsdiff.
class FluxDiffManager {
  /// Create a binary diff patch between two chunks.
  ///
  /// Returns a patch that can be applied to [oldChunk] to produce [newChunk].
  ///
  /// Example:
  /// ```dart
  /// final patch = await diffManager.createPatch(oldChunk, newChunk);
  /// final restored = await diffManager.applyPatch(oldChunk, patch);
  /// // restored == newChunk
  /// ```
  static Future<Uint8List> createPatch(Chunk oldChunk, Chunk newChunk) async {
    final oldBytes = ChunkSerializer.serialize(oldChunk);
    final newBytes = ChunkSerializer.serialize(newChunk);
    return createPatchFromBytes(oldBytes, newBytes);
  }

  /// Create a binary diff patch between two byte arrays.
  ///
  /// Format:
  /// [4 bytes: old length]
  /// [4 bytes: new length]
  /// [gzip compressed XOR diff or new bytes]
  static Future<Uint8List> createPatchFromBytes(
    Uint8List oldBytes,
    Uint8List newBytes,
  ) async {
    final buffer = BytesBuilder();

    // Header: old and new lengths
    _writeInt32(buffer, oldBytes.length);
    _writeInt32(buffer, newBytes.length);

    // If sizes are similar, use XOR diff
    if (_shouldUseXorDiff(oldBytes.length, newBytes.length)) {
      buffer.addByte(0); // Marker: XOR diff

      // Create XOR diff
      final maxLen =
          oldBytes.length > newBytes.length ? oldBytes.length : newBytes.length;
      final diff = Uint8List(maxLen);

      for (int i = 0; i < maxLen; i++) {
        final oldByte = i < oldBytes.length ? oldBytes[i] : 0;
        final newByte = i < newBytes.length ? newBytes[i] : 0;
        diff[i] = oldByte ^ newByte;
      }

      // Compress the diff
      final compressed = GZipEncoder().encode(diff);
      buffer.add(compressed!);
    } else {
      buffer.addByte(1); // Marker: full replacement

      // Just compress the new bytes
      final compressed = GZipEncoder().encode(newBytes);
      buffer.add(compressed!);
    }

    return buffer.toBytes();
  }

  /// Apply a patch to a chunk to produce a new chunk.
  static Future<Chunk> applyPatch(Chunk oldChunk, Uint8List patch) async {
    final oldBytes = ChunkSerializer.serialize(oldChunk);
    final newBytes = await applyPatchToBytes(oldBytes, patch);
    return ChunkSerializer.deserialize(newBytes);
  }

  /// Apply a patch to bytes to produce new bytes.
  static Future<Uint8List> applyPatchToBytes(
    Uint8List oldBytes,
    Uint8List patch,
  ) async {
    if (patch.length < 9) {
      throw FormatException('Invalid patch: too short');
    }

    // Read header
    final oldLen = _readInt32(patch, 0);
    final newLen = _readInt32(patch, 4);
    final mode = patch[8];

    // Verify old length matches
    if (oldLen != oldBytes.length) {
      throw FormatException(
          'Patch base mismatch: expected $oldLen bytes, got ${oldBytes.length}');
    }

    final compressedData = patch.sublist(9);
    final decompressed = GZipDecoder().decodeBytes(compressedData);

    if (mode == 0) {
      // XOR diff mode
      final result = Uint8List(newLen);
      for (int i = 0; i < newLen; i++) {
        final oldByte = i < oldBytes.length ? oldBytes[i] : 0;
        final diffByte = i < decompressed.length ? decompressed[i] : 0;
        result[i] = oldByte ^ diffByte;
      }
      return result;
    } else {
      // Full replacement mode
      return Uint8List.fromList(decompressed);
    }
  }

  /// Determine if XOR diff is appropriate.
  static bool _shouldUseXorDiff(int oldLen, int newLen) {
    if (oldLen == 0 || newLen == 0) return false;
    final ratio = oldLen > newLen ? newLen / oldLen : oldLen / newLen;
    return ratio > 0.5; // Use XOR if sizes are within 2x of each other
  }

  /// Calculate the compression ratio of a patch.
  static double calculateCompressionRatio(
    Uint8List fullBytes,
    Uint8List patchBytes,
  ) {
    if (fullBytes.isEmpty) return 1.0;
    return patchBytes.length / fullBytes.length;
  }

  /// Estimate if using diff is beneficial.
  static bool shouldUseDiff(
    Uint8List fullBytes,
    Uint8List patchBytes, {
    double threshold = 0.7,
  }) {
    return calculateCompressionRatio(fullBytes, patchBytes) < threshold;
  }

  static void _writeInt32(BytesBuilder buffer, int value) {
    buffer.addByte((value >> 24) & 0xFF);
    buffer.addByte((value >> 16) & 0xFF);
    buffer.addByte((value >> 8) & 0xFF);
    buffer.addByte(value & 0xFF);
  }

  static int _readInt32(Uint8List bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }
}
