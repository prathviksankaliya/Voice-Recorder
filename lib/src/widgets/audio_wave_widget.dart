import 'dart:async';
import 'package:flutter/material.dart';
import '../config/wave_config.dart';
import '../enums/enums.dart';
import 'wave_painter.dart';

/// Audio wave visualization widget
/// 
/// Displays real-time audio waveform based on amplitude stream.
/// Automatically syncs with recording state for visual feedback.
/// 
/// Example:
/// ```dart
/// AudioWaveWidget(
///   amplitudeStream: recorder.amplitudeStream.map((amp) => amp.current),
///   recordingState: recordingState,
///   config: WaveConfig.modern(),
/// )
/// ```
class AudioWaveWidget extends StatefulWidget {
  /// Stream of amplitude values in decibels (typically -160 to 0)
  /// 
  /// Usually obtained from VoiceRecorder:
  /// ```dart
  /// recorder.amplitudeStream.map((amp) => amp.current)
  /// ```
  final Stream<double> amplitudeStream;
  
  /// Current recording state to determine visual behavior
  /// 
  /// - [RecordingState.recording]: Active animated waves
  /// - [RecordingState.paused]: Frozen gray waves
  /// - [RecordingState.stopped]: Gray bars or flat line
  /// - [RecordingState.idle]: Flat line
  final RecordingState recordingState;
  
  /// Wave configuration for customization
  /// 
  /// If null, uses [WaveConfig.standard()]
  final WaveConfig? config;
  
  /// Container decoration (background, border, shadow, etc.)
  /// 
  /// Example:
  /// ```dart
  /// BoxDecoration(
  ///   color: Colors.white,
  ///   borderRadius: BorderRadius.circular(12),
  ///   boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
  /// )
  /// ```
  final BoxDecoration? decoration;
  
  /// Internal padding around the wave
  final EdgeInsets? padding;
  
  /// External margin around the container
  final EdgeInsets? margin;
  
  const AudioWaveWidget({
    super.key,
    required this.amplitudeStream,
    required this.recordingState,
    this.config,
    this.decoration,
    this.padding,
    this.margin,
  });

  /// Simplified constructor that accepts VoiceRecorder directly
  /// 
  /// This is a convenience constructor for beginners.
  /// 
  /// Example:
  /// ```dart
  /// AudioWaveWidget.fromRecorder(
  ///   recorder: recorder,
  ///   config: WaveConfig.modern(),
  /// )
  /// ```
  factory AudioWaveWidget.fromRecorder({
    Key? key,
    required dynamic recorder, // VoiceRecorder type (dynamic to avoid circular dependency)
    WaveConfig? config,
    BoxDecoration? decoration,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return AudioWaveWidget(
      key: key,
      amplitudeStream: (recorder as dynamic).amplitudeStream.map((amp) => amp.current),
      recordingState: (recorder as dynamic).recordingState,
      config: config,
      decoration: decoration,
      padding: padding,
      margin: margin,
    );
  }
  
  @override
  State<AudioWaveWidget> createState() => _AudioWaveWidgetState();
}

class _AudioWaveWidgetState extends State<AudioWaveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ValueNotifier<List<double>> _amplitudeBuffer = ValueNotifier([]);
  StreamSubscription<double>? _amplitudeSubscription;
  
  late WaveConfig _config;
  
  @override
  void initState() {
    super.initState();
    _config = widget.config ?? WaveConfig.standard();
    _setupAnimation();
    _subscribeToAmplitudeStream();
  }
  
  @override
  void didUpdateWidget(AudioWaveWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update config if changed
    if (widget.config != oldWidget.config) {
      setState(() {
        _config = widget.config ?? WaveConfig.standard();
      });
    }
    
    // Resubscribe if stream changed
    if (widget.amplitudeStream != oldWidget.amplitudeStream) {
      _amplitudeSubscription?.cancel();
      _subscribeToAmplitudeStream();
    }
    
    // Handle state changes
    if (widget.recordingState != oldWidget.recordingState) {
      _handleStateChange(oldWidget.recordingState, widget.recordingState);
    }
  }
  
  void _setupAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: _config.animationDuration,
    );
    
    if (_config.enableAnimation) {
      _animationController.repeat(reverse: true);
    }
  }
  
  void _subscribeToAmplitudeStream() {
    _amplitudeSubscription = widget.amplitudeStream.listen(
      (amplitude) {
        if (widget.recordingState == RecordingState.recording) {
          _addAmplitude(amplitude);
        }
      },
      onError: (error) {
        debugPrint('AudioWaveWidget: Amplitude stream error - $error');
      },
    );
  }
  
  void _addAmplitude(double amplitude) {
    if (!mounted) return;
    
    final normalized = _normalizeAmplitude(amplitude);
    final currentBuffer = List<double>.from(_amplitudeBuffer.value);
    currentBuffer.add(normalized);
    
    // Maintain buffer size (circular buffer)
    if (currentBuffer.length > _config.barCount) {
      currentBuffer.removeAt(0);
    }
    
    // Update ValueNotifier - only rebuilds CustomPaint, not entire widget
    _amplitudeBuffer.value = currentBuffer;
  }
  
  /// Normalizes amplitude from decibels to 0.0-1.0 range
  /// 
  /// Based on typical device data: -2 dB (loud) to -40 dB (quiet)
  double _normalizeAmplitude(double amplitude) {
    // Handle edge cases
    if (amplitude.isInfinite || amplitude.isNaN) {
      return 0.0;
    }
    
    // Typical range: -40 dB (quiet) to -2 dB (loud)
    const double minDb = -40.0;
    const double maxDb = -2.0;
    
    // Clamp to valid range
    final clampedDb = amplitude.clamp(minDb, maxDb);
    
    // Linear normalization to 0.0-1.0
    final normalized = (clampedDb - minDb) / (maxDb - minDb);
    
    return normalized.clamp(0.0, 1.0);
  }
  
  void _handleStateChange(RecordingState oldState, RecordingState newState) {
    if (newState == RecordingState.stopped || newState == RecordingState.idle) {
      if (!_config.showInactiveWhenStopped) {
        // Clear buffer to show flat line
        _amplitudeBuffer.value = [];
      }
      // Keep buffer to show gray bars if showInactiveWhenStopped is true
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: widget.decoration,
      padding: widget.padding,
      margin: widget.margin,
      child: SizedBox(
        width: _config.width,
        height: _config.height,
        child: CustomPaint(
          size: Size(
            _config.width ?? double.infinity,
            _config.height,
          ),
          painter: WavePainter(
            amplitudes: _amplitudeBuffer,
            config: _config,
            isRecording: widget.recordingState == RecordingState.recording,
            isPaused: widget.recordingState == RecordingState.paused,
            animation: _animationController,
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _amplitudeSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }
}
