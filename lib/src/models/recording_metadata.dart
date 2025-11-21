import 'dart:convert';

/// Complete metadata for a recording session
/// Tracks all information about the recording
class RecordingMetadata {
  /// Unique recording ID
  final String id;
  
  /// File name (without path)
  final String fileName;
  
  /// Full file path
  final String filePath;
  
  /// Recording start time
  final DateTime startTime;
  
  /// Recording end time (null if still recording)
  final DateTime? endTime;
  
  /// Total recording duration (excluding paused time)
  final Duration duration;
  
  /// Total paused duration
  final Duration pausedDuration;
  
  /// File size in bytes
  final int fileSizeBytes;
  
  /// Recording state when metadata was captured
  final String state;
  
  /// Number of times recording was paused
  final int pauseCount;
  
  /// Custom user data
  final Map<String, dynamic>? customData;
  
  /// Recording configuration used
  final Map<String, dynamic>? configSnapshot;

  const RecordingMetadata({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.startTime,
    this.endTime,
    required this.duration,
    this.pausedDuration = Duration.zero,
    required this.fileSizeBytes,
    required this.state,
    this.pauseCount = 0,
    this.customData,
    this.configSnapshot,
  });

  /// File size in MB
  double get fileSizeMB => fileSizeBytes / (1024 * 1024);
  
  /// File size in KB
  double get fileSizeKB => fileSizeBytes / 1024;
  
  /// Duration in seconds
  int get durationSeconds => duration.inSeconds;
  
  /// Duration in minutes
  double get durationMinutes => duration.inSeconds / 60;
  
  /// Duration formatted as HH:MM:SS or MM:SS
  String get durationFormatted {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}';
    }
    
    return '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}';
  }
  
  /// Whether recording is complete
  bool get isComplete => endTime != null;
  
  /// Actual recording time (start to end)
  Duration? get totalTime {
    final end = endTime;
    if (end == null) return null;
    return end.difference(startTime);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration.inMilliseconds,
      'pausedDuration': pausedDuration.inMilliseconds,
      'fileSizeBytes': fileSizeBytes,
      'state': state,
      'pauseCount': pauseCount,
      'customData': customData,
      'configSnapshot': configSnapshot,
    };
  }
  
  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON
  factory RecordingMetadata.fromJson(Map<String, dynamic> json) {
    return RecordingMetadata(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ?? DateTime.now(),
      endTime: json['endTime'] != null 
          ? DateTime.tryParse(json['endTime'] as String? ?? '') 
          : null,
      duration: Duration(milliseconds: json['duration'] as int? ?? 0),
      pausedDuration: Duration(milliseconds: json['pausedDuration'] as int? ?? 0),
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
      state: json['state'] as String? ?? 'unknown',
      pauseCount: json['pauseCount'] as int? ?? 0,
      customData: json['customData'] as Map<String, dynamic>?,
      configSnapshot: json['configSnapshot'] as Map<String, dynamic>?,
    );
  }
  
  /// Create from JSON string
  factory RecordingMetadata.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return RecordingMetadata.fromJson(json);
  }

  /// Copy with modifications
  RecordingMetadata copyWith({
    String? id,
    String? fileName,
    String? filePath,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    Duration? pausedDuration,
    int? fileSizeBytes,
    String? state,
    int? pauseCount,
    Map<String, dynamic>? customData,
    Map<String, dynamic>? configSnapshot,
  }) {
    return RecordingMetadata(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      pausedDuration: pausedDuration ?? this.pausedDuration,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      state: state ?? this.state,
      pauseCount: pauseCount ?? this.pauseCount,
      customData: customData ?? this.customData,
      configSnapshot: configSnapshot ?? this.configSnapshot,
    );
  }

  @override
  String toString() {
    return 'RecordingMetadata(id: $id, duration: $durationFormatted, size: ${fileSizeMB.toStringAsFixed(2)}MB)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is RecordingMetadata &&
        other.id == id &&
        other.fileName == fileName &&
        other.filePath == filePath;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^ fileName.hashCode ^ filePath.hashCode;
  }
}
