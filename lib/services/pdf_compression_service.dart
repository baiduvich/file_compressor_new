import 'dart:io';
import 'package:pdf_compressor_pro/pdf_compressor.dart';
import '../models/compression_options.dart';
import '../models/file_info.dart';
import 'package:path/path.dart' as path;

class PdfCompressionService {
  Future<FileInfo> compressPdf(
    FileInfo fileInfo, 
    String outputDirectory,
    CompressionPreset preset,
  ) async {
    // Map preset to CompressionLevel
    CompressionLevel quality = CompressionLevel.medium;
    switch (preset) {
      case CompressionPreset.smart:
        quality = CompressionLevel.medium;
        break;
      case CompressionPreset.highQuality:
        quality = CompressionLevel.high;
        break;
      case CompressionPreset.maxCompression:
        quality = CompressionLevel.low;
        break;
    }

    final String fileName = path.basenameWithoutExtension(fileInfo.name);
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    final String targetOutputPath = '$outputDirectory/${fileName}_compressed_$timestamp.pdf';

    try {
      print('Dart: Requesting PDF Compressor (Pro)...');
      print('Dart: Quality: $quality');
      
      // Call PdfCompressor.compressPdf(sourcePath, {level})
      final CompressResult result = await PdfCompressor.compressPdf(
        fileInfo.path,
        level: quality,
      );

      print('Dart: Original Result Path: ${result.compressedPath}');
      print('Dart: Original Size: ${result.originalSizeMB} MB');
      print('Dart: Compressed Size: ${result.compressedSizeMB} MB');

      final File compressedFile = File(result.compressedPath);
      
      if (await compressedFile.exists()) {
          // Move/Copy to our desired target path
          await compressedFile.copy(targetOutputPath);
          
          final File finalFile = File(targetOutputPath);
          final int compressedSize = await finalFile.length();
          
          print('Dart: Final Size: $compressedSize');
          print('Dart: Ratio: ${(compressedSize / fileInfo.sizeInBytes * 100).toStringAsFixed(2)}%');
          
          if (compressedSize >= fileInfo.sizeInBytes) {
             print('Dart: Compression ineffective. Returning original.');
             // cleanup
             try { await finalFile.delete(); } catch (_) {}
             // Also delete the temp file from package if appropriate, 
             // but we don't own it. It might be in cache. 
             // We can try to delete the source compressedFile if it was a temp.
             // Given it's a result, it likely is.
             try { await compressedFile.delete(); } catch (_) {}
             
             return fileInfo.copyWith(
               compressedPath: fileInfo.path, 
               compressedSizeInBytes: fileInfo.sizeInBytes
             );
          }
          
          // Cleanup temp file
          try { await compressedFile.delete(); } catch (_) {}

          return FileInfo(
            name: path.basename(finalFile.path),
            path: finalFile.path,
            sizeInBytes: fileInfo.sizeInBytes,
            compressedPath: finalFile.path,
            compressedSizeInBytes: compressedSize,
            dateAdded: DateTime.now(),
          );
      } else {
         throw Exception("Compressed file not created at ${result.compressedPath}");
      }

    } catch (e) {
      print('PDF Compression failed: $e');
      return fileInfo.copyWith(
        compressedPath: fileInfo.path,
        compressedSizeInBytes: fileInfo.sizeInBytes,
      );
    }
  }
}
