import 'file_info.dart';

class CompressionHistory {
  final String id;
  final List<FileInfo> files;
  final DateTime timestamp;
  final String outputPath;
  final int totalOriginalSize;
  final int totalCompressedSize;
  
  CompressionHistory({
    required this.id,
    required this.files,
    required this.timestamp,
    required this.outputPath,
    required this.totalOriginalSize,
    required this.totalCompressedSize,
  });
  
  double get totalCompressionRatio {
    if (totalOriginalSize == 0) return 0;
    return ((totalOriginalSize - totalCompressedSize) / totalOriginalSize) * 100;
  }
  
  double get totalSizeSavedInMB => (totalOriginalSize - totalCompressedSize) / (1024 * 1024);
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'files': files.map((f) => f.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'outputPath': outputPath,
      'totalOriginalSize': totalOriginalSize,
      'totalCompressedSize': totalCompressedSize,
    };
  }
  
  factory CompressionHistory.fromJson(Map<String, dynamic> json) {
    return CompressionHistory(
      id: json['id'],
      files: (json['files'] as List).map((f) => FileInfo.fromJson(f)).toList(),
      timestamp: DateTime.parse(json['timestamp']),
      outputPath: json['outputPath'],
      totalOriginalSize: json['totalOriginalSize'],
      totalCompressedSize: json['totalCompressedSize'],
    );
  }
}
