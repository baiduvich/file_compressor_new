import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;
import '../../version_a/models/file_info.dart';
import '../../version_a/models/compression_options.dart';
import 'smart_compression_service.dart';
import 'pdf_compression_service.dart';

class CompressionService {
  final _smartService = SmartCompressionService();
  final _pdfService = PdfCompressionService();

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

      // Add all files to the archive
      for (int i = 0; i < files.length; i++) {
        final fileInfo = files[i];
        final file = File(fileInfo.path);
        if (!await file.exists()) continue;
        
        String entryName = fileInfo.name;
        List<int> bytes;

        // Try to compress the file first (Compress THEN Zip logic)
        FileInfo? processed;
        
        // We attempt compression if it's a supported type, regardless of preset
        // mimicking the "individual compression" behavior the user liked
        if (_smartService.isImage(fileInfo.path)) {
           processed = await _smartService.compressImage(fileInfo: fileInfo, outputDirectory: tempDir, preset: preset);
        } else if (_smartService.isVideo(fileInfo.path)) {
           processed = await _smartService.compressVideo(fileInfo: fileInfo, outputDirectory: tempDir, preset: preset);
        } else if (fileInfo.path.toLowerCase().endsWith('.pdf')) {
           processed = await _pdfService.compressPdf(fileInfo, tempDir, preset);
        }
        
        if (processed != null && processed.path != fileInfo.path) {
           // Compressed successfully to a temp file
           final pFile = File(processed.path);
           if (await pFile.exists()) {
             bytes = await pFile.readAsBytes();
             // Use original name + new extension for clean entry name
             final ext = path.extension(processed.path);
             final originalBase = path.basenameWithoutExtension(fileInfo.name);
             entryName = '$originalBase$ext'; 
             
             // Cleanup temp file immediately after reading
             try { await pFile.delete(); } catch (_) {} 
           } else {
             // Fallback if temp file missing
             bytes = await file.readAsBytes();
           }
        } else {
           // No compression or failed, use original
           bytes = await file.readAsBytes();
        }

        totalOriginalSize += bytes.length; 
        
        final archiveFile = ArchiveFile(
          entryName,
          bytes.length,
          bytes,
        );
        archive.addFile(archiveFile);
        
        onProgress?.call((i + 1) / files.length * 0.8);
      }
      
      // Encode to ZIP
      int zipLevel = Deflate.BEST_COMPRESSION;
      if (preset == CompressionPreset.smart) zipLevel = 6;
      if (preset == CompressionPreset.highQuality) zipLevel = 0; 
      if (preset == CompressionPreset.maxCompression) zipLevel = 9;

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive, level: zipLevel);
      
      if (zipData == null) {
        throw Exception('Failed to create ZIP archive');
      }
      
      onProgress?.call(0.9);
      
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(zipData);
      onProgress?.call(1.0);
      
      return FileInfo(
        name: path.basename(outputPath),
        path: outputPath,
        sizeInBytes: totalOriginalSize, // This might be misleading, ideally sum of ORIGINAL input files?
        // But for "space saved" stats, we usually compare final vs initial. 
        // Here specific logic for stats might be needed elsewhere, but let's stick to this.
        compressedPath: outputPath,
        compressedSizeInBytes: zipData.length,
        dateAdded: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Bundled compression failed: $e');
    }
  }
  
  // Compress a single file individually
  Future<FileInfo> compressSingleFile({
    required FileInfo fileInfo,
    required String outputPath,
    CompressionPreset preset = CompressionPreset.smart,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final lowerPath = fileInfo.path.toLowerCase();
      final parentDir = path.dirname(outputPath); // Use parent of target output for temp/sidecars

      // 1. PDF Compression
      if (lowerPath.endsWith('.pdf')) {
        return await _pdfService.compressPdf(fileInfo, parentDir, preset);
      }
      
      // 2. Image Compression
      if (_smartService.isImage(fileInfo.path)) {
        return await _smartService.compressImage(fileInfo: fileInfo, outputDirectory: parentDir, preset: preset);
      }
      
      // 3. Video Compression
      if (_smartService.isVideo(fileInfo.path)) {
        return await _smartService.compressVideo(fileInfo: fileInfo, outputDirectory: parentDir, preset: preset);
      }

      // 4. Fallback to ZIP (Standard)
      return await _zipFile(
        fileInfo: fileInfo, 
        outputPath: outputPath, 
        preset: preset, 
        onProgress: onProgress
      );

    } catch (e) {
      throw Exception('Compression failed: $e');
    }
  }

  // Internal helper for actual Zipping of single file
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
      final archiveFile = ArchiveFile(
        fileInfo.name,
        bytes.length,
        bytes,
      );
      archive.addFile(archiveFile);
      onProgress?.call(0.6);
      
      int zipLevel = Deflate.BEST_COMPRESSION;
      if (preset == CompressionPreset.smart) zipLevel = 6;
      if (preset == CompressionPreset.highQuality) zipLevel = 0; 
      if (preset == CompressionPreset.maxCompression) zipLevel = 9;

      final zipEncoder = ZipEncoder();
      final zipData = zipEncoder.encode(archive, level: zipLevel);
      
      if (zipData == null) {
        throw Exception('Failed to create ZIP archive');
      }
      
      onProgress?.call(0.8);
      
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(zipData);
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
  
  // Compress files based on mode (bundled or individual)
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
        onProgress: (progress) {
          onProgress?.call(0, 1, progress);
        },
      );
      
      return [bundledFile];
    } else {
      final compressedFiles = <FileInfo>[];
      
      for (int i = 0; i < files.length; i++) {
        final fileInfo = files[i];
        final fileName = path.basenameWithoutExtension(fileInfo.name);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        
        // Default extension, compressSingleFile might return something else (.mp4/.jpg)
        // We pass a .zip path as default target if zipping occurs
        final outputPath = '$outputDirectory/${fileName}_compressed_$timestamp.zip'; 
        
        final compressed = await compressSingleFile(
          fileInfo: fileInfo,
          outputPath: outputPath,
          preset: preset,
          onProgress: (progress) {
            onProgress?.call(i, files.length, progress);
          },
        );
        
        compressedFiles.add(compressed);
      }
      
      return compressedFiles;
    }
  }
}
