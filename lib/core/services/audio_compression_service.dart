import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import '../../version_a/models/file_info.dart';
import '../../version_a/models/compression_options.dart';

/// Compresses audio files using native iOS AVFoundation (AVAssetExportSession).
/// Converts WAV, AIFF, FLAC, MP3 → M4A (AAC).
/// WAV is uncompressed PCM — conversion gives 85-95% file size reduction.
/// MP3/M4A re-encoding gives moderate reduction depending on source bitrate.
class AudioCompressionService {
  static const MethodChannel _channel = MethodChannel('audio_compressor');

  static const List<String> _audioExtensions = [
    '.wav', '.wave', '.aiff', '.aif', '.mp3', '.flac', '.ogg', '.wma'
  ];

  // Already AAC-encoded — re-encoding wastes time for little gain
  static const List<String> _alreadyCompressedExtensions = ['.m4a', '.aac'];

  bool isAudio(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return _audioExtensions.contains(ext) || _alreadyCompressedExtensions.contains(ext);
  }

  bool isAlreadyCompressedAudio(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return _alreadyCompressedExtensions.contains(ext);
  }

  Future<FileInfo> compressAudio({
    required FileInfo fileInfo,
    required String outputDirectory,
    required CompressionPreset preset,
  }) async {
    final File file = File(fileInfo.path);
    if (!await file.exists()) {
      throw Exception('File not found: ${fileInfo.path}');
    }

    // Already compressed formats won't benefit much — return original
    if (isAlreadyCompressedAudio(fileInfo.path)) {
      return fileInfo.copyWith(
        compressedPath: fileInfo.path,
        compressedSizeInBytes: fileInfo.sizeInBytes,
        formatNote: 'Already in AAC format',
      );
    }

    final String baseName = path.basenameWithoutExtension(fileInfo.name);
    final String inputExt = path.extension(fileInfo.path).toUpperCase().replaceAll('.', '');
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String outputPath = '$outputDirectory/${baseName}_compressed_$timestamp.m4a';

    // Bitrate selection — AVAssetExportPresetAppleM4A internally targets ~256kbps AAC.
    // We pass the desired bitrate to the native layer for future AVAssetWriter expansion.
    int bitrate;
    switch (preset) {
      case CompressionPreset.smart:
        bitrate = 128000; // 128 kbps — transparent for most content
        break;
      case CompressionPreset.highQuality:
        bitrate = 256000; // 256 kbps — audiophile quality
        break;
      case CompressionPreset.maxCompression:
        bitrate = 64000; // 64 kbps — good for voice, acceptable for music
        break;
    }

    try {
      final String? compressedPath = await _channel.invokeMethod<String>(
        'compressAudio',
        {
          'inputPath': fileInfo.path,
          'outputPath': outputPath,
          'bitrate': bitrate,
        },
      );

      if (compressedPath == null) {
        return fileInfo.copyWith(
          compressedPath: fileInfo.path,
          compressedSizeInBytes: fileInfo.sizeInBytes,
        );
      }

      final File compressedFile = File(compressedPath);
      if (!await compressedFile.exists()) {
        return fileInfo.copyWith(
          compressedPath: fileInfo.path,
          compressedSizeInBytes: fileInfo.sizeInBytes,
        );
      }

      final int compressedSize = await compressedFile.length();

      return FileInfo(
        name: path.basename(compressedPath),
        path: compressedPath,
        sizeInBytes: fileInfo.sizeInBytes,
        compressedPath: compressedPath,
        compressedSizeInBytes: compressedSize,
        dateAdded: DateTime.now(),
        formatNote: '$inputExt → M4A (AAC)',
      );
    } catch (e) {
      // Gracefully fall back to original on any native error
      return fileInfo.copyWith(
        compressedPath: fileInfo.path,
        compressedSizeInBytes: fileInfo.sizeInBytes,
      );
    }
  }
}
