import '../enums/enums.dart';

/// Data model for audio interruption events
/// 
/// This class encapsulates information about an interruption that occurred
/// during recording, such as phone calls, headphone disconnections, etc.
class InterruptionData {
  /// The type of interruption that occurred
  final InterruptionType type;
  
  /// Whether the recording is currently interrupted
  final bool isInterrupted;
  
  /// When the interruption occurred
  final DateTime timestamp;
  
  /// Whether the recording should be automatically paused
  final bool shouldPause;

  /// Creates an interruption data instance
  /// 
  /// [type] - The type of interruption
  /// [isInterrupted] - Current interruption status
  /// [timestamp] - When the interruption occurred
  /// [shouldPause] - Whether to auto-pause recording
  InterruptionData({
    required this.type,
    required this.isInterrupted,
    required this.timestamp,
    required this.shouldPause,
  });

  @override
  String toString() {
    return 'InterruptionData(type: $type, isInterrupted: $isInterrupted, '
        'timestamp: $timestamp, shouldPause: $shouldPause)';
  }
}
