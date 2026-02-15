import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class RemotePdfCompressor {
  static const String _baseUrl = 'https://pdfcompress.odtdoceditor.com/compress';

  /// Compresses a PDF file using the remote backend API
  /// 
  /// [file] - The PDF file to compress
  /// [quality] - Compression level (0=low compression, 4=max compression/smallest size). Defaults to 3.
  /// 
  /// Returns the compressed PDF file, or null if compression fails
  Future<File?> compressPdf({required File file, int quality = 3}) async {
    try {
      // Validate quality parameter
      final compressionLevel = quality.clamp(0, 4);
      
      print('RemotePdfCompressor: Starting compression with level $compressionLevel');
      print('RemotePdfCompressor: Input file: ${file.path}');
      print('RemotePdfCompressor: Input size: ${await file.length()} bytes');

      // Check if file exists
      if (!await file.exists()) {
        print('RemotePdfCompressor: Error - File does not exist');
        return null;
      }

      // Create multipart request
      final uri = Uri.parse('$_baseUrl?level=$compressionLevel');
      final request = http.MultipartRequest('POST', uri);
      
      // Add file to request
      final fileStream = file.openRead();
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: path.basename(file.path),
      );
      request.files.add(multipartFile);

      print('RemotePdfCompressor: Sending request to $uri');

      // Send request and get response stream
      final streamedResponse = await request.send();
      
      // Check status code
      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        print('RemotePdfCompressor: Error - Status ${streamedResponse.statusCode}: $errorBody');
        return null;
      }

      print('RemotePdfCompressor: Received response (${streamedResponse.statusCode})');

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputFileName = 'compressed_${path.basenameWithoutExtension(file.path)}_$timestamp.pdf';
      final outputPath = path.join(tempDir.path, outputFileName);

      // Read binary response stream and save to file
      final responseBytes = await http.Response.fromStream(streamedResponse);
      
      if (responseBytes.bodyBytes.isEmpty) {
        print('RemotePdfCompressor: Error - Empty response body');
        return null;
      }

      // Write compressed PDF to temporary file
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(responseBytes.bodyBytes);

      final outputSize = await outputFile.length();
      print('RemotePdfCompressor: Compression complete');
      print('RemotePdfCompressor: Output file: $outputPath');
      print('RemotePdfCompressor: Output size: $outputSize bytes');
      print('RemotePdfCompressor: Compression ratio: ${((outputSize / fileLength) * 100).toStringAsFixed(2)}%');

      return outputFile;

    } catch (e, stackTrace) {
      print('RemotePdfCompressor: Exception occurred: $e');
      print('RemotePdfCompressor: Stack trace: $stackTrace');
      return null;
    }
  }
}

