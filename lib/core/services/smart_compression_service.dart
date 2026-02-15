import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path/path.dart' as path;
import '../../version_a/models/file_info.dart';
import '../../version_a/models/compression_options.dart';

class SmartCompressionService {
  // Compress image by re-encoding
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
    final String extension = path.extension(fileInfo.path).toLowerCase();
    
    // Preserve PNG format if input is PNG (to keep transparency)
    final bool isPng = extension == '.png';
    final String targetExtension = isPng ? '.png' : '.jpg';
    
    final targetPath = '$outputDirectory/${fileName}_compressed_${DateTime.now().millisecondsSinceEpoch}$targetExtension';

    int qualityValue = 85;

    switch (preset) {
      case CompressionPreset.smart:
        qualityValue = 80;
        break;
      case CompressionPreset.highQuality:
        qualityValue = 90;
        break;
      case CompressionPreset.maxCompression:
        qualityValue = 50;
        break;
    }

    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: qualityValue,
      format: isPng ? CompressFormat.png : CompressFormat.jpeg,
    );

    if (result == null) {
      return fileInfo;
    }

    final int compressedSize = await result.length();

    // Safety check: if compressed is larger, keep original (unless user desperately wants different format, but usually size matters)
    if (compressedSize >= fileInfo.sizeInBytes && preset != CompressionPreset.highQuality) {
      try {
        await File(targetPath).delete();
      } catch (e) {
        // ignore
      }
      return fileInfo.copyWith(
        compressedPath: fileInfo.path,
        compressedSizeInBytes: fileInfo.sizeInBytes,
      );
    }

    return FileInfo(
      name: path.basename(targetPath),
      path: targetPath,
      sizeInBytes: fileInfo.sizeInBytes,
      compressedPath: targetPath,
      compressedSizeInBytes: compressedSize,
      dateAdded: DateTime.now(),
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

    VideoQuality videoQuality = VideoQuality.MediumQuality;

    switch (preset) {
      case CompressionPreset.smart:
        videoQuality = VideoQuality.MediumQuality; // 720p usually
        break;
      case CompressionPreset.highQuality:
        videoQuality = VideoQuality.HighestQuality; // Original
        break;
      case CompressionPreset.maxCompression:
        videoQuality = VideoQuality.LowQuality; // 360p
        break;
    }

    try {
      // Clear cache before starting to ensure we don't build up junk
      await VideoCompress.deleteAllCache();

      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: videoQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (mediaInfo == null || mediaInfo.file == null) {
        throw Exception('Video compression failed');
      }

      final compressedFile = mediaInfo.file!;
      final compressedSize = await compressedFile.length();
      
      if (compressedSize >= fileInfo.sizeInBytes && preset != CompressionPreset.highQuality) {
         // Cleanup usually handled by deleteAllCache later, but good to be explicit if we aren't using it
         // However, VideoCompress cache logic is sticky. We'll copy if good.
         return fileInfo.copyWith(
          compressedPath: fileInfo.path,
          compressedSizeInBytes: fileInfo.sizeInBytes,
        );
      }

      final fileName = path.basenameWithoutExtension(fileInfo.name);
      final newExtension = '.mp4'; 
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalPath = '$outputDirectory/${fileName}_compressed_$timestamp$newExtension';
      
      await compressedFile.copy(finalPath);
      
      // We don't delete `compressedFile` here manually because VideoCompress manages its referenced file in cache dir
      // and we call deleteAllCache() next time or on app start. 
      // Actually, let's try to delete this specific cached file to be clean.
      try { await compressedFile.delete(); } catch (_) {}

      final savedFile = File(finalPath);
      final savedSize = await savedFile.length();

      return FileInfo(
        name: path.basename(finalPath),
        path: finalPath,
        sizeInBytes: fileInfo.sizeInBytes,
        compressedPath: finalPath,
        compressedSizeInBytes: savedSize,
        dateAdded: DateTime.now(),
      );
    } catch (e) {
      // On failure return original
      return fileInfo.copyWith(
        compressedPath: fileInfo.path,
        compressedSizeInBytes: fileInfo.sizeInBytes,
      );
    }
  }

  bool isImage(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png') || ext.endsWith('.heic') || ext.endsWith('.webp');
  }

  bool isVideo(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.mp4') || ext.endsWith('.mov') || ext.endsWith('.avi') || ext.endsWith('.m4v') || ext.endsWith('.mkv');
  }
}
