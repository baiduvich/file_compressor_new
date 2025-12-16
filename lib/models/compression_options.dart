enum CompressionPreset {
  smart('Smart', 'Automatically optimizes quality & size'),
  highQuality('High Quality', 'Prioritizes quality over size'),
  maxCompression('Max Compression', 'Smallest possible size');

  const CompressionPreset(this.name, this.description);
  final String name;
  final String description;
}

// Legacy enums removed: CompressionMode, CompressionLevel, SmartCompressionQuality
