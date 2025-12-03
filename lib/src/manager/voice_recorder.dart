import 'dart:async';
import 'package:record/record.dart';
import '../enums/enums.dart';
import '../models/interruption_data.dart';
import '../models/recording.dart';
import '../services/audio_session_service.dart';
import '../services/recorder_service.dart';
import '../services/recording_timer_service.dart';
import '../config/recorder_config.dart';
import '../config/storage_config.dart';
import '../exceptions/recorder_exception.dart';

/// Callback invoked when the recording state changes (idle, recording, paused, stopped).
typedef RecordingStateCallback = void Function(RecordingState state);

/// Callback invoked when an error occurs during recording operations.
typedef ErrorCallback = void Function(RecorderException error);

/// Callback invoked when recording is interrupted (phone call, headphones disconnected, etc.).
typedef InterruptionCallback = void Function(InterruptionData interruption);

/// Provides simple API for recording with automatic initialization,
/// pause/resume support, and real-time audio data streams.
/// 
/// **Quick Start**:
/// ```dart
/// final recorder = VoiceRecorder();
/// await recorder.start();  // Auto-initializes if needed
/// final recording = await recorder.stop();
/// print('Saved: ${recording.path}');
/// ```
/// 
/// **With Callbacks**:
/// ```dart
/// final recorder = VoiceRecorder(
///   onStateChanged: (state) => print('State: $state'),
///   onError: (error) => print('Error: ${error.message}'),
///   onInterruption: (data) => print('Interrupted: ${data.type}'),
/// );
/// ```
/// 
/// **Custom Quality**:
/// ```dart
/// await recorder.start(
///   config: RecorderConfig.highQuality(),
///   storageConfig: StorageConfig.withPath('/custom/path.m4a'),
/// );
/// ```
/// 
/// Remember to call [dispose] when done to free resources.
class VoiceRecorder {
  /// Core recording service
  final RecorderService _recorder = RecorderService();
  
  /// Audio session and interruption management
  final AudioSessionService _audioSessionService = AudioSessionService.instance;

  /// Recording timer service for accurate duration tracking
  final RecordingTimerService _timerService = RecordingTimerService();

  /// Callback for state changes
  final RecordingStateCallback? onStateChanged;

  /// Callback for errors
  final ErrorCallback? onError;

  /// Callback for interruptions
  final InterruptionCallback? onInterruption;

  /// Stream subscriptions
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  StreamSubscription<InterruptionData>? _interruptionSubscription;

  /// Controller for broadcasting interruption events to UI
  final StreamController<InterruptionData> _interruptionController =
      StreamController<InterruptionData>.broadcast();

  /// Whether the recorder has been disposed
  bool _isDisposed = false;

  /// Whether the recorder is initialized
  bool _isInitialized = false;

  VoiceRecorder({
    this.onStateChanged,
    this.onError,
    this.onInterruption,
  });

  /// Stream of interruption events (phone calls, headphones disconnected, etc.).
  /// 
  /// Listen to this stream to handle interruptions in your UI.
  Stream<InterruptionData> get interruptionStream => _interruptionController.stream;

  /// Stream of real-time amplitude data for waveform visualization.
  /// 
  /// Emits amplitude values (in decibels) approximately every 100ms while recording.
  /// Use this to build custom audio visualizations.
  Stream<Amplitude> get amplitudeStream => _recorder.amplitudeStream;
  
  /// Stream of recording state changes from the underlying recorder.
  /// 
  /// Emits [RecordState] values when the recorder state changes.
  Stream<RecordState> get onRecordStateChanged => _recorder.onStateChanged;

  /// Stream of duration updates during recording.
  /// 
  /// Emits the current recording duration (excluding paused time).
  /// Updates approximately every second while recording.
  Stream<Duration> get durationStream => _timerService.durationStream;

  /// Current recording state (idle, recording, paused, or stopped).
  RecordingState get recordingState {
    _checkDisposed();
    return _recorder.state;
  }

  /// Whether the recorder is currently recording audio.
  bool get isRecording {
    _checkDisposed();
    return _recorder.isRecording;
  }

  /// Whether the recording is currently paused.
  bool get isPaused {
    _checkDisposed();
    return _recorder.isPaused;
  }

  /// Whether the recording has been stopped.
  bool get isStopped {
    _checkDisposed();
    return _recorder.isStopped;
  }

  /// Whether the recorder has been initialized.
  /// 
  /// Initialization happens automatically on first [start] call.
  bool get isInitialized => _isInitialized;

  /// Whether the recorder has been disposed.
  /// 
  /// Once disposed, the recorder cannot be used again.
  bool get isDisposed => _isDisposed;

  /// Current recording file name (e.g., 'recording_123456.m4a').
  /// 
  /// Returns null if no recording is active.
  String? get currentRecordingFileName {
    _checkDisposed();
    return _recorder.recordingFileName;
  }

  /// Full path to the current recording file.
  /// 
  /// Returns null if no recording is active.
  String? get currentRecordingFullPath {
    _checkDisposed();
    return _recorder.recordingFileFullPath;
  }

  /// Current recording duration (excludes paused time).
  /// 
  /// Returns null if not currently recording or paused.
  /// Use this for displaying recording time in your UI.
  Duration? get currentDuration {
    _checkDisposed();
    if (!isRecording && !isPaused) return null;
    return _timerService.currentDuration;
  }

  /// Checks if the recorder has been disposed
  void _checkDisposed() {
    if (_isDisposed) {
      throw RecorderException.disposed();
    }
  }

  /// Notifies state change callback
  void _notifyStateChange(RecordingState state) {
    onStateChanged?.call(state);
  }

  /// Notifies error callback
  void _notifyError(RecorderException error) {
    print('VoiceRecorder: Error - $error');
    onError?.call(error);
  }

  /// Initialize the recorder manually (optional).
  /// 
  /// The recorder auto-initializes on first [start] call, so calling this
  /// is optional. Use it if you want to initialize early or check permissions
  /// before recording.
  /// 
  /// Returns `true` if initialization succeeds, `false` otherwise.
  /// Throws [RecorderException] if microphone permission is denied.
  Future<bool> initialize() async {
    _checkDisposed();

    if (_isInitialized) {
      print('VoiceRecorder: Already initialized');
      return true;
    }

    try {
      print('VoiceRecorder: Initializing...');

      // 1. Initialize recorder
      final recorderInit = await _recorder.initialize();
      if (!recorderInit) {
        throw RecorderException.initializationFailed('Recorder initialization failed');
      }

      // 2. Initialize audio session
      final audioSessionInit = await _audioSessionService.initialize();
      if (!audioSessionInit) {
        throw RecorderException.initializationFailed('Audio session initialization failed');
      }

      // 3. Setup stream connections
      _setupStreamConnections();

      _isInitialized = true;
      print('VoiceRecorder: Initialization complete');
      return true;
    } catch (e, stackTrace) {
      final error = e is RecorderException 
          ? e 
          : RecorderException.initializationFailed(e);
      _notifyError(error);
      print('VoiceRecorder: Initialization error - $e\n$stackTrace');
      return false;
    }
  }

  /// Sets up connections between services via streams
  void _setupStreamConnections() {
    _interruptionSubscription = _audioSessionService.interruptionEvents.listen(
      (interruption) {
        if (isRecording || isPaused) {
          _interruptionController.add(interruption);
          onInterruption?.call(interruption);
        }
      },
      onError: (error) {
        print('VoiceRecorder: Interruption stream error - $error');
      },
    );

    print('VoiceRecorder: Stream connections established');
  }

  /// Start recording audio.
  /// 
  /// Auto-initializes if not already initialized. Configures audio session
  /// and begins recording with the specified quality and storage settings.
  /// 
  /// **Parameters**:
  /// - [config]: Audio quality configuration (defaults to voice-optimized)
  /// - [storageConfig]: Storage location configuration (defaults to temp directory)
  /// 
  /// **Examples**:
  /// ```dart
  /// // Simple start (temp directory, voice quality)
  /// await recorder.start();
  /// 
  /// // High quality recording
  /// await recorder.start(config: RecorderConfig.highQuality());
  /// 
  /// // Custom storage path
  /// await recorder.start(
  ///   storageConfig: StorageConfig.withPath('/custom/path.m4a'),
  /// );
  /// ```
  /// 
  /// Throws [RecorderException] if recording fails to start.
  Future<void> start({
    RecorderConfig? config,
    StorageConfig? storageConfig,
  }) async {
    _checkDisposed();

    // Auto-initialize if not already initialized (convenience for beginners)
    if (!_isInitialized) {
      print('VoiceRecorder: Auto-initializing...');
      final initialized = await initialize();
      if (!initialized) {
        throw RecorderException.invalidState('Failed to initialize recorder');
      }
    }

    try {
      print('VoiceRecorder: Starting recording...');

      // Set recording config - defaults to voice quality
      final recordConfig = config ?? const RecorderConfig();
      _recorder.updateConfig(recordConfig);

      StorageConfig finalStorageConfig = StorageConfig.tempDirectory();
       if (storageConfig != null) {
        finalStorageConfig = storageConfig;
      }
      
      _recorder.updateStorageConfig(finalStorageConfig);

      // 1. Configure audio session FIRST
      final audioConfigured = await _audioSessionService.configureForRecording();
      if (!audioConfigured) {
        throw RecorderException.audioSessionError('Failed to configure audio session');
      }

      // 2. Start recording
      await _recorder.startRecording();

      // 3. Start duration timer
      _timerService.start();

      _notifyStateChange(RecordingState.recording);
      print('VoiceRecorder: Recording started successfully');
    } catch (e, stackTrace) {
      final error = e is RecorderException 
          ? e 
          : RecorderException.recordingFailed(e);
      _notifyError(error);
      print('VoiceRecorder: Start recording error - $e\n$stackTrace');
      rethrow;
    }
  }

  /// Pause the current recording.
  /// 
  /// Recording can be resumed later with [resume]. The duration timer
  /// pauses as well, so paused time is not included in the final duration.
  /// 
  /// Throws [RecorderException] if not currently recording.
  Future<void> pause() async {
    _checkDisposed();

    if (!isRecording) {
      throw RecorderException.invalidState('Cannot pause - not recording');
    }

    try {
      print('VoiceRecorder: Pausing recording...');

      await _recorder.pauseRecording();
      _timerService.pause();

      _notifyStateChange(RecordingState.paused);
      print('VoiceRecorder: Recording paused');
    } catch (e, stackTrace) {
      final error = e is RecorderException 
          ? e 
          : RecorderException.recordingFailed(e);
      _notifyError(error);
      print('VoiceRecorder: Pause recording error - $e\n$stackTrace');
      rethrow;
    }
  }

  /// Resume a paused recording.
  /// 
  /// Continues recording from where it was paused. The duration timer
  /// resumes as well.
  /// 
  /// Throws [RecorderException] if not currently paused.
  Future<void> resume() async {
    _checkDisposed();

    if (!isPaused) {
      throw RecorderException.invalidState('Cannot resume - not paused');
    }

    try {
      print('VoiceRecorder: Resuming recording...');

      // Configure audio session
      final audioConfigured = await _audioSessionService.configureForRecording();
      if (!audioConfigured) {
        throw RecorderException.audioSessionError('Failed to configure audio session');
      }

      await _recorder.resumeRecording();

      _timerService.resume();

      _notifyStateChange(RecordingState.recording);
      print('VoiceRecorder: Recording resumed');
    } catch (e, stackTrace) {
      final error = e is RecorderException 
          ? e 
          : RecorderException.recordingFailed(e);
      _notifyError(error);
      print('VoiceRecorder: Resume recording error - $e\n$stackTrace');
      rethrow;
    }
  }

  /// Stop recording and return the recorded file information.
  /// 
  /// Finalizes the recording, saves the file, and returns a [Recording]
  /// object containing file path, duration, size, and timestamp.
  /// 
  /// The duration excludes any paused time.
  /// 
  /// **Example**:
  /// ```dart
  /// final recording = await recorder.stop();
  /// print('Saved: ${recording.path}');
  /// print('Duration: ${recording.duration.inSeconds}s');
  /// print('Size: ${recording.sizeInBytes} bytes');
  /// ```
  /// 
  /// Throws [RecorderException] if no active recording or file not found.
  Future<Recording> stop() async {
    _checkDisposed();

    if (!isRecording && !isPaused) {
      throw RecorderException.invalidState('No active recording to stop');
    }

    try {
      print('VoiceRecorder: Stopping recording...');

      // Stop timer and get accurate duration (excluding pause time)
      final duration = _timerService.stop();

      final file = await _recorder.stopRecording();

      if (file == null || !file.existsSync()) {
        throw RecorderException.fileNotFound('Recording file not found');
      }

      await _audioSessionService.reset();

      // Get file size
      final sizeInBytes = await file.length();
      final timestamp = DateTime.now();

      _notifyStateChange(RecordingState.stopped);
      print('VoiceRecorder: Recording stopped - ${file.path} (${duration.inSeconds}s, $sizeInBytes bytes)');
      
      return Recording(
        path: file.path,
        file: file,
        duration: duration,
        sizeInBytes: sizeInBytes,
        timestamp: timestamp,
      );
    } catch (e, stackTrace) {
      final error = e is RecorderException 
          ? e 
          : RecorderException.recordingFailed(e);
      _notifyError(error);
      print('VoiceRecorder: Stop recording error - $e\n$stackTrace');
      rethrow;
    }
  }

  /// Delete the current recording file.
  /// 
  /// Stops the recording if active and deletes the file from storage.
  /// Resets the recorder to idle state.
  /// 
  /// Throws [RecorderException] if deletion fails.
  Future<void> delete() async {
    _checkDisposed();

    try {
      print('VoiceRecorder: Deleting recording...');

      // Stop timer if running
      if (isRecording || isPaused) {
        _timerService.stop();
      }

      await _recorder.deleteRecording();
      await _audioSessionService.reset();

      _notifyStateChange(RecordingState.idle);
      print('VoiceRecorder: Recording deleted');
    } catch (e, stackTrace) {
      final error = e is RecorderException 
          ? e 
          : RecorderException.storageError(e);
      _notifyError(error);
      print('VoiceRecorder: Delete recording error - $e\n$stackTrace');
      rethrow;
    }
  }

  /// Restart the recording from the beginning.
  /// 
  /// Stops the current recording (if active), deletes the file,
  /// and starts a new recording with a fresh timestamp.
  /// Maintains the same configuration and audio session settings.
  /// 
  /// Throws [RecorderException] if restart fails.
  Future<void> restart() async {
    _checkDisposed();

    try {
      // Step 1: Stop current recording if active
      if (isRecording || isPaused) {
        _timerService.stop();
        await _recorder.stopRecording();
        print('VoiceRecorder: Stopped current recording');
      }

      // Step 2: Delete the recording file
      await _recorder.deleteRecording();
      print('VoiceRecorder: Deleted old recording file');

      // Step 3: Configure audio session for recording
      final audioConfigured = await _audioSessionService.configureForRecording();
      if (!audioConfigured) {
        throw RecorderException.audioSessionError('Failed to configure audio session for restart');
      }

      // Step 4: Start new recording
      await _recorder.startRecording();

      // Step 5: Start fresh timer
      _timerService.start();

      _notifyStateChange(RecordingState.recording);
      
      print('VoiceRecorder: Recording restarted successfully');
    } catch (e, stackTrace) {
      final error = e is RecorderException 
          ? e 
          : RecorderException.recordingFailed(e);
      _notifyError(error);
      print('VoiceRecorder: Restart recording error - $e\n$stackTrace');
      rethrow;
    }
  }

  /// Reset the recorder to idle state.
  /// 
  /// Stops any active recording and resets the audio session.
  /// Does not delete the recording file.
  Future<void> reset() async {
    _checkDisposed();

    try {
      print('VoiceRecorder: Resetting...');

      if (isRecording || isPaused) {
        _timerService.stop();
        await _recorder.stopRecording();
      }

      await _audioSessionService.reset();

      _notifyStateChange(RecordingState.idle);
      print('VoiceRecorder: Reset complete');
    } catch (e) {
      print('VoiceRecorder: Reset error - $e');
    }
  }

  /// Dispose the recorder and free all resources.
  /// 
  /// Stops any active recording, cancels all subscriptions, and cleans up
  /// internal services. After calling dispose, this recorder instance cannot
  /// be used again.
  /// 
  /// Always call this in your widget's dispose method:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   recorder.dispose();
  ///   super.dispose();
  /// }
  /// ```
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    try {
      print('VoiceRecorder: Disposing...');

      // Cancel subscriptions
      await _amplitudeSubscription?.cancel();
      await _interruptionSubscription?.cancel();
      await _interruptionController.close();

      // Dispose services
      await _recorder.dispose();
      await _timerService.dispose();
      _audioSessionService.reset();

      _isDisposed = true;
      _isInitialized = false;
      print('VoiceRecorder: Disposed');
    } catch (e) {
      print('VoiceRecorder: Dispose error - $e');
    }
  }
}
