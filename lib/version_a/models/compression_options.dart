enum CompressionPreset {
  smart('Balanced', 'Best quality/size ratio — recommended', 'Typically 50–80% smaller'),
  highQuality('Near Original', 'Minimal quality loss, moderate reduction', 'Typically 15–40% smaller'),
  maxCompression('Smallest File', 'Maximum reduction — converts to efficient formats', 'Typically 70–95% smaller');

  const CompressionPreset(this.name, this.description, this.expectedSavings);
  final String name;
  final String description;
  final String expectedSavings;
}
