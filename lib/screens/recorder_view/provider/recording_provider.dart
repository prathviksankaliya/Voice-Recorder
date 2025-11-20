import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import '../../../core/enums/enums.dart';
import '../../../core/models/interruption_data.dart';
import '../manager/recorder_manager.dart';

/// Provider for managing recording state and operations
/// 
/// This provider wraps the RecorderManager and exposes recording functionality
/// to the UI layer using the Provider pattern (ChangeNotifier).
/// 
/// Features:
/// - Manages recording state (idle, recording, paused, stopped)
/// - Handles all recording operations (start, pause, resume, stop, etc.)
/// - Listens to interruptions and auto-pauses when needed
/// - Provides waveform data for visualization
/// - Tracks recording duration
/// 
/// Usage:
/// ```dart
/// final provider = Provider.of<RecordingProvider>(context);
/// await provider.startRecording();
/// ```
class RecordingProvider extends ChangeNotifier {
  /// The recorder manager that handles all recording operations
  final RecorderManager _manager;

  /// Stream subscriptions
  StreamSubscription<InterruptionData>? _interruptionSubscription;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  /// Whether the provider is initialized
  bool _isInitialized = false;

  /// Current error message (if any)
  String? _errorMessage;

  /// Recording start time
  DateTime? _recordingStartTime;

  /// Recording duration timer
  Timer? _durationTimer;

  /// Current recording duration
  Duration _recordingDuration = Duration.zero;

  /// Accumulated duration from previous recording segments (before pauses)
  Duration _accumulatedDuration = Duration.zero;

  /// Last interruption that occurred
  InterruptionData? _lastInterruption;

  /// Creates a RecordingProvider
  /// 
  /// [manager] - Optional RecorderManager for dependency injection (testing)
  RecordingProvider({RecorderManager? manager})
      : _manager = manager ?? RecorderManager();

  // ==================== Getters ====================

  /// Whether the provider is initialized
  bool get isInitialized => _isInitialized;

  /// Current recording state
  RecordingState get recordingState => _manager.recordingState;

  /// Whether currently recording
  bool get isRecording => _manager.isRecording;

  /// Whether recording is paused
  bool get isPaused => _manager.isPaused;

  /// Whether recording is stopped
  bool get isStopped => _manager.isStopped;

  /// Current recording file name
  String? get currentRecordingFileName => _manager.currentRecordingFileName;

  /// Current recording full path
  String? get currentRecordingFullPath => _manager.currentRecordingFullPath;

  /// Current error message
  String? get errorMessage => _errorMessage;

  /// Recording duration
  Duration get recordingDuration => _recordingDuration;

  /// Recording duration as formatted string (MM:SS)
  String get formattedDuration {
    final minutes = _recordingDuration.inMinutes.toString().padLeft(2, '0');
    final seconds = (_recordingDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Waveform buffer for visualization
  List<double> get waveformBuffer => _manager.waveformBuffer;

  /// Whether waveform data is available
  bool get hasWaveformData => _manager.hasAmplitudeData;

  /// Last interruption that occurred
  InterruptionData? get lastInterruption => _lastInterruption;

  /// Stream of waveform data
  Stream<List<double>> get waveformStream => _manager.waveManager.waveformStream;

  // ==================== Initialization ====================

  /// Initializes the recording provider
  /// 
  /// Must be called before any recording operations.
  /// Sets up the recorder manager and stream listeners.
  /// 
  /// Returns true if initialization was successful.
  Future<bool> initialize() async {
    try {
      _clearError();

      // Initialize manager
      final success = await _manager.initialize();
      if (!success) {
        _setError('Failed to initialize recorder');
        return false;
      }

      // Setup stream listeners
      _setupStreamListeners();

      _isInitialized = true;
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Initialization error: $e');
      return false;
    }
  }

  /// Sets up stream listeners for interruptions and amplitude
  void _setupStreamListeners() {
    // Listen to interruptions
    _interruptionSubscription = _manager.interruptionStream.listen(
      _handleInterruption,
      onError: (error) {
        print('RecordingProvider: Interruption stream error - $error');
      },
    );

    // Listen to amplitude for real-time updates
    _amplitudeSubscription = _manager.amplitudeStream.listen(
      (amplitude) {
        // Notify listeners for waveform updates
        // The waveform data is managed by WaveDataManager
        notifyListeners();
      },
      onError: (error) {
        print('RecordingProvider: Amplitude stream error - $error');
      },
    );
  }

  /// Handles audio interruptions
  /// 
  /// Automatically pauses recording when interruption occurs
  void _handleInterruption(InterruptionData interruption) {
    print('RecordingProvider: Interruption detected - ${interruption.type}');

    _lastInterruption = interruption;

    // Auto-pause if recording and interruption requires it
    if (interruption.shouldPause && isRecording) {
      pauseRecording();
      _setError('Recording paused: ${interruption.type.name}');
    }

    notifyListeners();
  }

  // ==================== Recording Operations ====================

  /// Starts a new recording
  /// 
  /// Initializes if not already initialized.
  /// Starts the recorder and duration timer.
  Future<void> startRecording() async {
    try {
      _clearError();

      // Initialize if needed
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          return;
        }
      }

      // Start recording
      await _manager.startRecording();

      // Reset and start duration timer
      _recordingStartTime = DateTime.now();
      _recordingDuration = Duration.zero;
      _accumulatedDuration = Duration.zero;
      _startDurationTimer();

      notifyListeners();
    } catch (e) {
      _setError('Failed to start recording: $e');
    }
  }

  /// Pauses the current recording
  Future<void> pauseRecording() async {
    try {
      _clearError();

      if (!isRecording) {
        _setError('Cannot pause - not recording');
        return;
      }

      // Save the current duration before pausing
      final startTime = _recordingStartTime;
      if (startTime != null) {
        _accumulatedDuration += DateTime.now().difference(startTime);
      }

      await _manager.pauseRecording();

      // Stop duration timer
      _stopDurationTimer();

      // Update duration to show accumulated time
      _recordingDuration = _accumulatedDuration;

      notifyListeners();
    } catch (e) {
      _setError('Failed to pause recording: $e');
    }
  }

  /// Resumes a paused recording
  Future<void> resumeRecording() async {
    try {
      _clearError();

      if (!isPaused) {
        _setError('Cannot resume - not paused');
        return;
      }

      await _manager.resumeRecording();

      // Reset start time for the new recording segment
      _recordingStartTime = DateTime.now();

      // Restart duration timer
      _startDurationTimer();

      notifyListeners();
    } catch (e) {
      _setError('Failed to resume recording: $e');
    }
  }

  /// Stops the recording and saves the file
  /// 
  /// Returns the saved file and timestamp, or null if failed.
  Future<(File, DateTime)?> stopRecording() async {
    try {
      _clearError();

      if (!isRecording && !isPaused) {
        _setError('No active recording to stop');
        return null;
      }

      // Stop duration timer
      _stopDurationTimer();

      // Stop recording
      final result = await _manager.stopRecording();

      // Reset duration
      _recordingDuration = Duration.zero;
      _recordingStartTime = null;

      notifyListeners();

      return result;
    } catch (e) {
      _setError('Failed to stop recording: $e');
      return null;
    }
  }

  /// Deletes the current recording
  Future<void> deleteRecording() async {
    try {
      _clearError();

      await _manager.deleteRecording();

      // Stop and reset duration timer
      _stopDurationTimer();
      _recordingDuration = Duration.zero;
      _recordingStartTime = null;

      notifyListeners();
    } catch (e) {
      _setError('Failed to delete recording: $e');
    }
  }

  /// Restarts the recording
  /// 
  /// Stops current recording and starts a new one.
  Future<void> restartRecording() async {
    try {
      _clearError();

      await _manager.restartRecording();

      // Reset and restart duration timer
      _recordingStartTime = DateTime.now();
      _recordingDuration = Duration.zero;
      _startDurationTimer();

      notifyListeners();
    } catch (e) {
      _setError('Failed to restart recording: $e');
    }
  }

  // ==================== Duration Timer ====================

  /// Starts the duration timer
  void _startDurationTimer() {
    _stopDurationTimer(); // Stop any existing timer

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final startTime = _recordingStartTime;
      if (startTime != null) {
        // Add accumulated duration from previous segments
        _recordingDuration = _accumulatedDuration + DateTime.now().difference(startTime);
        notifyListeners();
      }
    });
  }

  /// Stops the duration timer
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  // ==================== Error Handling ====================

  /// Sets an error message and notifies listeners
  void _setError(String message) {
    _errorMessage = message;
    print('RecordingProvider: Error - $message');
    notifyListeners();
  }

  /// Clears the current error message
  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Clears the last interruption
  void clearInterruption() {
    _lastInterruption = null;
    notifyListeners();
  }

  // ==================== Cleanup ====================

  /// Resets the provider to initial state
  Future<void> reset() async {
    try {
      _clearError();

      await _manager.reset();

      _stopDurationTimer();
      _recordingDuration = Duration.zero;
      _recordingStartTime = null;
      _lastInterruption = null;

      notifyListeners();
    } catch (e) {
      _setError('Failed to reset: $e');
    }
  }

  @override
  void dispose() {
    print('RecordingProvider: Disposing...');
    
    // Cancel subscriptions
    _interruptionSubscription?.cancel();
    _amplitudeSubscription?.cancel();

    // Stop timer
    _stopDurationTimer();

    // Dispose manager (this should stop background service)
    _manager.dispose();
    
    print('RecordingProvider: Disposed');

    super.dispose();
  }
}
