/// Base exception class for recorder errors
/// 
/// Provides structured error information with type classification
/// and original error context for debugging.
class RecorderException implements Exception {
  /// Human-readable error message
  final String message;
  
  /// Type of error that occurred
  final RecorderErrorType type;
  
  /// Original error object (if any)
  final dynamic originalError;
  
  /// Stack trace (if available)
  final StackTrace? stackTrace;

  RecorderException(
    this.message,
    this.type, [
    this.originalError,
    this.stackTrace,
  ]);

  @override
  String toString() {
    final buffer = StringBuffer('RecorderException: $message');
    buffer.write(' (type: ${type.name})');
    
    if (originalError != null) {
      buffer.write('\nOriginal error: $originalError');
    }
    
    if (stackTrace != null) {
      buffer.write('\nStack trace:\n$stackTrace');
    }
    
    return buffer.toString();
  }

  /// Creates a permission denied exception
  factory RecorderException.permissionDenied([String? details]) {
    return RecorderException(
      details ?? 'Microphone permission denied',
      RecorderErrorType.permissionDenied,
    );
  }

  /// Creates an initialization failed exception
  factory RecorderException.initializationFailed([dynamic error]) {
    return RecorderException(
      'Failed to initialize recorder',
      RecorderErrorType.initializationFailed,
      error,
    );
  }

  /// Creates a recording failed exception
  factory RecorderException.recordingFailed([dynamic error]) {
    return RecorderException(
      'Recording operation failed',
      RecorderErrorType.recordingFailed,
      error,
    );
  }

  /// Creates a file not found exception
  factory RecorderException.fileNotFound(String path) {
    return RecorderException(
      'Recording file not found: $path',
      RecorderErrorType.fileNotFound,
    );
  }

  /// Creates a storage error exception
  factory RecorderException.storageError([dynamic error]) {
    return RecorderException(
      'Storage operation failed',
      RecorderErrorType.storageError,
      error,
    );
  }

  /// Creates an invalid state exception
  factory RecorderException.invalidState(String message) {
    return RecorderException(
      message,
      RecorderErrorType.invalidState,
    );
  }

  /// Creates an audio session error exception
  factory RecorderException.audioSessionError([dynamic error]) {
    return RecorderException(
      'Audio session configuration failed',
      RecorderErrorType.audioSessionError,
      error,
    );
  }

  /// Creates a disposed error exception
  factory RecorderException.disposed() {
    return RecorderException(
      'Recorder has been disposed and cannot be used',
      RecorderErrorType.disposed,
    );
  }
}

/// Types of errors that can occur in the recorder
enum RecorderErrorType {
  /// Microphone permission was denied
  permissionDenied,
  
  /// Recorder initialization failed
  initializationFailed,
  
  /// Recording operation failed
  recordingFailed,
  
  /// Recording file was not found
  fileNotFound,
  
  /// Storage operation failed
  storageError,
  
  /// Invalid state for the requested operation
  invalidState,
  
  /// Audio session configuration failed
  audioSessionError,
  
  /// Recorder has been disposed
  disposed,
  
  /// Unknown error
  unknown,
}
