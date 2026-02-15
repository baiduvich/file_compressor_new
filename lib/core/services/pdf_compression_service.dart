import 'dart:io';
import 'package:flutter/services.dart';
import '../../version_a/models/compression_options.dart';
import '../../version_a/models/file_info.dart';
import 'package:path/path.dart' as path;

class PdfCompressionService {
  static const MethodChannel _channel = MethodChannel('pdf_compressor');

  Future<FileInfo> compressPdf(
    FileInfo fileInfo, 
    String outputDirectory,
    CompressionPreset preset,
  ) async {
    // Map preset to compression level (0.0 = max compression, 1.0 = high quality)
    double quality = 0.5;
    switch (preset) {
      case CompressionPreset.smart:
        quality = 0.5;
        break;
      case CompressionPreset.highQuality:
        quality = 0.8;
        break;
      case CompressionPreset.maxCompression:
        quality = 0.2;
        break;
    }

    final String fileName = path.basenameWithoutExtension(fileInfo.name);
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String targetOutputPath = '$outputDirectory/${fileName}_compressed_$timestamp.pdf';

    try {
      print('Dart: Attempting PDF Compression...');
      print('Dart: Quality: $quality');
      
      // Try native iOS compression first
      try {
        final String? compressedPath = await _channel.invokeMethod<String>(
          'compressPdf',
          {
            'inputPath': fileInfo.path,
            'outputPath': targetOutputPath,
            'quality': quality,
          },
        );

        if (compressedPath != null) {
          final File compressedFile = File(compressedPath);
          if (await compressedFile.exists()) {
            final int compressedSize = await compressedFile.length();
            print('Dart: Native compression - Final Size: $compressedSize bytes');
            print('Dart: Ratio: ${(compressedSize / fileInfo.sizeInBytes * 100).toStringAsFixed(2)}%');
            
            if (compressedSize < fileInfo.sizeInBytes) {
              return FileInfo(
                name: path.basename(compressedFile.path),
                path: compressedFile.path,
                sizeInBytes: fileInfo.sizeInBytes,
                compressedPath: compressedFile.path,
                compressedSizeInBytes: compressedSize,
                dateAdded: DateTime.now(),
              );
            }
          }
        }
      } catch (nativeError) {
        print('Dart: Native compression failed: $nativeError');
      }
      
      // If compression failed or didn't reduce size, return original
      print('Dart: Compression ineffective or failed. Returning original.');
      return fileInfo.copyWith(
        compressedPath: fileInfo.path,
        compressedSizeInBytes: fileInfo.sizeInBytes,
      );

    } catch (e) {
      print('PDF Compression failed: $e');
      return fileInfo.copyWith(
        compressedPath: fileInfo.path,
        compressedSizeInBytes: fileInfo.sizeInBytes,
      );
    }
  }
}
