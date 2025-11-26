# Voice Recorder

[![pub package](https://img.shields.io/pub/v/voice_recorder.svg)](https://pub.dev/packages/voice_recorder)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Simple, powerful audio recording for Flutter. Record high-quality audio with just a few lines of code.

## ✨ Features

- 🎙️ **Simple API** - Start recording in 3 lines of code
- 📊 **Waveform Visualization** - Real-time audio amplitude data
- ⏸️ **Pause/Resume** - Full recording control
- ⏱️ **Accurate Duration** - Excludes pause time automatically
- 📞 **Interruption Handling** - Handles phone calls, headphones, etc.
- ⚙️ **Flexible Configuration** - Simple defaults, advanced when needed
- 💾 **Easy Storage** - Simple path or full control
- 🏗️ **Production Ready** - Comprehensive error handling

## 📦 Installation

```yaml
dependencies:
  voice_recorder: ^0.1.0
```

```bash
flutter pub get
```

## 🚀 Quick Start

```dart
import 'package:voice_recorder/voice_recorder.dart';

// Create recorder
final recorder = VoiceRecorder();

// Initialize once (upfront, no delay later)
await recorder.initialize();

// Start recording
await recorder.start();

// Stop and get info
final recording = await recorder.stop();
print('Duration: ${recording.duration.inSeconds}s');
print('Size: ${recording.sizeInBytes} bytes');
print('Path: ${recording.path}');
```

That's it! 🎉

## 🔧 Platform Setup

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="28" />
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record audio</string>
```

## 📖 Usage

### Basic Recording

```dart
// Create recorder
final recorder = VoiceRecorder(
  onStateChanged: (state) => print('State: $state'),
  onError: (error) => print('Error: $error'),
);

// Initialize
await recorder.initialize();

// Start
await recorder.start();

// Pause
await recorder.pause();

// Resume
await recorder.resume();

// Stop
final recording = await recorder.stop();

// Clean up
await recorder.dispose();
```

### Custom Path

```dart
// Save to specific directory
await recorder.start(path: '/my/recordings');

// Save with specific filename
await recorder.start(path: '/my/recordings/interview.m4a');
```

### Quality Settings

```dart
// High quality
await recorder.start(
  config: RecorderConfig.highQuality(),
);

// Voice optimized (default)
await recorder.start(
  config: RecorderConfig.voice(),
);

// Custom settings
await recorder.start(
  config: RecorderConfig(
    encoder: AudioEncoder.aacLc,
    bitRate: 128000,
    sampleRate: 44100,
  ),
);
```

### Advanced Storage

```dart
// Use app documents directory
await recorder.start(
  storageConfig: StorageConfig.visible(),
);

// Custom directory
await recorder.start(
  storageConfig: StorageConfig.withDirectory('/custom/path'),
);

// Full control
await recorder.start(
  config: RecorderConfig.highQuality(),
  storageConfig: StorageConfig.visible(),
);
```

## 📊 Waveform Visualization

```dart
// Listen to amplitude updates
recorder.amplitudeStream.listen((amplitude) {
  print('Amplitude: ${amplitude.current} dB');
});

// Get waveform buffer
List<double> waveform = recorder.waveformBuffer;

// Use in CustomPainter
CustomPaint(
  painter: WaveformPainter(recorder.waveformBuffer),
)
```

## ⏱️ Duration Tracking

```dart
// Get current duration while recording
Duration? duration = recorder.currentDuration;

// Listen to duration updates
recorder.durationStream.listen((duration) {
  print('Recording: ${duration.inSeconds}s');
});

// Duration in Recording object (excludes pause time)
final recording = await recorder.stop();
print('Total: ${recording.duration.inSeconds}s');
```

## 📞 Interruption Handling

```dart
final recorder = VoiceRecorder(
  onInterruption: (interruption) {
    print('Interrupted: ${interruption.type}');
  },
);

// Or listen to stream
recorder.interruptionStream.listen((interruption) {
  if (interruption.type == InterruptionType.phoneCall) {
    // Handle phone call
  }
});
```

## 🎯 Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:voice_recorder/voice_recorder.dart';

class RecordingScreen extends StatefulWidget {
  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late VoiceRecorder recorder;
  RecordingState state = RecordingState.idle;

  @override
  void initState() {
    super.initState();
    recorder = VoiceRecorder(
      onStateChanged: (s) => setState(() => state = s),
      onError: (e) => print('Error: $e'),
    );
    recorder.initialize();
  }

  @override
  void dispose() {
    recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Voice Recorder')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('State: ${state.name}'),
            SizedBox(height: 20),
            if (state == RecordingState.idle)
              ElevatedButton(
                onPressed: () => recorder.start(),
                child: Text('Start'),
              ),
            if (state == RecordingState.recording)
              ElevatedButton(
                onPressed: () => recorder.pause(),
                child: Text('Pause'),
              ),
            if (state == RecordingState.paused)
              ElevatedButton(
                onPressed: () => recorder.resume(),
                child: Text('Resume'),
              ),
            if (state == RecordingState.recording || 
                state == RecordingState.paused)
              ElevatedButton(
                onPressed: () async {
                  final recording = await recorder.stop();
                  print('Saved: ${recording.path}');
                },
                child: Text('Stop'),
              ),
          ],
        ),
      ),
    );
  }
}
```

## 📚 API Reference

### VoiceRecorder

Main class for audio recording.

**Constructor:**
```dart
VoiceRecorder({
  RecordingStateCallback? onStateChanged,
  ErrorCallback? onError,
  InterruptionCallback? onInterruption,
})
```

**Methods:**
- `initialize()` - Initialize recorder (call once)
- `start({path, config, storageConfig})` - Start recording
- `pause()` - Pause recording
- `resume()` - Resume recording
- `stop()` - Stop and get Recording object
- `delete()` - Delete current recording
- `restart()` - Restart recording
- `dispose()` - Clean up resources

**Properties:**
- `isRecording` - Currently recording
- `isPaused` - Currently paused
- `currentDuration` - Current duration (excludes pause)
- `currentRecordingFullPath` - Current file path
- `waveformBuffer` - Waveform data
- `amplitudeStream` - Amplitude updates
- `durationStream` - Duration updates

### Recording

Recording metadata returned by `stop()`.

**Properties:**
- `path` - Full file path
- `file` - File object
- `duration` - Recording duration (excludes pause time)
- `sizeInBytes` - File size in bytes
- `timestamp` - When recording stopped
- `fileName` - File name only

### RecorderConfig

Recording quality configuration.

**Presets:**
- `RecorderConfig.voice()` - Voice optimized (default)
- `RecorderConfig.highQuality()` - High quality
- `RecorderConfig.mediumQuality()` - Medium quality
- `RecorderConfig.lowQuality()` - Low quality

**Custom:**
```dart
RecorderConfig(
  encoder: AudioEncoder.aacLc,
  bitRate: 128000,
  sampleRate: 44100,
  numChannels: 1,
)
```

### StorageConfig

Storage location configuration.

**Options:**
- `StorageConfig()` - Default (temp directory)
- `StorageConfig.visible()` - App documents
- `StorageConfig.withDirectory(path)` - Custom directory
- `StorageConfig.withPath(path)` - Specific file path

## 🔐 Permissions

Request microphone permission before recording:

```dart
import 'package:permission_handler/permission_handler.dart';

final status = await Permission.microphone.request();
if (status.isGranted) {
  await recorder.start();
}
```

## ❓ Troubleshooting

**Permission denied?**
- Add platform permissions (see Platform Setup)
- Request permission at runtime

**Recording not starting?**
- Call `initialize()` first
- Check microphone permission

**File not found?**
- Check storage configuration
- Ensure write permissions

## 🤝 Contributing

Contributions welcome! Please open an issue or submit a PR.

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

## 🙏 Credits

Built with:
- [record](https://pub.dev/packages/record)
- [audio_session](https://pub.dev/packages/audio_session)
- [permission_handler](https://pub.dev/packages/permission_handler)
- [path_provider](https://pub.dev/packages/path_provider)

---

Made with ❤️ for the Flutter community
