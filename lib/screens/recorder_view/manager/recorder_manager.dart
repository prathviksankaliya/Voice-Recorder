import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import '../../../core/enums/enums.dart';
import '../../../core/models/interruption_data.dart';
import '../../../services/recording_services/audio_session_service.dart';
import '../../../services/recording_services/recorder_service.dart';
import '../../../widgets/live_wave_form_widget/wave_data_manager.dart';

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
class RecorderManager {
  /// Core recording service
  final RecorderService _recorder;
  
  /// Audio session and interruption management
  final AudioSessionService _audioSessionService;
  
  /// Waveform data management
  final WaveDataManager _waveManager;

  /// Stream subscriptions
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  StreamSubscription<InterruptionData>? _interruptionSubscription;

  /// Controller for broadcasting interruption events to UI
  final StreamController<InterruptionData> _interruptionController =
      StreamController<InterruptionData>.broadcast();

  /// Creates a RecorderManager with dependency injection
  /// 
  /// Services can be injected for testing, or will use defaults.
  RecorderManager({
    RecorderService? recorder,
    AudioSessionService? audioSessionService,
    WaveDataManager? waveManager,
  })  : _recorder = recorder ?? RecorderService(),
        _audioSessionService = audioSessionService ?? AudioSessionService.instance,
        _waveManager = waveManager ?? WaveDataManager.instance;
  /// Stream of interruption events for the UI
  /// 
  /// Subscribe to this to handle interruptions (phone calls, headphone disconnect, etc.)
  Stream<InterruptionData> get interruptionStream => _interruptionController.stream;

  /// Stream of amplitude data from the recorder
  Stream<Amplitude> get amplitudeStream => _recorder.amplitudeStream;
  
  /// Stream of interruption events from the recorder
  /// 
  /// Emits true when an interruption occurs (phone call, other app takes audio focus)
  /// Emits false when recording resumes after interruption
  Stream<RecordState> get onStateChanged => _recorder.onStateChanged;

  /// Current recording state
  RecordingState get recordingState => _recorder.state;

  /// Whether currently recording
  bool get isRecording => _recorder.isRecording;

  /// Whether recording is paused
  bool get isPaused => _recorder.isPaused;

  /// Whether recording is stopped
  bool get isStopped => _recorder.isStopped;

  /// Current recording file name
  String? get currentRecordingFileName => _recorder.recordingFileName;

  /// Current recording full path
  String? get currentRecordingFullPath => _recorder.recordingFileFullPath;

  /// Whether waveform data is available
  bool get hasAmplitudeData => _waveManager.hasData;

  /// Current waveform buffer
  List<double> get waveformBuffer => _waveManager.currentBuffer;

  /// Waveform data manager (for direct access if needed)
  WaveDataManager get waveManager => _waveManager;

  /// Initializes all services
  /// 
  /// Must be called before any recording operations.
  /// Initializes services in the correct order and sets up connections.
  /// 
  /// Returns true if initialization was successful.
  Future<bool> initialize() async {
    try {
      print('RecorderManager: Initializing...');

      // 1. Initialize recorder
      final recorderInit = await _recorder.initialize();
      if (!recorderInit) {
        print('RecorderManager: Recorder initialization failed');
        return false;
      }

      // 2. Initialize wave manager
      _waveManager.initialize();

      // 3. Initialize audio session
      final audioSessionInit = await _audioSessionService.initialize();
      if (!audioSessionInit) {
        print('RecorderManager: Audio session initialization failed');
        return false;
      }

      // 5. Setup stream connections
      _setupStreamConnections();

      print('RecorderManager: Initialization complete');
      return true;
    } catch (e) {
      print('RecorderManager: Initialization error - $e');
      return false;
    }
  }

  /// Sets up connections between services via streams
  void _setupStreamConnections() {
    // Connect recorder amplitude to wave manager
    _amplitudeSubscription = _recorder.amplitudeStream.listen((amplitude) {
      // Convert current to decibels for wave manager
      // The Amplitude object has current and max properties
      final decibels = amplitude.current;
      _waveManager.addAmplitude(decibels);
    });

    // Connect audio session interruptions to our interruption stream
    // Only forward interruptions when actually recording
    _interruptionSubscription = _audioSessionService.interruptionEvents.listen(
      (interruption) {
        // Only emit interruption if we're actually recording or paused
        if (isRecording || isPaused) {
          _interruptionController.add(interruption);
        }
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
  /// Throws an exception if recording fails to start.
  Future<void> startRecording() async {
    try {
      print('RecorderManager: Starting recording...');

      // 1. Configure audio session FIRST (before starting recorder)
      final audioConfigured = await _audioSessionService.configureForRecording();
      if (!audioConfigured) {
        throw Exception('Failed to configure audio session');
      }

      // 2. Start recording (after audio session is configured)
      await _recorder.startRecording();

      // 3. Start wave data collection
      _waveManager.startRecording();

      print('RecorderManager: Recording started successfully');
    } catch (e) {
      print('RecorderManager: Start recording error - $e');
      rethrow;
    }
  }

  /// Pauses the current recording
  /// 
  /// Recording can be resumed later from the same point.
  Future<void> pauseRecording() async {
    try {
      if (!isRecording) {
        print('RecorderManager: Cannot pause - not recording');
        return;
      }

      print('RecorderManager: Pausing recording...');

      // 1. Pause recorder
      await _recorder.pauseRecording();

      // 2. Pause wave data collection
      _waveManager.pauseRecording();

      print('RecorderManager: Recording paused');
    } catch (e) {
      print('RecorderManager: Pause recording error - $e');
      rethrow;
    }
  }

  /// Resumes a paused recording
  /// 
  /// Continues recording from where it was paused.
  Future<void> resumeRecording() async {
    try {
      if (!isPaused) {
        print('RecorderManager: Cannot resume - not paused');
        return;
      }

      print('RecorderManager: Resuming recording...');

      // 1. Configure audio session
      final audioConfigured = await _audioSessionService.configureForRecording();
      if (!audioConfigured) {
        throw Exception('Failed to configure audio session');
      }

      // 1. Resume recorder
      await _recorder.resumeRecording();

      // 2. Resume wave data collection
      _waveManager.resumeRecording();

      print('RecorderManager: Recording resumed');
    } catch (e) {
      print('RecorderManager: Resume recording error - $e');
      rethrow;
    }
  }

  /// Stops the recording and saves the file
  /// 
  /// Returns a tuple of (File, DateTime) with the saved file and timestamp.
  /// Throws an exception if stopping fails or file is not found.
  Future<(File, DateTime)> stopRecording() async {
    try {
      print('RecorderManager: Stopping recording...');

      // 1. Stop recorder
      final file = await _recorder.stopRecording();
      
      // 2. Stop wave data collection (do this regardless of file status)
      _waveManager.stopRecording();

      // 3. Check file validity after cleanup is done
      if (file == null || !file.existsSync()) {
        throw Exception('Recording file not found');
      }

      // 2. Stop wave data collection
      _waveManager.stopRecording();

      // 4. Reset audio session
      await _audioSessionService.reset();

      final timestamp = DateTime.now();
      print('RecorderManager: Recording stopped - ${file.path}');
      
      return (file, timestamp);
    } catch (e) {
      print('RecorderManager: Stop recording error - $e');
      rethrow;
    }
  }

  /// Deletes the current recording
  /// 
  /// Stops the recording if active and deletes the file.
  Future<void> deleteRecording() async {
    try {
      print('RecorderManager: Deleting recording...');

      // 1. Delete recording
      await _recorder.deleteRecording();

      // 2. Clear wave data
      _waveManager.clearData();

      // 4. Reset audio session
      await _audioSessionService.reset();

      print('RecorderManager: Recording deleted');
    } catch (e) {
      print('RecorderManager: Delete recording error - $e');
      rethrow;
    }
  }

  /// Restarts the recording
  /// 
  /// Stops the current recording and starts a new one.
  /// Returns the timestamp when the new recording started.
  Future<DateTime> restartRecording() async {
    try {
      print('RecorderManager: Restarting recording...');

      // 1. Restart recorder (this handles deletion internally)
      await _recorder.restartRecording();

      // 2. Clear and restart wave data
      _waveManager.clearData();
      _waveManager.startRecording();

      final timestamp = DateTime.now();
      print('RecorderManager: Recording restarted');
      
      return timestamp;
    } catch (e) {
      print('RecorderManager: Restart recording error - $e');
      rethrow;
    }
  }

  /// Checks if audio focus is available
  /// 
  /// Returns true if the app can access the microphone.
  Future<bool> checkAudioFocusAvailable() async {
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
    try {
      print('RecorderManager: Resetting...');

      // Stop recording if active
      if (isRecording || isPaused) {
        await _recorder.stopRecording();
      }

      // Clear wave data
      _waveManager.clearData();

      // Reset audio session
      await _audioSessionService.reset();

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
    try {
      print('RecorderManager: Disposing...');

      // 1. Cancel subscriptions
      await _amplitudeSubscription?.cancel();
      await _interruptionSubscription?.cancel();
      await _interruptionController.close();

      // 2. Dispose services
      await _recorder.dispose();
      _audioSessionService.reset();
      _waveManager.clearData();

      print('RecorderManager: Disposed');
    } catch (e) {
      print('RecorderManager: Dispose error - $e');
    }
  }
}