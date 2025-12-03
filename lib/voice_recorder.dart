/// Voice Recorder - Simple audio recording for Flutter
/// 
/// Record high-quality audio with just 2 lines of code:
/// ```dart
/// final recorder = VoiceRecorder();
/// await recorder.start();
/// final recording = await recorder.stop();
/// ```
/// 
/// Features:
/// - Easy recording controls (start, pause, resume, stop)
/// - Real-time audio waveform visualization
/// - Customizable audio quality presets
/// - Flexible storage configuration
/// - Automatic interruption handling (calls, headphones, etc.)
/// - Duration tracking with pause support
/// 
/// See [VoiceRecorder] for the main API.
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
