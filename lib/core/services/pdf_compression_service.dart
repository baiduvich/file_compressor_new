import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../version_a/models/compression_options.dart';
import '../../version_a/models/file_info.dart';

class PdfCompressionService {
  static const String _baseUrl = 'https://pdfcompress.odtdoceditor.com';

  static int _levelForPreset(CompressionPreset preset) {
    switch (preset) {
      case CompressionPreset.highQuality:
        return 1;
      case CompressionPreset.smart:
        return 3;
      case CompressionPreset.maxCompression:
        return 5;
    }
  }

  Future<FileInfo> compressPdf(
    FileInfo fileInfo,
    String outputDirectory,
    CompressionPreset preset,
  ) async {
    final int level = _levelForPreset(preset);
    final String fileName = path.basenameWithoutExtension(fileInfo.name);
    final Directory tmpDir = await getTemporaryDirectory();
    final String localOutputPath =
        '${tmpDir.path}/${fileName}_compressed_${DateTime.now().millisecondsSinceEpoch}.pdf';

    try {
      // ── Step 1: upload file to backend ───────────────────────────────────
      final uri = Uri.parse('$_baseUrl/compress');
      final request = http.MultipartRequest('POST', uri)
        ..fields['level'] = level.toString()
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          fileInfo.path,
          filename: fileInfo.name,
        ));

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 3),
        onTimeout: () => throw Exception('Upload timed out after 3 minutes'),
      );

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        throw Exception('Server error ${streamedResponse.statusCode}: $body');
      }

      final responseBody = await streamedResponse.stream.bytesToString();

      // ── Step 2: parse compressed_url from JSON response ──────────────────
      final compressedUrl = _parseCompressedUrl(responseBody);
      if (compressedUrl == null) {
        throw Exception('No compressed_url in response: $responseBody');
      }

      // ── Step 3: download compressed file ─────────────────────────────────
      final downloadResponse = await http
          .get(Uri.parse(compressedUrl))
          .timeout(const Duration(minutes: 2));

      if (downloadResponse.statusCode != 200) {
        throw Exception('Download failed: HTTP ${downloadResponse.statusCode}');
      }

      // ── Step 4: save to temp directory ───────────────────────────────────
      final outFile = File(localOutputPath);
      await outFile.writeAsBytes(downloadResponse.bodyBytes);

      final int compressedSize = await outFile.length();

      if (compressedSize >= fileInfo.sizeInBytes) {
        await outFile.delete().catchError((_) => outFile);
        return _passthrough(fileInfo);
      }

      return FileInfo(
        name: '${fileName}_compressed.pdf',
        path: fileInfo.path,
        sizeInBytes: fileInfo.sizeInBytes,
        compressedPath: localOutputPath,
        compressedSizeInBytes: compressedSize,
        dateAdded: DateTime.now(),
      );
    } catch (e) {
      // Network unavailable, timeout, or server error — fall back silently
      return _passthrough(fileInfo);
    }
  }

  /// Parses {"compressed_url": "...", "success": true} without adding dart:convert
  /// (keeps the dependency footprint minimal). Falls back to a simple string search.
  String? _parseCompressedUrl(String json) {
    // Look for "compressed_url":"<value>" allowing spaces and both quote styles
    final exp = RegExp(r'"compressed_url"\s*:\s*"([^"]+)"');
    final match = exp.firstMatch(json);
    return match?.group(1);
  }

  FileInfo _passthrough(FileInfo fileInfo) => fileInfo.copyWith(
        compressedPath: fileInfo.path,
        compressedSizeInBytes: fileInfo.sizeInBytes,
      );
}
