import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import '../enums/enums.dart';
import '../models/interruption_data.dart';
import '../services/audio_session_service.dart';
import '../services/recorder_service.dart';
import '../widgets/wave_data_manager.dart';
import '../config/recorder_config.dart';
import '../config/storage_config.dart';
import '../exceptions/recorder_exception.dart';

/// Callback for recording state changes
typedef RecordingStateCallback = void Function(RecordingState state);

/// Callback for errors
typedef ErrorCallback = void Function(RecorderException error);

/// Callback for interruptions
typedef InterruptionCallback = void Function(InterruptionData interruption);

/// Orchestrates recording services and provides a unified API
/// 
/// This is the main coordinator that:
/// - Manages recording services (recorder, waveform)
/// - Coordinates service interactions and lifecycle
/// - Provides a simple API for the UI layer
/// - Handles errors and cleanup
/// - Connects services through streams
/// 
/// Use this class as the single entry point for all recording operations.
/// 
/// Example:
/// ```dart
/// final manager = RecorderManager(
///   config: RecorderConfig.voice(),
///   onStateChanged: (state) => print('State: $state'),
///   onError: (error) => print('Error: $error'),
/// );
/// 
/// await manager.initialize();
/// await manager.startRecording();
/// ```
class RecorderManager {
  /// Core recording service
  final RecorderService _recorder;
  
  /// Audio session and interruption management
  final AudioSessionService _audioSessionService;
  
  /// Waveform data management
  final WaveDataManager _waveManager;

  /// Recording configuration
  final RecorderConfig config;

  /// Storage configuration
  final StorageConfig storageConfig;

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

  /// Whether the manager has been disposed
  bool _isDisposed = false;

  /// Whether the manager is initialized
  bool _isInitialized = false;

  /// Creates a RecorderManager with dependency injection
  /// 
  /// [config] - Recording configuration (quality, format, etc.)
  /// [storageConfig] - Storage configuration (path, cleanup, etc.)
  /// [onStateChanged] - Callback for state changes
  /// [onError] - Callback for errors
  /// [onInterruption] - Callback for interruptions
  /// [recorder] - Optional recorder service for testing
  /// [audioSessionService] - Optional audio session service for testing
  /// [waveManager] - Optional wave manager for testing
  RecorderManager({
    RecorderConfig? config,
    StorageConfig? storageConfig,
    this.onStateChanged,
    this.onError,
    this.onInterruption,
    RecorderService? recorder,
    AudioSessionService? audioSessionService,
    WaveDataManager? waveManager,
  })  : config = config ?? const RecorderConfig(),
        storageConfig = storageConfig ?? const StorageConfig(),
        _recorder = recorder ?? RecorderService(),
        _audioSessionService = audioSessionService ?? AudioSessionService.instance,
        _waveManager = waveManager ?? WaveDataManager.instance;

  /// Stream of interruption events for the UI
  /// 
  /// Subscribe to this to handle interruptions (phone calls, headphone disconnect, etc.)
  Stream<InterruptionData> get interruptionStream => _interruptionController.stream;

  /// Stream of amplitude data from the recorder
  Stream<Amplitude> get amplitudeStream => _recorder.amplitudeStream;
  
  /// Stream of state changes from the recorder
  Stream<RecordState> get onRecordStateChanged => _recorder.onStateChanged;

  /// Current recording state
  RecordingState get recordingState {
    _checkDisposed();
    return _recorder.state;
  }

  /// Whether currently recording
  bool get isRecording {
    _checkDisposed();
    return _recorder.isRecording;
  }

  /// Whether recording is paused
  bool get isPaused {
    _checkDisposed();
    return _recorder.isPaused;
  }

  /// Whether recording is stopped
  bool get isStopped {
    _checkDisposed();
    return _recorder.isStopped;
  }

  /// Whether the manager is initialized
  bool get isInitialized => _isInitialized;

  /// Whether the manager has been disposed
  bool get isDisposed => _isDisposed;

  /// Current recording file name
  String? get currentRecordingFileName {
    _checkDisposed();
    return _recorder.recordingFileName;
  }

  /// Current recording full path
  String? get currentRecordingFullPath {
    _checkDisposed();
    return _recorder.recordingFileFullPath;
  }

  /// Whether waveform data is available
  bool get hasAmplitudeData {
    _checkDisposed();
    return _waveManager.hasData;
  }

  /// Current waveform buffer
  List<double> get waveformBuffer {
    _checkDisposed();
    return _waveManager.currentBuffer;
  }

  /// Waveform data manager (for direct access if needed)
  WaveDataManager get waveManager {
    _checkDisposed();
    return _waveManager;
  }

  /// Checks if the manager has been disposed
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
    print('RecorderManager: Error - $error');
    onError?.call(error);
  }

  /// Initializes all services
  /// 
  /// Must be called before any recording operations.
  /// Initializes services in the correct order and sets up connections.
  /// 
  /// Returns true if initialization was successful.
  /// Throws [RecorderException] if initialization fails.
  Future<bool> initialize() async {
    _checkDisposed();

    if (_isInitialized) {
      print('RecorderManager: Already initialized');
      return true;
    }

    try {
      print('RecorderManager: Initializing...');

      // 1. Initialize recorder with config
      _recorder.updateConfig(config);
      _recorder.updateStorageConfig(storageConfig);
      
      final recorderInit = await _recorder.initialize();
      if (!recorderInit) {
        throw RecorderException.initializationFailed('Recorder initialization failed');
      }

      // 2. Initialize wave manager
      _waveManager.initialize();

      // 3. Initialize audio session
      final audioSessionInit = await _audioSessionService.initialize();
      if (!audioSessionInit) {
        throw RecorderException.initializationFailed('Audio session initialization failed');
      }

      // 4. Setup stream connections
      _setupStreamConnections();

      _isInitialized = true;
      print('RecorderManager: Initialization complete');
      return true;
    } catch (e, stackTrace) {
      final error = e is RecorderException 
          ? e 
          : RecorderException.initializationFailed(e);
      _notifyError(error);
      print('RecorderManager: Initialization error - $e\n$stackTrace');
      return false;
    }
  }

  /// Sets up connections between services via streams
  void _setupStreamConnections() {
    // Connect recorder amplitude to wave manager
    _amplitudeSubscription = _recorder.amplitudeStream.listen(
      (amplitude) {
        final decibels = amplitude.current;
        _waveManager.addAmplitude(decibels);
      },
      onError: (error) {
        print('RecorderManager: Amplitude stream error - $error');
      },
    );

    // Connect audio session interruptions to our interruption stream
    _interruptionSubscription = _audioSessionService.interruptionEvents.listen(
      (interruption) {
        // Only emit interruption if we're actually recording or paused
        if (isRecording || isPaused) {
          _interruptionController.add(interruption);
          onInterruption?.call(interruption);
        }
      },
      onError: (error) {
        print('RecorderManager: Interruption stream error - $error');
      },
    );

    print('RecorderManager: Stream connections established');
  }

  /// Starts a new recording
  /// 
  /// This will:
  /// 1. Configure audio session for recording
  /// 2. Start the recorder
  /// 3. Start waveform data collection
  /// 
  /// Throws [RecorderException] if recording fails to start.
  Future<void> startRecording() async {
    _checkDisposed();

    if (!_isInitialized) {
      throw RecorderException.invalidState('Manager not initialized. Call initialize() first.');
    }

    try {
      print('RecorderManager: Starting recording...');

      // 1. Configure audio session FIRST
      final audioConfigured = await _audioSessionService.configureForRecording();
      if (!audioConfigured) {
        throw RecorderException.audioSessionError('Failed to configure audio session');
      }

      // 2. Start recording
      await _recorder.startRecording();

      // 3. Start wave data collection
      _waveManager.startRecording();

      _notifyStateChange(RecordingState.recording);
      print('RecorderManager: Recording started successfully');
    } catch (e, stackTrace) {
      final error = e is RecorderException 
          ? e 
          : RecorderException.recordingFailed(e);
      _notifyError(error);
      print('RecorderManager: Start recording error - $e\n$stackTrace');
      rethrow;
    }
  }

  /// Pauses the current recording
  /// 
  /// Recording can be resumed later from the same point.
  /// Throws [RecorderException] if pause fails.
  Future<void> pauseRecording() async {
    _checkDisposed();

    if (!isRecording) {
      throw RecorderException.invalidState('Cannot pause - not recording');
    }

    try {
      print('RecorderManager: Pausing recording...');

      await _recorder.pauseRecording();
      _waveManager.pauseRecording();

      _notifyStateChange(RecordingState.paused);
      print('RecorderManager: Recording paused');
    } catch (e, stackTrace) {
      final error = e is RecorderException 
          ? e 
          : RecorderException.recordingFailed(e);
      _notifyError(error);
      print('RecorderManager: Pause recording error - $e\n$stackTrace');
      rethrow;
    }
  }

  /// Resumes a paused recording
  /// 
  /// Continues recording from where it was paused.
  /// Throws [RecorderException] if resume fails.
  Future<void> resumeRecording() async {
    _checkDisposed();

    if (!isPaused) {
      throw RecorderException.invalidState('Cannot resume - not paused');
    }

    try {
      print('RecorderManager: Resuming recording...');

      // Configure audio session
      final audioConfigured = await _audioSessionService.configureForRecording();
      if (!audioConfigured) {
        throw RecorderException.audioSessionError('Failed to configure audio session');
      }

      await _recorder.resumeRecording();
      _waveManager.resumeRecording();

      _notifyStateChange(RecordingState.recording);
      print('RecorderManager: Recording resumed');
    } catch (e, stackTrace) {
      final error = e is RecorderException 
          ? e 
          : RecorderException.recordingFailed(e);
      _notifyError(error);
      print('RecorderManager: Resume recording error - $e\n$stackTrace');
      rethrow;
    }
  }

  /// Stops the recording and saves the file
  /// 
  /// Returns a tuple of (File, DateTime) with the saved file and timestamp.
  /// Throws [RecorderException] if stopping fails or file is not found.
  Future<(File, DateTime)> stopRecording() async {
    _checkDisposed();

    if (!isRecording && !isPaused) {
      throw RecorderException.invalidState('No active recording to stop');
    }

    try {
      print('RecorderManager: Stopping recording...');

      final file = await _recorder.stopRecording();
      _waveManager.stopRecording();

      if (file == null || !file.existsSync()) {
        throw RecorderException.fileNotFound('Recording file not found');
      }

      await _audioSessionService.reset();

      final timestamp = DateTime.now();
      _notifyStateChange(RecordingState.stopped);
      print('RecorderManager: Recording stopped - ${file.path}');
      
      return (file, timestamp);
    } catch (e, stackTrace) {
      final error = e is RecorderException 
          ? e 
          : RecorderException.recordingFailed(e);
      _notifyError(error);
      print('RecorderManager: Stop recording error - $e\n$stackTrace');
      rethrow;
    }
  }

  /// Deletes the current recording
  /// 
  /// Stops the recording if active and deletes the file.
  /// Throws [RecorderException] if deletion fails.
  Future<void> deleteRecording() async {
    _checkDisposed();

    try {
      print('RecorderManager: Deleting recording...');

      await _recorder.deleteRecording();
      _waveManager.clearData();
      await _audioSessionService.reset();

      _notifyStateChange(RecordingState.idle);
      print('RecorderManager: Recording deleted');
    } catch (e, stackTrace) {
      final error = e is RecorderException 
          ? e 
          : RecorderException.storageError(e);
      _notifyError(error);
      print('RecorderManager: Delete recording error - $e\n$stackTrace');
      rethrow;
    }
  }

  /// Restarts the recording
  /// 
  /// Stops the current recording and starts a new one.
  /// Returns the timestamp when the new recording started.
  /// Throws [RecorderException] if restart fails.
  Future<DateTime> restartRecording() async {
    _checkDisposed();

    try {
      print('RecorderManager: Restarting recording...');

      await _recorder.restartRecording();
      _waveManager.clearData();
      _waveManager.startRecording();

      final timestamp = DateTime.now();
      _notifyStateChange(RecordingState.recording);
      print('RecorderManager: Recording restarted');
      
      return timestamp;
    } catch (e, stackTrace) {
      final error = e is RecorderException 
          ? e 
          : RecorderException.recordingFailed(e);
      _notifyError(error);
      print('RecorderManager: Restart recording error - $e\n$stackTrace');
      rethrow;
    }
  }

  /// Checks if audio focus is available
  /// 
  /// Returns true if the app can access the microphone.
  Future<bool> checkAudioFocusAvailable() async {
    _checkDisposed();

    try {
      return await _recorder.initialize();
    } catch (e) {
      print('RecorderManager: Audio focus check error - $e');
      return false;
    }
  }

  /// Resets the manager to initial state
  /// 
  /// Stops any active recording and clears all data.
  Future<void> reset() async {
    _checkDisposed();

    try {
      print('RecorderManager: Resetting...');

      if (isRecording || isPaused) {
        await _recorder.stopRecording();
      }

      _waveManager.clearData();
      await _audioSessionService.reset();

      _notifyStateChange(RecordingState.idle);
      print('RecorderManager: Reset complete');
    } catch (e) {
      print('RecorderManager: Reset error - $e');
    }
  }

  /// Disposes the manager and all services
  /// 
  /// Must be called when the manager is no longer needed.
  /// Cleans up all resources and cancels subscriptions.
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    try {
      print('RecorderManager: Disposing...');

      // Cancel subscriptions
      await _amplitudeSubscription?.cancel();
      await _interruptionSubscription?.cancel();
      await _interruptionController.close();

      // Dispose services
      await _recorder.dispose();
      _audioSessionService.reset();
      _waveManager.clearData();

      _isDisposed = true;
      _isInitialized = false;
      print('RecorderManager: Disposed');
    } catch (e) {
      print('RecorderManager: Dispose error - $e');
    }
  }
}
