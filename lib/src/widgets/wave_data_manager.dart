import 'dart:async';
import 'dart:math';

/// Manages amplitude data for waveform visualization
/// 
/// This singleton service:
/// - Collects amplitude (decibel) data from the recorder
/// - Maintains a circular buffer of recent amplitudes
/// - Normalizes values for display (0.0 to 1.0 range)
/// - Provides a stream for real-time UI updates
/// 
/// Use [WaveDataManager.instance] to access the singleton.
class WaveDataManager {
  /// Singleton instance
  static final WaveDataManager instance = WaveDataManager._internal();
  
  /// Private constructor for singleton
  WaveDataManager._internal();

  /// Maximum number of amplitude values to keep in buffer
  /// This determines how many bars are shown in the waveform
  /// Reduced for better performance and more responsive visualization
  static const int _maxBufferSize = 50;

  /// Buffer storing normalized amplitude values (0.0 to 1.0)
  final List<double> _amplitudeBuffer = [];

  /// Whether recording is currently active
  bool _isRecording = false;

  /// Whether recording is paused
  bool _isPaused = false;

  /// Controller for broadcasting waveform data updates
  final StreamController<List<double>> _waveformController =
      StreamController<List<double>>.broadcast();

  /// Stream of waveform data for UI updates
  /// 
  /// Emits the current amplitude buffer whenever new data is added.
  /// Subscribe to this stream to update waveform visualization in real-time.
  Stream<List<double>> get waveformStream => _waveformController.stream;

  /// Current amplitude buffer (read-only copy)
  /// 
  /// Returns a copy of the current amplitude values.
  /// Values are normalized between 0.0 (silence) and 1.0 (maximum amplitude).
  List<double> get currentBuffer => List.unmodifiable(_amplitudeBuffer);

  /// Whether there is any amplitude data available
  bool get hasData => _amplitudeBuffer.isNotEmpty;

  /// Whether recording is active
  bool get isRecording => _isRecording;

  /// Initializes the wave data manager
  /// 
  /// Clears any existing data and prepares for new recording.
  void initialize() {
    clearData();
    print('WaveDataManager: Initialized');
  }

  /// Marks recording as started
  /// 
  /// Call this when recording begins to enable data collection.
  void startRecording() {
    _isRecording = true;
    _isPaused = false;
    clearData();
    print('WaveDataManager: Recording started');
  }

  /// Marks recording as paused
  /// 
  /// Call this when recording is paused. No new data will be added.
  void pauseRecording() {
    _isPaused = true;
    print('WaveDataManager: Recording paused');
  }

  /// Marks recording as resumed
  /// 
  /// Call this when recording resumes. Data collection continues.
  void resumeRecording() {
    _isPaused = false;
    print('WaveDataManager: Recording resumed');
  }

  /// Marks recording as stopped
  /// 
  /// Call this when recording ends. Data is preserved for display.
  void stopRecording() {
    _isRecording = false;
    _isPaused = false;
    print('WaveDataManager: Recording stopped');
  }

  /// Adds a new amplitude value to the buffer
  /// 
  /// The value is normalized and added to the circular buffer.
  /// If recording is paused, the value is ignored.
  /// 
  /// [amplitude] - Raw amplitude value in decibels (typically -160 to 0)
  void addAmplitude(double amplitude) {
    // Ignore if not recording or if paused
    if (!_isRecording || _isPaused) {
      return;
    }

    // Normalize the amplitude value
    final normalized = _normalizeAmplitude(amplitude);

    // Add to buffer
    _amplitudeBuffer.add(normalized);

    // Maintain buffer size (circular buffer behavior)
    if (_amplitudeBuffer.length > _maxBufferSize) {
      _amplitudeBuffer.removeAt(0);
    }

    // Notify listeners
    if (!_waveformController.isClosed) {
      _waveformController.add(currentBuffer);
    }
  }

  /// Normalizes amplitude from decibels to 0.0-1.0 range
  /// 
  /// Based on actual Android device data: -2 dB (loud) to -40 dB (quiet)
  /// This method converts that to a 0.0-1.0 range for visualization.
  /// 
  /// [amplitude] - Raw amplitude in decibels
  /// 
  /// Returns normalized value between 0.0 and 1.0
  double _normalizeAmplitude(double amplitude) {
    // Handle edge cases
    if (amplitude.isInfinite || amplitude.isNaN) {
      return 0.0;
    }

    // Actual range from Android device: -2 dB (loud) to -40 dB (quiet/silence)
    const double minDb = -40.0;  // Quiet sounds
    const double maxDb = -2.0;   // Loud sounds

    // Clamp to valid range
    final clampedDb = amplitude.clamp(minDb, maxDb);

    // Simple linear normalization to 0.0-1.0
    final normalized = (clampedDb - minDb) / (maxDb - minDb);

    return normalized.clamp(0.0, 1.0);
  }

  /// Clears all amplitude data from the buffer
  /// 
  /// Use this when starting a new recording or resetting the waveform.
  void clearData() {
    _amplitudeBuffer.clear();
    
    if (!_waveformController.isClosed) {
      _waveformController.add(currentBuffer);
    }
    
    print('WaveDataManager: Data cleared');
  }

  /// Disposes the manager and cleans up resources
  /// 
  /// Closes the stream controller and clears data.
  void dispose() {
    _waveformController.close();
    _amplitudeBuffer.clear();
    _isRecording = false;
    _isPaused = false;
    print('WaveDataManager: Disposed');
  }
}
