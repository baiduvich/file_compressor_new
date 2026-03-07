import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path/path.dart' as path;
import '../../version_a/models/file_info.dart';
import '../../version_a/models/compression_options.dart';

class SmartCompressionService {
  // Compress image — uses WebP for Smart/MaxCompression (50–90% smaller than PNG/JPEG),
  // JPEG for NearOriginal (maintains compatibility).
  Future<FileInfo> compressImage({
    required FileInfo fileInfo,
    required String outputDirectory,
    required CompressionPreset preset,
  }) async {
    final File file = File(fileInfo.path);
    if (!await file.exists()) {
      throw Exception('File not found: ${fileInfo.path}');
    }

    final String fileName = path.basenameWithoutExtension(fileInfo.name);
    final String inputExt = path.extension(fileInfo.path).toLowerCase();
    final bool isPng = inputExt == '.png';
    final bool isWebP = inputExt == '.webp';

    // Format selection:
    // - Near Original → keep original format (JPEG/PNG)
    // - Balanced & Smallest File → WebP (dramatically smaller with same perceived quality)
    final bool convertToWebP = !isWebP &&
        (preset == CompressionPreset.smart || preset == CompressionPreset.maxCompression);

    String targetExtension;
    CompressFormat compressFormat;

    if (convertToWebP) {
      targetExtension = '.webp';
      compressFormat = CompressFormat.webp;
    } else if (isPng) {
      targetExtension = '.png';
      compressFormat = CompressFormat.png;
    } else {
      targetExtension = '.jpg';
      compressFormat = CompressFormat.jpeg;
    }

    final targetPath =
        '$outputDirectory/${fileName}_compressed_${DateTime.now().millisecondsSinceEpoch}$targetExtension';

    int qualityValue;
    switch (preset) {
      case CompressionPreset.smart:
        qualityValue = convertToWebP ? 82 : 80;
        break;
      case CompressionPreset.highQuality:
        qualityValue = 90;
        break;
      case CompressionPreset.maxCompression:
        qualityValue = convertToWebP ? 60 : 50;
        break;
    }

    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: qualityValue,
      format: compressFormat,
    );

    if (result == null) {
      return fileInfo.copyWith(
        compressedPath: fileInfo.path,
        compressedSizeInBytes: fileInfo.sizeInBytes,
      );
    }

    final int compressedSize = await result.length();

    // If compressed is larger than original (already well-compressed), keep original
    if (compressedSize >= fileInfo.sizeInBytes && preset != CompressionPreset.highQuality) {
      try {
        await File(targetPath).delete();
      } catch (_) {}
      return fileInfo.copyWith(
        compressedPath: fileInfo.path,
        compressedSizeInBytes: fileInfo.sizeInBytes,
      );
    }

    // Build a human-readable format note when conversion happens
    String? formatNote;
    if (convertToWebP) {
      final originalLabel = isPng ? 'PNG' : inputExt.toUpperCase().replaceAll('.', '');
      formatNote = '$originalLabel → WebP';
    }

    return FileInfo(
      name: path.basename(targetPath),
      path: targetPath,
      sizeInBytes: fileInfo.sizeInBytes,
      compressedPath: targetPath,
      compressedSizeInBytes: compressedSize,
      dateAdded: DateTime.now(),
      formatNote: formatNote,
    );
  }

  // Compress video by re-encoding
  Future<FileInfo> compressVideo({
    required FileInfo fileInfo,
    required String outputDirectory,
    required CompressionPreset preset,
  }) async {
    final File file = File(fileInfo.path);
    if (!await file.exists()) {
      throw Exception('File not found: ${fileInfo.path}');
    }

    VideoQuality videoQuality;
    switch (preset) {
      case CompressionPreset.smart:
        videoQuality = VideoQuality.MediumQuality; // 720p
        break;
      case CompressionPreset.highQuality:
        videoQuality = VideoQuality.HighestQuality;
        break;
      case CompressionPreset.maxCompression:
        videoQuality = VideoQuality.LowQuality; // 360p
        break;
    }

    try {
      await VideoCompress.deleteAllCache();

      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: videoQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (mediaInfo == null || mediaInfo.file == null) {
        throw Exception('Video compression returned null');
      }

      final compressedFile = mediaInfo.file!;
      final compressedSize = await compressedFile.length();

      if (compressedSize >= fileInfo.sizeInBytes && preset != CompressionPreset.highQuality) {
        return fileInfo.copyWith(
          compressedPath: fileInfo.path,
          compressedSizeInBytes: fileInfo.sizeInBytes,
        );
      }

      final fileName = path.basenameWithoutExtension(fileInfo.name);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalPath = '$outputDirectory/${fileName}_compressed_$timestamp.mp4';

      await compressedFile.copy(finalPath);
      try {
        await compressedFile.delete();
      } catch (_) {}

      final savedSize = await File(finalPath).length();

      return FileInfo(
        name: path.basename(finalPath),
        path: finalPath,
        sizeInBytes: fileInfo.sizeInBytes,
        compressedPath: finalPath,
        compressedSizeInBytes: savedSize,
        dateAdded: DateTime.now(),
      );
    } catch (e) {
      return fileInfo.copyWith(
        compressedPath: fileInfo.path,
        compressedSizeInBytes: fileInfo.sizeInBytes,
      );
    }
  }

  bool isImage(String filePath) {
    final ext = filePath.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.heic') ||
        ext.endsWith('.webp');
  }

  bool isVideo(String filePath) {
    final ext = filePath.toLowerCase();
    return ext.endsWith('.mp4') ||
        ext.endsWith('.mov') ||
        ext.endsWith('.avi') ||
        ext.endsWith('.m4v') ||
        ext.endsWith('.mkv');
  }
}
