import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:record/record.dart';
import '../enums/enums.dart';
import '../config/recorder_config.dart';
import '../config/storage_config.dart';
import '../exceptions/recorder_exception.dart';
import 'recorder_storage_handler.dart';

/// Low-level audio recording service
///
/// This service wraps the 'record' package and provides a clean API for:
/// - Starting, pausing, resuming, and stopping recordings
/// - Managing recording state
/// - Providing amplitude data for waveform visualization
/// - Handling file paths and storage
///
/// This is a simple wrapper that focuses only on recording operations.
class RecorderService {
  /// The underlying audio recorder instance
  final AudioRecorder _recorder = AudioRecorder();

  /// Handles file storage operations
  final RecorderStorageHandler _storageHandler = RecorderStorageHandler();

  /// Recording configuration
  RecorderConfig _config = const RecorderConfig();

  /// Storage configuration
  StorageConfig _storageConfig = const StorageConfig();

  /// Current recording state
  RecordingState _state = RecordingState.idle;

  /// Name of the current recording file (e.g., 'recording_123456.m4a')
  String? _recordingFileName;

  /// Full path to the current recording file
  String? _recordingFileFullPath;

  /// Stream subscription for amplitude data
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  /// Controller for broadcasting amplitude data to listeners
  final StreamController<Amplitude> _amplitudeController = StreamController<Amplitude>.broadcast();

  /// Stream of amplitude data for waveform visualization
  ///
  /// Emits amplitude values while recording is active.
  /// Subscribe to this stream to get real-time audio levels.
  Stream<Amplitude> get amplitudeStream => _amplitudeController.stream;

  Stream<RecordState> get onStateChanged => _recorder.onStateChanged();

  /// Current recording state
  RecordingState get state => _state;

  /// Whether the recorder is currently recording
  bool get isRecording => _state == RecordingState.recording;

  /// Whether the recording is paused
  bool get isPaused => _state == RecordingState.paused;

  /// Whether the recording is stopped
  bool get isStopped => _state == RecordingState.stopped;

  /// Name of the current recording file
  String? get recordingFileName => _recordingFileName;

  /// Full path to the current recording file
  String? get recordingFileFullPath => _recordingFileFullPath;

  /// Updates the recording configuration
  void updateConfig(RecorderConfig config) {
    _config = config;
  }

  /// Updates the storage configuration
  void updateStorageConfig(StorageConfig config) {
    _storageConfig = config;
    _storageHandler.setConfig(config);
  }

  /// Initializes the recorder
  ///
  /// Must be called before any recording operations.
  /// Checks if recording permission is granted.
  ///
  /// Returns true if initialization was successful
  /// Throws [RecorderException] if initialization fails
  Future<bool> initialize() async {
    try {
      // Check if we have recording permission
      final hasPermission = await _recorder.hasPermission();

      if (!hasPermission) {
        print('RecorderService: Microphone permission not granted');
        throw RecorderException.permissionDenied();
      }

      print('RecorderService: Initialized successfully');
      return true;
    } catch (e, stackTrace) {
      print('RecorderService: Initialization error - $e');
      if (e is RecorderException) {
        rethrow;
      }
      throw RecorderException.initializationFailed(e);
    }
  }

  /// Starts a new recording
  ///
  /// Creates a new file with timestamp-based name and begins recording.
  /// If a recording is already in progress, it will be stopped first.
  ///
  /// Throws [RecorderException] if recording fails to start.
  Future<void> startRecording() async {
    try {
      // Stop any existing recording
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingFileName = '${_config.filePrefix}_$timestamp.${_config.fileExtension}';

      // Get file path from storage handler
      final fileName = _recordingFileName;
      if (fileName == null) {
        throw RecorderException.recordingFailed('Failed to generate recording filename');
      }

      // Get recording path using storage handler
      _recordingFileFullPath = await _storageHandler.getRecordingPath(fileName: fileName);

      // Use configuration
      final recordConfig = _config.toRecordConfig();

      // Start recording
      final filePath = _recordingFileFullPath;
      if (filePath == null) {
        throw RecorderException.storageError('Failed to get recording file path');
      }

      await _recorder.start(recordConfig, path: filePath);

      // Update state
      _state = RecordingState.recording;

      // Start listening to amplitude for waveform
      _startAmplitudeStream();

      print('RecorderService: Recording started - $_recordingFileName');
    } catch (e, stackTrace) {
      print('RecorderService: Start recording error - $e');
      if (e is RecorderException) {
        rethrow;
      }
      throw RecorderException.recordingFailed(e);
    }
  }

  /// Pauses the current recording
  ///
  /// Recording can be resumed later from the same point.
  /// Amplitude stream will be paused as well.
  /// 
  /// Throws [RecorderException] if pause fails.
  Future<void> pauseRecording() async {
    try {
      if (!isRecording) {
        throw RecorderException.invalidState('Cannot pause - not recording');
      }

      await _recorder.pause();
      _state = RecordingState.paused;

      print('RecorderService: Recording paused');
    } catch (e, stackTrace) {
      print('RecorderService: Pause recording error - $e');
      if (e is RecorderException) {
        rethrow;
      }
      throw RecorderException.recordingFailed(e);
    }
  }

  /// Resumes a paused recording
  ///
  /// Continues recording from where it was paused.
  /// Amplitude stream will resume as well.
  /// 
  /// Throws [RecorderException] if resume fails.
  Future<void> resumeRecording() async {
    try {
      if (!isPaused) {
        throw RecorderException.invalidState('Cannot resume - not paused');
      }

      await _recorder.resume();
      _state = RecordingState.recording;

      print('RecorderService: Recording resumed');
    } catch (e, stackTrace) {
      print('RecorderService: Resume recording error - $e');
      if (e is RecorderException) {
        rethrow;
      }
      throw RecorderException.recordingFailed(e);
    }
  }

  /// Stops the current recording and saves the file
  ///
  /// Returns the File object of the saved recording.
  /// After stopping, the recording cannot be resumed.
  /// 
  /// Throws [RecorderException] if stop fails or file is not found.
  Future<File?> stopRecording() async {
    try {
      if (_state == RecordingState.idle || _state == RecordingState.stopped) {
        throw RecorderException.invalidState('No active recording to stop');
      }

      // Stop recording
      final path = await _recorder.stop();

      // Stop amplitude stream (do this regardless of path status)
      await _stopAmplitudeStream();

      // Update state (always update state after stopping)
      _state = RecordingState.stopped;

      if (path == null) {
        throw RecorderException.fileNotFound('Recording stopped but no file path returned');
      }

      // Get the file
      final file = File(path);

      if (!await file.exists()) {
        throw RecorderException.fileNotFound(path);
      }

      print('RecorderService: Recording stopped successfully - ${file.path}');
      return file;
    } catch (e, stackTrace) {
      print('RecorderService: Stop recording error - $e');
      // Ensure cleanup happens even on error
      await _stopAmplitudeStream();
      _state = RecordingState.stopped;
      
      if (e is RecorderException) {
        rethrow;
      }
      throw RecorderException.recordingFailed(e);
    }
  }

  /// Restarts the recording
  ///
  /// Stops the current recording (if any) and starts a new one.
  /// The previous recording file will be deleted.
  /// 
  /// Throws [RecorderException] if restart fails.
  Future<void> restartRecording() async {
    try {
      // Delete current recording if exists
      final filePath = _recordingFileFullPath;
      if (filePath != null) {
        await _storageHandler.deleteRecording(filePath);
      }

      // Stop current recording
      if (isRecording || isPaused) {
        await _recorder.stop();
        await _stopAmplitudeStream();
      }

      // Start new recording
      await startRecording();

      print('RecorderService: Recording restarted');
    } catch (e, stackTrace) {
      print('RecorderService: Restart recording error - $e');
      if (e is RecorderException) {
        rethrow;
      }
      throw RecorderException.recordingFailed(e);
    }
  }

  /// Deletes the current recording file
  ///
  /// Stops the recording if active and deletes the file from storage.
  /// 
  /// Throws [RecorderException] if deletion fails.
  Future<void> deleteRecording() async {
    try {
      // Stop recording if active
      if (isRecording || isPaused) {
        await _recorder.stop();
        await _stopAmplitudeStream();
      }

      // Delete file if exists
      final filePath = _recordingFileFullPath;
      if (filePath != null) {
        final deleted = await _storageHandler.deleteRecording(filePath);

        if (!deleted) {
          throw RecorderException.storageError('Failed to delete recording file');
        }
        
        print('RecorderService: Recording deleted');
      }

      // Reset state
      _state = RecordingState.idle;
      _recordingFileName = null;
      _recordingFileFullPath = null;
    } catch (e, stackTrace) {
      print('RecorderService: Delete recording error - $e');
      if (e is RecorderException) {
        rethrow;
      }
      throw RecorderException.storageError(e);
    }
  }

  /// Starts streaming amplitude data for waveform visualization
  void _startAmplitudeStream() {
    _amplitudeSubscription = _recorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen(
      (amplitude) {
        // Forward amplitude to our broadcast stream
        if (!_amplitudeController.isClosed) {
          _amplitudeController.add(amplitude);
        }
      },
      onError: (error) {
        print('RecorderService: Amplitude stream error - $error');
      },
    );

    _recorder.onStateChanged().listen(
      (event) {
        log("log: newStateUpdate ${event.name}");
      },
      onError: (error) {
        print('RecorderService: State change stream error - $error');
      },
    );
  }

  /// Stops the amplitude stream
  Future<void> _stopAmplitudeStream() async {
    await _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
  }

  /// Disposes the recorder and cleans up resources
  ///
  /// Must be called when the recorder is no longer needed.
  /// After disposal, the recorder cannot be used again.
  Future<void> dispose() async {
    try {
      // Stop recording if active
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      // Cancel amplitude subscription
      await _stopAmplitudeStream();
      
      // Close amplitude controller
      if (!_amplitudeController.isClosed) {
        await _amplitudeController.close();
      }

      // Dispose recorder
      await _recorder.dispose();
      
      print('RecorderService: Disposed');
    } catch (e) {
      print('RecorderService: Dispose error - $e');
      // Don't rethrow in dispose - just log the error
    }
  }
}
