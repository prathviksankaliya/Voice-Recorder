import 'dart:async';

/// Service for tracking recording duration with pause support
/// Syncs with actual recording state
class RecordingTimerService {
  /// Recording start time
  DateTime? _startTime;
  
  /// Current pause start time
  DateTime? _pauseStartTime;
  
  /// Total paused duration
  Duration _totalPausedDuration = Duration.zero;
  
  /// Number of pauses
  int _pauseCount = 0;
  
  /// Timer for periodic updates
  Timer? _timer;
  
  /// Stream controller for duration updates
  final StreamController<Duration> _durationController = 
      StreamController<Duration>.broadcast();
  
  /// Update interval
  final Duration updateInterval;

  RecordingTimerService({
    this.updateInterval = const Duration(milliseconds: 100),
  });

  /// Stream of duration updates
  Stream<Duration> get durationStream => _durationController.stream;

  /// Current recording duration (excluding paused time)
  Duration get currentDuration {
    final start = _startTime;
    if (start == null) return Duration.zero;
    
    final now = DateTime.now();
    final totalElapsed = now.difference(start);
    
    // Calculate current pause duration if paused
    var pausedTime = _totalPausedDuration;
    final pauseStart = _pauseStartTime;
    if (pauseStart != null) {
      pausedTime += now.difference(pauseStart);
    }
    
    final result = totalElapsed - pausedTime;
    return result.isNegative ? Duration.zero : result;
  }

  /// Total paused duration
  Duration get pausedDuration => _totalPausedDuration;

  /// Number of times paused
  int get pauseCount => _pauseCount;

  /// Recording start time
  DateTime? get startTime => _startTime;

  /// Whether timer is running
  bool get isRunning => _startTime != null && _pauseStartTime == null;

  /// Whether timer is paused
  bool get isPaused => _pauseStartTime != null;

  /// Start the timer
  void start() {
    if (_startTime != null) {
      print('RecordingTimerService: Timer already started');
      return;
    }

    _startTime = DateTime.now();
    _totalPausedDuration = Duration.zero;
    _pauseCount = 0;
    _pauseStartTime = null;

    _startPeriodicUpdates();
    
    print('RecordingTimerService: Timer started');
  }

  /// Pause the timer
  void pause() {
    if (_pauseStartTime != null) {
      print('RecordingTimerService: Timer already paused');
      return;
    }

    if (_startTime == null) {
      print('RecordingTimerService: Timer not started');
      return;
    }

    _pauseStartTime = DateTime.now();
    _pauseCount++;
    
    _stopPeriodicUpdates();
    
    print('RecordingTimerService: Timer paused (count: $_pauseCount)');
  }

  /// Resume the timer
  void resume() {
    final pauseStart = _pauseStartTime;
    if (pauseStart == null) {
      print('RecordingTimerService: Timer not paused');
      return;
    }

    final pauseDuration = DateTime.now().difference(pauseStart);
    _totalPausedDuration += pauseDuration;
    _pauseStartTime = null;

    _startPeriodicUpdates();
    
    print('RecordingTimerService: Timer resumed (paused for ${pauseDuration.inSeconds}s)');
  }

  /// Stop the timer and return final duration
  Duration stop() {
    if (_startTime == null) {
      print('RecordingTimerService: Timer not started');
      return Duration.zero;
    }

    // If paused, add final pause duration
    final pauseStart = _pauseStartTime;
    if (pauseStart != null) {
      final pauseDuration = DateTime.now().difference(pauseStart);
      _totalPausedDuration += pauseDuration;
      _pauseStartTime = null;
    }

    final finalDuration = currentDuration;
    
    _stopPeriodicUpdates();
    _reset();
    
    print('RecordingTimerService: Timer stopped - Duration: ${finalDuration.inSeconds}s');
    return finalDuration;
  }

  /// Reset the timer
  void _reset() {
    _startTime = null;
    _pauseStartTime = null;
    _totalPausedDuration = Duration.zero;
    _pauseCount = 0;
  }

  /// Start periodic duration updates
  void _startPeriodicUpdates() {
    _stopPeriodicUpdates();
    
    _timer = Timer.periodic(updateInterval, (timer) {
      if (!_durationController.isClosed) {
        _durationController.add(currentDuration);
      }
    });
  }

  /// Stop periodic updates
  void _stopPeriodicUpdates() {
    _timer?.cancel();
    _timer = null;
  }

  /// Get current state as string
  String get stateString {
    if (_startTime == null) return 'idle';
    if (_pauseStartTime != null) return 'paused';
    return 'recording';
  }

  /// Dispose the service
  Future<void> dispose() async {
    _stopPeriodicUpdates();
    await _durationController.close();
    print('RecordingTimerService: Disposed');
  }
}
