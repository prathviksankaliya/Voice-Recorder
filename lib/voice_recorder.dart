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
/// // Create a recorder manager
/// final recorder = RecorderManager(
///   config: RecorderConfig.voice(),
///   onStateChanged: (state) => print('State: $state'),
///   onError: (error) => print('Error: $error'),
/// );
/// 
/// // Initialize
/// await recorder.initialize();
/// 
/// // Start recording
/// await recorder.startRecording();
/// 
/// // Stop and get file
/// final (file, timestamp) = await recorder.stopRecording();
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
library voice_recorder;

// Core manager
export 'src/manager/recorder_manager.dart';

// Configuration
export 'src/config/recorder_config.dart';
export 'src/config/storage_config.dart';

// Models
export 'src/models/interruption_data.dart';

// Enums
export 'src/enums/enums.dart';

// Exceptions
export 'src/exceptions/recorder_exception.dart';

// Widgets (optional UI components)
export 'src/widgets/wave_data_manager.dart';

// Re-export commonly used types from dependencies
export 'package:record/record.dart' show Amplitude, RecordState, AudioEncoder;
