import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import '../../core/enums/enums.dart';
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
  
  /// Current recording state
  RecordingState _state = RecordingState.idle;
  
  /// Name of the current recording file (e.g., 'recording_123456.m4a')
  String? _recordingFileName;
  
  /// Full path to the current recording file
  String? _recordingFileFullPath;
  
  /// Stream subscription for amplitude data
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  
  /// Controller for broadcasting amplitude data to listeners
  final StreamController<Amplitude> _amplitudeController = 
      StreamController<Amplitude>.broadcast();

  /// Stream of amplitude data for waveform visualization
  /// 
  /// Emits amplitude values while recording is active.
  /// Subscribe to this stream to get real-time audio levels.
  Stream<Amplitude> get amplitudeStream => _amplitudeController.stream;

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

  /// Initializes the recorder
  /// 
  /// Must be called before any recording operations.
  /// Checks if recording permission is granted.
  /// 
  /// Returns true if initialization was successful
  Future<bool> initialize() async {
    try {
      // Check if we have recording permission
      final hasPermission = await _recorder.hasPermission();
      
      if (!hasPermission) {
        print('RecorderService: Microphone permission not granted');
        return false;
      }
      
      print('RecorderService: Initialized successfully');
      return true;
    } catch (e) {
      print('RecorderService: Initialization error - $e');
      return false;
    }
  }

  /// Starts a new recording
  /// 
  /// Creates a new file with timestamp-based name and begins recording.
  /// If a recording is already in progress, it will be stopped first.
  /// 
  /// Throws an exception if recording fails to start.
  Future<void> startRecording() async {
    try {
      // Stop any existing recording
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _recordingFileName = 'recording_$timestamp.m4a';
      
      // Get file path from storage handler
      final fileName = _recordingFileName;
      if (fileName == null) {
        throw Exception('Failed to generate recording filename');
      }
      
      _recordingFileFullPath = await _storageHandler.getHiddenRecordingPath(fileName);

      // Configure recording settings
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,  // AAC-LC codec for good quality/size ratio
        bitRate: 128000,              // 128 kbps
        sampleRate: 44100,            // 44.1 kHz (CD quality)
      );

      // Start recording
      final filePath = _recordingFileFullPath;
      if (filePath == null) {
        throw Exception('Failed to get recording file path');
      }
      
      await _recorder.start(config, path: filePath);

      // Update state
      _state = RecordingState.recording;

      // Start listening to amplitude for waveform
      _startAmplitudeStream();

      print('RecorderService: Recording started - $_recordingFileName');
    } catch (e) {
      print('RecorderService: Start recording error - $e');
      rethrow;
    }
  }

  /// Pauses the current recording
  /// 
  /// Recording can be resumed later from the same point.
  /// Amplitude stream will be paused as well.
  Future<void> pauseRecording() async {
    try {
      if (!isRecording) {
        print('RecorderService: Cannot pause - not recording');
        return;
      }

      await _recorder.pause();
      _state = RecordingState.paused;
      
      print('RecorderService: Recording paused');
    } catch (e) {
      print('RecorderService: Pause recording error - $e');
      rethrow;
    }
  }

  /// Resumes a paused recording
  /// 
  /// Continues recording from where it was paused.
  /// Amplitude stream will resume as well.
  Future<void> resumeRecording() async {
    try {
      if (!isPaused) {
        print('RecorderService: Cannot resume - not paused');
        return;
      }

      await _recorder.resume();
      _state = RecordingState.recording;
      
      print('RecorderService: Recording resumed');
    } catch (e) {
      print('RecorderService: Resume recording error - $e');
      rethrow;
    }
  }

  /// Stops the current recording and saves the file
  /// 
  /// Returns the File object of the saved recording, or null if failed.
  /// After stopping, the recording cannot be resumed.
  Future<File?> stopRecording() async {
    try {
      if (_state == RecordingState.idle || _state == RecordingState.stopped) {
        print('RecorderService: No active recording to stop');
        return null;
      }

      // Stop recording
      final path = await _recorder.stop();
      
      // Stop amplitude stream
      await _stopAmplitudeStream();
      
      // Update state
      _state = RecordingState.stopped;

      if (path == null) {
        print('RecorderService: Recording stopped but no file path returned');
        return null;
      }

      // Get the file
      final file = File(path);
      
      if (!await file.exists()) {
        print('RecorderService: Recording file does not exist');
        return null;
      }

      print('RecorderService: Recording stopped - ${file.path}');
      return file;
    } catch (e) {
      print('RecorderService: Stop recording error - $e');
      await _stopAmplitudeStream();
      rethrow;
    }
  }

  /// Restarts the recording
  /// 
  /// Stops the current recording (if any) and starts a new one.
  /// The previous recording file will be deleted.
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
    } catch (e) {
      print('RecorderService: Restart recording error - $e');
      rethrow;
    }
  }

  /// Deletes the current recording file
  /// 
  /// Stops the recording if active and deletes the file from storage.
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
        
        if (deleted) {
          print('RecorderService: Recording deleted');
        }
      }

      // Reset state
      _state = RecordingState.idle;
      _recordingFileName = null;
      _recordingFileFullPath = null;
    } catch (e) {
      print('RecorderService: Delete recording error - $e');
      rethrow;
    }
  }

  /// Starts streaming amplitude data for waveform visualization
  void _startAmplitudeStream() {
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amplitude) {
      // Forward amplitude to our broadcast stream
      if (!_amplitudeController.isClosed) {
        _amplitudeController.add(amplitude);
      }
    });
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
      await _amplitudeController.close();

      // Dispose recorder
      await _recorder.dispose();
      
      print('RecorderService: Disposed');
    } catch (e) {
      print('RecorderService: Dispose error - $e');
    }
  }
}
