/// Voice Recorder Package
/// 
/// A comprehensive audio recording solution with waveform visualization,
/// interruption handling, and flexible configuration.
/// 
/// ## Features
/// - High-quality audio recording with customizable settings
/// - Real-time waveform visualization
/// - Automatic interruption handling (phone calls, headphones, etc.)
/// - Pause/resume support
/// - Multiple quality presets
/// - Configurable storage options
/// - Clean architecture with dependency injection
/// 
/// ## Quick Start
/// 
/// ```dart
/// import 'package:voice_recorder/voice_recorder.dart';
/// 
/// // Create a voice recorder
/// final recorder = VoiceRecorder(
///   onStateChanged: (state) => print('State: $state'),
///   onError: (error) => print('Error: $error'),
/// );
/// 
/// // Initialize (do this once, upfront)
/// await recorder.initialize();
/// 
/// // Start recording (fast, no delay!)
/// await recorder.start();
/// 
/// // Stop and get recording info
/// final recording = await recorder.stop();
/// print('Path: ${recording.path}');
/// print('Duration: ${recording.duration.inSeconds}s');
/// print('Size: ${recording.sizeInBytes} bytes');
/// ```
/// 
/// ## Configuration
/// 
/// Use predefined quality presets:
/// ```dart
/// RecorderConfig.lowQuality()   // 64 kbps, 22.05 kHz
/// RecorderConfig.mediumQuality() // 128 kbps, 44.1 kHz
/// RecorderConfig.highQuality()   // 256 kbps, 48 kHz
/// RecorderConfig.voice()         // Optimized for voice
/// ```
/// 
/// Or create custom configuration:
/// ```dart
/// RecorderConfig(
///   encoder: AudioEncoder.aacLc,
///   bitRate: 128000,
///   sampleRate: 44100,
///   autoGain: true,
///   echoCancel: true,
///   noiseSuppress: true,
/// )
/// ```
library;

// Core manager
export 'src/manager/voice_recorder.dart';

// Configuration
export 'src/config/recorder_config.dart';
export 'src/config/storage_config.dart';

// Models
export 'src/models/interruption_data.dart';
export 'src/models/recording.dart';

// Enums
export 'src/enums/enums.dart';

// Exceptions
export 'src/exceptions/recorder_exception.dart';

// Widgets (optional UI components)
export 'src/widgets/audio_wave_widget.dart';

// Wave configuration
export 'src/config/wave_config.dart';

// Re-export commonly used types from dependencies
export 'package:record/record.dart' show Amplitude, RecordState, AudioEncoder;
