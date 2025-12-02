/// Simple voice recording for Flutter.
/// 
/// **Quick Start** (2 lines):
/// ```dart
/// final recorder = VoiceRecorder();
/// await recorder.start();
/// final recording = await recorder.stop();
/// ```
/// 
/// **With Wave Visualization**:
/// ```dart
/// AudioWaveWidget.fromRecorder(recorder: recorder)
/// ```
/// 
/// **Customize Quality**:
/// ```dart
/// await recorder.start(config: RecorderConfig.highQuality());
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
