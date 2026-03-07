import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import '../../version_a/models/file_info.dart';
import '../../version_a/models/compression_options.dart';

/// Compresses Microsoft Office files (DOCX, PPTX, XLSX) by opening their
/// internal ZIP structure, finding embedded images, compressing them, and
/// repacking the archive. Typically achieves 50–80% reduction on
/// presentation/document files with photo-heavy content.
class OfficeCompressionService {
  static const List<String> officeExtensions = [
    '.docx', '.docm',
    '.pptx', '.pptm',
    '.xlsx', '.xlsm',
  ];

  bool isOfficeFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return officeExtensions.contains(ext);
  }

  Future<FileInfo> compressOffice({
    required FileInfo fileInfo,
    required String outputDirectory,
    required CompressionPreset preset,
  }) async {
    final File file = File(fileInfo.path);
    if (!await file.exists()) throw Exception('File not found: ${fileInfo.path}');

    final Uint8List bytes = await file.readAsBytes();
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      // Not a valid ZIP — return original
      return fileInfo.copyWith(
        compressedPath: fileInfo.path,
        compressedSizeInBytes: fileInfo.sizeInBytes,
      );
    }

    int imageQuality;
    switch (preset) {
      case CompressionPreset.smart:
        imageQuality = 75;
        break;
      case CompressionPreset.highQuality:
        imageQuality = 88;
        break;
      case CompressionPreset.maxCompression:
        imageQuality = 55;
        break;
    }

    final Archive outputArchive = Archive();
    int imagesCompressed = 0;
    int tempIndex = 0;

    for (final ArchiveFile entry in archive) {
      if (!entry.isFile) {
        outputArchive.addFile(ArchiveFile(entry.name, 0, <int>[]));
        continue;
      }

      final String entryLower = entry.name.toLowerCase();

      // Embedded images live in media/ folders inside Office documents
      final bool isEmbeddedImage = _isMediaImage(entryLower);

      if (isEmbeddedImage) {
        final List<int> originalBytes = entry.content as List<int>;
        List<int> finalBytes = originalBytes;

        try {
          final String tempIn = '$outputDirectory/tmp_office_in_$tempIndex.jpg';
          final String tempOut = '$outputDirectory/tmp_office_out_$tempIndex.webp';
          tempIndex++;

          await File(tempIn).writeAsBytes(originalBytes);

          // Convert to WebP for Office images — significant savings, widely supported
          final CompressFormat format = entryLower.endsWith('.png')
              ? CompressFormat.webp
              : CompressFormat.jpeg;
          final String outExt = format == CompressFormat.webp ? '.webp' : '.jpg';
          final String tempOutFinal = tempOut.replaceAll('.webp', outExt);

          final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
            tempIn,
            tempOutFinal,
            quality: imageQuality,
            format: format,
          );

          if (compressed != null) {
            final List<int> compressedBytes = await File(compressed.path).readAsBytes();
            if (compressedBytes.length < originalBytes.length) {
              finalBytes = compressedBytes;
              imagesCompressed++;
            }
            try { await File(compressed.path).delete(); } catch (_) {}
          }
          try { await File(tempIn).delete(); } catch (_) {}
        } catch (_) {
          // Keep original bytes if compression fails
        }

        outputArchive.addFile(ArchiveFile(entry.name, finalBytes.length, finalBytes));
      } else {
        outputArchive.addFile(ArchiveFile(entry.name, entry.size, entry.content));
      }
    }

    final int zipLevel = preset == CompressionPreset.maxCompression ? 9 : 6;
    final List<int>? newZipBytes = ZipEncoder().encode(outputArchive, level: zipLevel);

    if (newZipBytes == null) {
      throw Exception('Failed to re-encode office file');
    }

    // Only return the compressed version if it's actually smaller
    if (newZipBytes.length >= fileInfo.sizeInBytes) {
      return fileInfo.copyWith(
        compressedPath: fileInfo.path,
        compressedSizeInBytes: fileInfo.sizeInBytes,
      );
    }

    final String fileName = path.basenameWithoutExtension(fileInfo.name);
    final String ext = path.extension(fileInfo.name);
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String outputPath = '$outputDirectory/${fileName}_compressed_$timestamp$ext';

    await File(outputPath).writeAsBytes(newZipBytes);

    return FileInfo(
      name: path.basename(outputPath),
      path: outputPath,
      sizeInBytes: fileInfo.sizeInBytes,
      compressedPath: outputPath,
      compressedSizeInBytes: newZipBytes.length,
      dateAdded: DateTime.now(),
      formatNote: imagesCompressed > 0
          ? 'Compressed $imagesCompressed embedded image${imagesCompressed == 1 ? '' : 's'}'
          : null,
    );
  }

  bool _isMediaImage(String entryPath) {
    // Match media folders in Office ZIP structures
    final bool inMediaFolder = entryPath.contains('/media/') ||
        entryPath.contains('\\media\\') ||
        entryPath.startsWith('media/');
    if (!inMediaFolder) return false;

    return entryPath.endsWith('.jpg') ||
        entryPath.endsWith('.jpeg') ||
        entryPath.endsWith('.png') ||
        entryPath.endsWith('.bmp') ||
        entryPath.endsWith('.tiff') ||
        entryPath.endsWith('.tif');
  }
}
