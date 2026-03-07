class FileInfo {
  final String name;
  final String path;
  final int sizeInBytes;
  final String? compressedPath;
  final int? compressedSizeInBytes;
  final DateTime dateAdded;
  // Human-readable note about format conversion, e.g. "PNG → WebP", "WAV → M4A (AAC)"
  final String? formatNote;

  FileInfo({
    required this.name,
    required this.path,
    required this.sizeInBytes,
    this.compressedPath,
    this.compressedSizeInBytes,
    required this.dateAdded,
    this.formatNote,
  });

  double get sizeInMB => sizeInBytes / (1024 * 1024);
  double? get compressedSizeInMB =>
      compressedSizeInBytes != null ? compressedSizeInBytes! / (1024 * 1024) : null;

  double? get compressionRatio {
    if (compressedSizeInBytes == null || sizeInBytes == 0) return null;
    return ((sizeInBytes - compressedSizeInBytes!) / sizeInBytes) * 100;
  }

  bool get wasAlreadyOptimized {
    if (compressedSizeInBytes == null) return false;
    return compressedSizeInBytes! >= (sizeInBytes * 0.97).round();
  }

  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : 'unknown';
  }

  FileInfo copyWith({
    String? name,
    String? path,
    int? sizeInBytes,
    String? compressedPath,
    int? compressedSizeInBytes,
    DateTime? dateAdded,
    String? formatNote,
  }) {
    return FileInfo(
      name: name ?? this.name,
      path: path ?? this.path,
      sizeInBytes: sizeInBytes ?? this.sizeInBytes,
      compressedPath: compressedPath ?? this.compressedPath,
      compressedSizeInBytes: compressedSizeInBytes ?? this.compressedSizeInBytes,
      dateAdded: dateAdded ?? this.dateAdded,
      formatNote: formatNote ?? this.formatNote,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'sizeInBytes': sizeInBytes,
      'compressedPath': compressedPath,
      'compressedSizeInBytes': compressedSizeInBytes,
      'dateAdded': dateAdded.toIso8601String(),
      'formatNote': formatNote,
    };
  }

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      name: json['name'],
      path: json['path'],
      sizeInBytes: json['sizeInBytes'],
      compressedPath: json['compressedPath'],
      compressedSizeInBytes: json['compressedSizeInBytes'],
      dateAdded: DateTime.parse(json['dateAdded']),
      formatNote: json['formatNote'],
    );
  }
}
