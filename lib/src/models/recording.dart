import 'dart:io';

/// Recording metadata returned by stop()
class Recording {
  const Recording({
    required this.path,
    required this.file,
    required this.duration,
    required this.sizeInBytes,
    required this.timestamp,
  });

  /// Full file path
  final String path;
  
  /// File object
  final File file;
  
  /// Duration (excludes pause time)
  final Duration duration;
  
  /// File size in bytes
  final int sizeInBytes;
  
  /// When recording stopped
  final DateTime timestamp;
  
  /// File name only
  String get fileName => path.split('/').last;
  
  @override
  String toString() {
    return 'Recording(path: $path, duration: ${duration.inSeconds}s, size: $sizeInBytes bytes)';
  }
}
