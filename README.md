# Flutter Audio Recorder

A comprehensive, independent audio recording module for Flutter with waveform visualization, interruption handling, and flexible configuration. Designed to be easily integrated into any Flutter project.

## ✨ Features

- 🎙️ **High-quality audio recording** with customizable settings
- 📊 **Real-time waveform visualization**
- 📞 **Automatic interruption handling** (phone calls, headphones disconnect, etc.)
- ⏸️ **Pause/resume support**
- 🎚️ **Multiple quality presets** (low, medium, high, voice-optimized)
- 💾 **Configurable storage** options (hidden/visible files, custom paths)
- 🏗️ **Clean architecture** with dependency injection for testing
- 🔧 **Flexible configuration** for Android and iOS
- ⚡ **Callback-based** or **Stream-based** APIs
- 🧪 **Testable** with mock implementations

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  recorder:
    path: ../recorder  # Or your package path
```

### Platform Setup

#### Android

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

#### iOS

Add permissions to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio</string>
```

## 🚀 Quick Start

### Basic Usage

```dart
import 'package:recorder/recorder.dart';

// Create a recorder manager
final recorder = RecorderManager(
  config: RecorderConfig.voice(),
  onStateChanged: (state) => print('State: $state'),
  onError: (error) => print('Error: $error'),
);

// Initialize
await recorder.initialize();

// Start recording
await recorder.startRecording();

// Pause
await recorder.pauseRecording();

// Resume
await recorder.resumeRecording();

// Stop and get file
final (file, timestamp) = await recorder.stopRecording();
print('Recording saved: ${file.path}');

// Clean up
await recorder.dispose();
```

### With Provider (State Management)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recorder/recorder.dart';

class RecordingProvider extends ChangeNotifier {
  final RecorderManager _manager;

  RecordingProvider()
      : _manager = RecorderManager(
          config: RecorderConfig.voice(),
          onStateChanged: (state) => notifyListeners(),
        );

  RecordingState get state => _manager.recordingState;
  bool get isRecording => _manager.isRecording;

  Future<void> initialize() async {
    await _manager.initialize();
    notifyListeners();
  }

  Future<void> startRecording() async {
    await _manager.startRecording();
  }

  Future<void> stopRecording() async {
    await _manager.stopRecording();
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }
}
```

## ⚙️ Configuration

### Quality Presets

```dart
// Low quality (64 kbps, 22.05 kHz) - smallest file size
RecorderConfig.lowQuality()

// Medium quality (128 kbps, 44.1 kHz) - balanced
RecorderConfig.mediumQuality()

// High quality (256 kbps, 48 kHz) - best quality
RecorderConfig.highQuality()

// Voice optimized - best for voice recording
RecorderConfig.voice()
```

### Custom Configuration

```dart
final config = RecorderConfig(
  encoder: AudioEncoder.aacLc,
  bitRate: 128000,
  sampleRate: 44100,
  numChannels: 1,
  autoGain: true,
  echoCancel: true,
  noiseSuppress: true,
  filePrefix: 'my_recording',
  fileExtension: 'm4a',
  androidConfig: AndroidRecorderConfig(
    audioSource: AndroidAudioSource.mic,
    serviceConfig: AndroidServiceConfig(
      title: 'Recording',
      content: 'Recording in progress...',
    ),
  ),
);

final recorder = RecorderManager(config: config);
```

### Storage Configuration

```dart
// Default: hidden files in app directory
final storageConfig = StorageConfig.defaultConfig();

// Visible files in documents
final storageConfig = StorageConfig.visible();

// With automatic cleanup
final storageConfig = StorageConfig.withCleanup(
  maxAge: Duration(days: 30),
  maxRecordings: 100,
);

// Custom directory
final storageConfig = StorageConfig(
  customDirectory: '/path/to/recordings',
  useHiddenFiles: false,
);

final recorder = RecorderManager(
  config: RecorderConfig.voice(),
  storageConfig: storageConfig,
);
```

## 🎨 UI Components

### Waveform Visualization

The package includes a waveform data manager that you can use to build custom visualizations:

```dart
import 'package:recorder/recorder.dart';

class WaveformWidget extends StatelessWidget {
  final RecorderManager recorder;

  const WaveformWidget({required this.recorder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<double>>(
      stream: recorder.waveManager.waveformStream,
      builder: (context, snapshot) {
        final waveform = snapshot.data ?? [];
        return CustomPaint(
          painter: WaveformPainter(waveform),
        );
      },
    );
  }
}
```

## 🔔 Interruption Handling

The recorder automatically handles interruptions like phone calls, headphone disconnects, etc.:

```dart
final recorder = RecorderManager(
  onInterruption: (interruption) {
    print('Interruption: ${interruption.type}');
    if (interruption.shouldPause) {
      // Recording was automatically paused
      showNotification('Recording paused due to ${interruption.type}');
    }
  },
);

// Or listen to the stream
recorder.interruptionStream.listen((interruption) {
  // Handle interruption
});
```

## 🧪 Testing

The package is designed for testability with dependency injection:

```dart
import 'package:recorder/recorder.dart';
import 'package:mockito/mockito.dart';

class MockRecorderService extends Mock implements RecorderService {}

void main() {
  test('recorder starts successfully', () async {
    final mockService = MockRecorderService();
    final recorder = RecorderManager(recorder: mockService);
    
    when(mockService.initialize()).thenAnswer((_) async => true);
    when(mockService.startRecording()).thenAnswer((_) async => null);
    
    await recorder.initialize();
    await recorder.startRecording();
    
    verify(mockService.startRecording()).called(1);
  });
}
```

## 📱 Example App

Check the `example/` directory for a complete working example with:
- Recording controls
- Waveform visualization
- Permission handling
- Error handling
- File management

## 🏗️ Architecture

```
┌─────────────────────────────────────────┐
│           UI Layer (Your App)           │
│  ┌─────────────────────────────────┐    │
│  │   RecordingProvider/Widget      │    │
│  └─────────────────────────────────┘    │
└──────────────────┬──────────────────────┘
                   ▼
┌─────────────────────────────────────────┐
│        RecorderManager (Public API)     │
│          - Callbacks & Streams          │
│          - Configuration                │
│          - Error Handling               │
└──────────────────┬──────────────────────┘
                   │
    ┌──────────────┼──────────────┐
    │              │              │
┌───▼────┐  ┌──────▼─────┐   ┌────▼────┐
│Recorder│  │AudioSession│   │WaveData │
│Service │  │  Service   │   │ Manager │
└────────┘  └────────────┘   └─────────┘
```

## 🔧 API Reference

### RecorderManager

Main class for recording operations.

#### Constructor

```dart
RecorderManager({
  RecorderConfig? config,
  StorageConfig? storageConfig,
  RecordingStateCallback? onStateChanged,
  ErrorCallback? onError,
  InterruptionCallback? onInterruption,
})
```

#### Methods

- `Future<bool> initialize()` - Initialize the recorder
- `Future<void> startRecording()` - Start recording
- `Future<void> pauseRecording()` - Pause recording
- `Future<void> resumeRecording()` - Resume recording
- `Future<(File, DateTime)> stopRecording()` - Stop and save recording
- `Future<void> deleteRecording()` - Delete current recording
- `Future<DateTime> restartRecording()` - Restart recording
- `Future<void> dispose()` - Clean up resources

#### Properties

- `RecordingState recordingState` - Current state
- `bool isRecording` - Whether recording
- `bool isPaused` - Whether paused
- `bool isInitialized` - Whether initialized
- `String? currentRecordingFileName` - Current file name
- `List<double> waveformBuffer` - Waveform data
- `Stream<Amplitude> amplitudeStream` - Amplitude stream
- `Stream<InterruptionData> interruptionStream` - Interruption stream

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Built with [record](https://pub.dev/packages/record) package
- Uses [audio_session](https://pub.dev/packages/audio_session) for interruption handling
- [permission_handler](https://pub.dev/packages/permission_handler) for permissions

## 📞 Support

For issues, questions, or suggestions, please file an issue on GitHub.

---

Made with ❤️ for the Flutter community
