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

/// Called when recording state changes
typedef RecordingStateCallback = void Function(RecordingState state);

/// Called when an error occurs
typedef ErrorCallback = void Function(RecorderException error);

/// Called when recording is interrupted
typedef InterruptionCallback = void Function(InterruptionData interruption);

/// Simple voice recorder for Flutter.
/// 
/// **Basic Usage**:
/// ```dart
/// final recorder = VoiceRecorder();
/// await recorder.start();
/// final recording = await recorder.stop();
/// ```
/// 
/// **With Callbacks**:
/// ```dart
/// final recorder = VoiceRecorder(
///   onStateChanged: (state) => print(state),
///   onError: (error) => print(error),
/// );
/// ```
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

  /// Creates a voice recorder
  VoiceRecorder({
    this.onStateChanged,
    this.onError,
    this.onInterruption,
  });

  /// Interruption events (phone calls, headphones, etc.)
  Stream<InterruptionData> get interruptionStream => _interruptionController.stream;

  /// Real-time amplitude data for waveform visualization
  Stream<Amplitude> get amplitudeStream => _recorder.amplitudeStream;
  
  /// Recording state changes
  Stream<RecordState> get onRecordStateChanged => _recorder.onStateChanged;

  /// Duration updates (excludes pause time)
  Stream<Duration> get durationStream => _timerService.durationStream;

  /// Current state
  RecordingState get recordingState {
    _checkDisposed();
    return _recorder.state;
  }

  /// True if currently recording
  bool get isRecording {
    _checkDisposed();
    return _recorder.isRecording;
  }

  /// True if paused
  bool get isPaused {
    _checkDisposed();
    return _recorder.isPaused;
  }

  /// True if stopped
  bool get isStopped {
    _checkDisposed();
    return _recorder.isStopped;
  }

  /// True if initialized
  bool get isInitialized => _isInitialized;

  /// True if disposed
  bool get isDisposed => _isDisposed;

  /// Current file name
  String? get currentRecordingFileName {
    _checkDisposed();
    return _recorder.recordingFileName;
  }

  /// Current file path
  String? get currentRecordingFullPath {
    _checkDisposed();
    return _recorder.recordingFileFullPath;
  }

  /// Current duration (excludes pause time). Null if not recording.
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

  /// Initialize the recorder (optional - auto-initializes on first start).
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

  /// Start recording.
  /// 
  /// ```dart
  /// await recorder.start();
  /// await recorder.start(config: RecorderConfig.highQuality());
  /// await recorder.start(path: '/my/recordings');
  /// ```
  Future<void> start({
    String? path,
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

      StorageConfig finalStorageConfig;
      if (path != null) {
        if (path.endsWith('.m4a') || path.endsWith('.mp3') || path.endsWith('.wav') || path.endsWith('.aac')) {
          finalStorageConfig = StorageConfig.withPath(path);
        } else {
          finalStorageConfig = StorageConfig.withDirectory(path);
        }
      } else if (storageConfig != null) {
        finalStorageConfig = storageConfig;
      } else {
        finalStorageConfig = const StorageConfig();
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

  /// Pause recording.
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

  /// Resume recording.
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

  /// Stop recording and get file info.
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

  /// Delete current recording.
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

  /// Restart recording.
  Future<void> restart() async {
    _checkDisposed();

    try {
      print('VoiceRecorder: Restarting recording...');

      // Stop timer
      _timerService.stop();

      await _recorder.restartRecording();

      // Start new timer
      _timerService.start();

      _notifyStateChange(RecordingState.recording);
      print('VoiceRecorder: Recording restarted');
    } catch (e, stackTrace) {
      final error = e is RecorderException 
          ? e 
          : RecorderException.recordingFailed(e);
      _notifyError(error);
      print('VoiceRecorder: Restart recording error - $e\n$stackTrace');
      rethrow;
    }
  }

  /// Reset to idle state.
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

  /// Dispose resources.
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
