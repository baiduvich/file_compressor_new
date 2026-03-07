import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import '../../version_a/models/file_info.dart';
import '../../version_a/models/compression_options.dart';
import 'smart_compression_service.dart';
import 'pdf_compression_service.dart';
import 'audio_compression_service.dart';
import 'office_compression_service.dart';

class CompressionService {
  final _smartService = SmartCompressionService();
  final _pdfService = PdfCompressionService();
  final _audioService = AudioCompressionService();
  final _officeService = OfficeCompressionService();

  // Compress multiple files into one bundled ZIP
  Future<FileInfo> compressFilesIntoBundledZip({
    required List<FileInfo> files,
    required String outputPath,
    CompressionPreset preset = CompressionPreset.smart,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final archive = Archive();
      int totalOriginalSize = 0;
      final tempDir = path.dirname(outputPath);

      for (int i = 0; i < files.length; i++) {
        final fileInfo = files[i];
        final file = File(fileInfo.path);
        if (!await file.exists()) continue;

        String entryName = fileInfo.name;
        List<int> bytes;

        FileInfo? processed = await _compressIndividualFile(fileInfo, tempDir, preset);

        if (processed != null &&
            processed.compressedPath != null &&
            processed.compressedPath != fileInfo.path) {
          final pFile = File(processed.compressedPath!);
          if (await pFile.exists()) {
            bytes = await pFile.readAsBytes();
            final ext = path.extension(processed.compressedPath!);
            final originalBase = path.basenameWithoutExtension(fileInfo.name);
            entryName = '$originalBase$ext';
            try {
              await pFile.delete();
            } catch (_) {}
          } else {
            bytes = await file.readAsBytes();
          }
        } else {
          bytes = await file.readAsBytes();
        }

        totalOriginalSize += bytes.length;
        archive.addFile(ArchiveFile(entryName, bytes.length, bytes));
        onProgress?.call((i + 1) / files.length * 0.8);
      }

      int zipLevel = 6;
      if (preset == CompressionPreset.highQuality) zipLevel = 0;
      if (preset == CompressionPreset.maxCompression) zipLevel = 9;

      final zipData = ZipEncoder().encode(archive, level: zipLevel);
      if (zipData == null) throw Exception('Failed to create ZIP archive');

      onProgress?.call(0.9);
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(zipData);
      onProgress?.call(1.0);

      return FileInfo(
        name: path.basename(outputPath),
        path: outputPath,
        sizeInBytes: totalOriginalSize,
        compressedPath: outputPath,
        compressedSizeInBytes: zipData.length,
        dateAdded: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Bundled compression failed: $e');
    }
  }

  // Compress a single file individually — routes to the right engine
  Future<FileInfo> compressSingleFile({
    required FileInfo fileInfo,
    required String outputPath,
    CompressionPreset preset = CompressionPreset.smart,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final parentDir = path.dirname(outputPath);
      final result = await _compressIndividualFile(fileInfo, parentDir, preset);
      if (result != null) return result;

      // Fallback: ZIP for unsupported types
      return await _zipFile(
        fileInfo: fileInfo,
        outputPath: outputPath,
        preset: preset,
        onProgress: onProgress,
      );
    } catch (e) {
      throw Exception('Compression failed: $e');
    }
  }

  // Core routing logic — returns null if file type not recognised
  Future<FileInfo?> _compressIndividualFile(
    FileInfo fileInfo,
    String outputDirectory,
    CompressionPreset preset,
  ) async {
    final lowerPath = fileInfo.path.toLowerCase();

    // PDF
    if (lowerPath.endsWith('.pdf')) {
      print('[PDF] Routing to PDF compression: ${fileInfo.name} (${fileInfo.sizeInBytes} bytes), preset=$preset');
      final result = await _pdfService.compressPdf(fileInfo, outputDirectory, preset);
      print('[PDF] PDF compression result: ${result.name}, compressed=${result.compressedPath != null && result.compressedPath != fileInfo.path}');
      return result;
    }

    // Images (JPEG, PNG, HEIC, WebP)
    if (_smartService.isImage(fileInfo.path)) {
      return await _smartService.compressImage(
        fileInfo: fileInfo,
        outputDirectory: outputDirectory,
        preset: preset,
      );
    }

    // Videos (MP4, MOV, AVI, MKV, M4V)
    if (_smartService.isVideo(fileInfo.path)) {
      return await _smartService.compressVideo(
        fileInfo: fileInfo,
        outputDirectory: outputDirectory,
        preset: preset,
      );
    }

    // Audio (WAV, AIFF, MP3, FLAC, M4A, AAC)
    if (_audioService.isAudio(fileInfo.path)) {
      return await _audioService.compressAudio(
        fileInfo: fileInfo,
        outputDirectory: outputDirectory,
        preset: preset,
      );
    }

    // Office documents (DOCX, PPTX, XLSX)
    if (_officeService.isOfficeFile(fileInfo.path)) {
      return await _officeService.compressOffice(
        fileInfo: fileInfo,
        outputDirectory: outputDirectory,
        preset: preset,
      );
    }

    return null; // Unknown type — caller handles ZIP fallback
  }

  Future<FileInfo> _zipFile({
    required FileInfo fileInfo,
    required String outputPath,
    required CompressionPreset preset,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(fileInfo.path);
    if (!await file.exists()) {
      throw Exception('File not found: ${fileInfo.path}');
    }

    final bytes = await file.readAsBytes();
    onProgress?.call(0.3);

    final archive = Archive();
    archive.addFile(ArchiveFile(fileInfo.name, bytes.length, bytes));
    onProgress?.call(0.6);

    int zipLevel = 6;
    if (preset == CompressionPreset.highQuality) zipLevel = 0;
    if (preset == CompressionPreset.maxCompression) zipLevel = 9;

    final zipData = ZipEncoder().encode(archive, level: zipLevel);
    if (zipData == null) throw Exception('Failed to create ZIP archive');

    onProgress?.call(0.8);
    await File(outputPath).writeAsBytes(zipData);
    onProgress?.call(1.0);

    return FileInfo(
      name: path.basename(outputPath),
      path: outputPath,
      sizeInBytes: bytes.length,
      compressedPath: outputPath,
      compressedSizeInBytes: zipData.length,
      dateAdded: DateTime.now(),
    );
  }

  // Top-level entry point: handles both bundled and individual compression
  Future<List<FileInfo>> compressFiles({
    required List<FileInfo> files,
    required String outputDirectory,
    CompressionPreset preset = CompressionPreset.smart,
    bool bundleFiles = false,
    void Function(int currentIndex, int total, double fileProgress)? onProgress,
  }) async {
    if (bundleFiles) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '$outputDirectory/archive_$timestamp.zip';
      final bundledFile = await compressFilesIntoBundledZip(
        files: files,
        outputPath: outputPath,
        preset: preset,
        onProgress: (progress) => onProgress?.call(0, 1, progress),
      );
      return [bundledFile];
    }

    final compressedFiles = <FileInfo>[];
    for (int i = 0; i < files.length; i++) {
      final fileInfo = files[i];
      final fileName = path.basenameWithoutExtension(fileInfo.name);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '$outputDirectory/${fileName}_compressed_$timestamp.zip';

      final compressed = await compressSingleFile(
        fileInfo: fileInfo,
        outputPath: outputPath,
        preset: preset,
        onProgress: (progress) => onProgress?.call(i, files.length, progress),
      );
      compressedFiles.add(compressed);
    }
    return compressedFiles;
  }
}
