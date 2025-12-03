/// Configuration for recording file storage
/// 
/// Controls where and how recording files are stored with user-controlled paths.
class StorageConfig {
  /// User-provided file path (full path including filename)
  /// If null, auto-generates path based on other settings
  final String? userProvidedPath;
  
  /// Use temp directory as fallback
  /// If true and no path provided, uses system temp directory
  final bool useTempDirectory;
  
  /// Auto-generate filename if only directory provided
  final bool autoGenerateFilename;
  
  /// Filename prefix for auto-generated names
  final String filenamePrefix;
  
  /// Filename suffix/extension
  final String fileExtension;

  const StorageConfig({
    this.userProvidedPath,
    this.useTempDirectory = true,
    this.autoGenerateFilename = true,
    this.filenamePrefix = 'recording',
    this.fileExtension = 'm4a',
  });

  /// Use exact file path provided by user
  /// 
  /// Example:
  /// ```dart
  /// StorageConfig.withPath('/storage/emulated/0/Recordings/my_recording.m4a')
  /// ```
  factory StorageConfig.withPath(String filePath) {
    return StorageConfig(
      userProvidedPath: filePath,
      useTempDirectory: false,
      autoGenerateFilename: false,
    );
  }

  /// Use temp directory (default)
  /// Files will be stored in system temp directory
  factory StorageConfig.tempDirectory() {
    return const StorageConfig(
      useTempDirectory: true,
      autoGenerateFilename: true,
    );
  }

  /// Configuration for visible files in app documents directory
  factory StorageConfig.visible() {
    return const StorageConfig(
      useTempDirectory: false,
      autoGenerateFilename: true,
    );
  }

  StorageConfig copyWith({
    String? userProvidedPath,
    String? customDirectory,
    bool? useTempDirectory,
    bool? autoGenerateFilename,
    String? filenamePrefix,
    String? fileExtension,
  }) {
    return StorageConfig(
      userProvidedPath: userProvidedPath ?? this.userProvidedPath,
      useTempDirectory: useTempDirectory ?? this.useTempDirectory,
      autoGenerateFilename: autoGenerateFilename ?? this.autoGenerateFilename,
      filenamePrefix: filenamePrefix ?? this.filenamePrefix,
      fileExtension: fileExtension ?? this.fileExtension,
    );
  }
}
