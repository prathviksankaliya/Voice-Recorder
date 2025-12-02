# 🎙️ Voice Recorder

[![pub package](https://img.shields.io/pub/v/voice_recorder.svg)](https://pub.dev/packages/voice_recorder)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-green.svg)](https://pub.dev/packages/voice_recorder)

**Simple, powerful audio recording for Flutter.** Record high-quality audio with just 2 lines of code.

Perfect for voice notes, interviews, podcasts, or any audio recording needs.

---

## ✨ Why Choose This Package?

- 🚀 **Super Simple** - Just 2 lines to start recording
- 🎨 **Wave Visualization** - Built-in real-time waveform widget
- ⚡ **Auto-Initialize** - No manual setup needed
- 🎯 **Beginner Friendly** - Clear examples, easy to understand
- 🏗️ **Production Ready** - Error handling, interruptions, edge cases
- 🎛️ **Fully Customizable** - Simple defaults, powerful when needed
- 📱 **Cross Platform** - Works on Android & iOS

---

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  voice_recorder: ^1.0.0
```

Run:
```bash
flutter pub get
```

---

## ⚡ Quick Start (30 Seconds)

### 1. Import
```dart
import 'package:voice_recorder/voice_recorder.dart';
```

### 2. Record Audio (2 lines!)
```dart
final recorder = VoiceRecorder();
await recorder.start();
// ... recording ...
final recording = await recorder.stop();
```

### 3. Done! 🎉
```dart
print('Saved: ${recording.path}');
print('Duration: ${recording.duration.inSeconds}s');
print('Size: ${(recording.sizeInBytes / 1024).toStringAsFixed(1)} KB');
```

**That's it!** No complex setup, no boilerplate. Just works.

---

## 🎨 With Wave Visualization (4 lines!)

```dart
final recorder = VoiceRecorder();

// In your widget:
AudioWaveWidget.fromRecorder(recorder: recorder)

// Start recording
await recorder.start();
```

**Result**: Beautiful, animated waveform that syncs with your voice!

---

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

---

## 📖 Usage Examples

### Basic Recording

```dart
import 'package:voice_recorder/voice_recorder.dart';

// Create recorder
final recorder = VoiceRecorder();

// Start recording
await recorder.start();

// Stop and get file info
final recording = await recorder.stop();
print('Path: ${recording.path}');
print('Duration: ${recording.duration.inSeconds}s');
```

### With Pause/Resume

```dart
final recorder = VoiceRecorder(
  onStateChanged: (state) => print('State: $state'),
);

await recorder.start();
await recorder.pause();   // Pause
await recorder.resume();  // Resume
final recording = await recorder.stop();
```

### With Callbacks

```dart
final recorder = VoiceRecorder(
  onStateChanged: (state) {
    print('Recording state: $state');
  },
  onError: (error) {
    print('Error: ${error.message}');
  },
  onInterruption: (interruption) {
    print('Interrupted by: ${interruption.type}');
  },
);
```

### Custom Quality

```dart
// Voice optimized (default)
await recorder.start(
  config: RecorderConfig.voice(),
);

// High quality
await recorder.start(
  config: RecorderConfig.highQuality(),
);

// Custom settings
await recorder.start(
  config: RecorderConfig(
    bitRate: 128000,
    sampleRate: 44100,
    noiseSuppress: true,
  ),
);
```

### Custom Storage

```dart
// Save to specific directory
await recorder.start(path: '/my/recordings');

// Save with specific filename
await recorder.start(path: '/my/recordings/interview.m4a');

// Visible in file manager
await recorder.start(
  storageConfig: StorageConfig.visible(),
);
```

---

## 🎨 Wave Visualization

### Option 1: Auto Widget (Easiest)

```dart
AudioWaveWidget.fromRecorder(
  recorder: recorder,
  config: WaveConfig.modern(),
  decoration: BoxDecoration(
    color: Colors.blue.shade50,
    borderRadius: BorderRadius.circular(16),
  ),
)
```

### Option 2: Manual Control (Full Control)

```dart
recorder.amplitudeStream.listen((amplitude) {
  final decibels = amplitude.current;
  // Build your own custom visualization
});
```

### Wave Presets

```dart
WaveConfig.minimal()    // Simple, clean
WaveConfig.standard()   // Default
WaveConfig.modern()     // Stylish, animated
WaveConfig.detailed()   // Dense, detailed
```

### Custom Wave Styling

```dart
AudioWaveWidget.fromRecorder(
  recorder: recorder,
  config: WaveConfig(
    waveColor: Colors.blue,
    inactiveColor: Colors.grey,
    height: 100,
    barWidth: 4,
    barSpacing: 3,
    style: WaveStyle.rounded,
  ),
)
```

---

## 📊 Duration Tracking

```dart
// Get current duration (excludes pause time)
Duration? duration = recorder.currentDuration;

// Listen to duration updates
recorder.durationStream.listen((duration) {
  print('Recording: ${duration.inSeconds}s');
});

// Format duration
String formatDuration(Duration d) {
  final minutes = d.inMinutes.toString().padLeft(2, '0');
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
```

---

## 📞 Interruption Handling

Automatically handles:
- ☎️ Phone calls
- 🎧 Headphone disconnect
- 📱 Bluetooth disconnect
- 🔊 Audio route changes

```dart
final recorder = VoiceRecorder(
  onInterruption: (interruption) {
    if (interruption.type == InterruptionType.phoneCall) {
      // Recording automatically paused
      showNotification('Recording paused due to phone call');
    }
  },
);
```

---

## 📚 API Reference

### VoiceRecorder

Main class for audio recording.

#### Constructor
```dart
VoiceRecorder({
  RecordingStateCallback? onStateChanged,
  ErrorCallback? onError,
  InterruptionCallback? onInterruption,
})
```

#### Methods
| Method | Description |
|--------|-------------|
| `start({path, config, storageConfig})` | Start recording |
| `pause()` | Pause recording |
| `resume()` | Resume recording |
| `stop()` | Stop and get Recording object |
| `delete()` | Delete current recording |
| `dispose()` | Clean up resources |

#### Properties
| Property | Type | Description |
|----------|------|-------------|
| `isRecording` | `bool` | Currently recording |
| `isPaused` | `bool` | Currently paused |
| `recordingState` | `RecordingState` | Current state |
| `currentDuration` | `Duration?` | Current duration (excludes pause) |
| `amplitudeStream` | `Stream<Amplitude>` | Real-time amplitude data |
| `durationStream` | `Stream<Duration>` | Duration updates |

### Recording

Recording metadata returned by `stop()`.

| Property | Type | Description |
|----------|------|-------------|
| `path` | `String` | Full file path |
| `fileName` | `String` | File name only |
| `file` | `File` | File object |
| `duration` | `Duration` | Recording duration |
| `sizeInBytes` | `int` | File size in bytes |
| `timestamp` | `DateTime` | When recorded |

### RecorderConfig

Recording quality configuration.

#### Presets
```dart
RecorderConfig.voice()         // Voice optimized (default)
RecorderConfig.lowQuality()    // 64 kbps, smallest files
RecorderConfig.mediumQuality() // 128 kbps, balanced
RecorderConfig.highQuality()   // 256 kbps, best quality
```

#### Custom
```dart
RecorderConfig(
  encoder: AudioEncoder.aacLc,
  bitRate: 128000,
  sampleRate: 44100,
  numChannels: 1,
  autoGain: true,
  echoCancel: true,
  noiseSuppress: true,
)
```

### WaveConfig

Wave visualization configuration.

#### Presets
```dart
WaveConfig.minimal()    // Simple, clean
WaveConfig.standard()   // Default
WaveConfig.modern()     // Stylish, animated
WaveConfig.detailed()   // Dense, detailed
```

#### Custom
```dart
WaveConfig(
  waveColor: Colors.blue,
  inactiveColor: Colors.grey,
  height: 100,
  barWidth: 4,
  barSpacing: 3,
  barCount: 50,
  style: WaveStyle.rounded,
)
```

---

## 🔐 Permissions

### Request at Runtime

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestPermission() async {
  final status = await Permission.microphone.request();
  return status.isGranted;
}

// Use it
if (await requestPermission()) {
  await recorder.start();
} else {
  print('Microphone permission denied');
}
```

---

## ❓ Troubleshooting

### Permission Denied
**Problem**: Recording fails with permission error

**Solution**:
1. Add platform permissions (see Platform Setup)
2. Request permission at runtime
3. Check device settings

### File Not Found
**Problem**: Recording file not found after stop

**Solution**:
- Use `StorageConfig.visible()` for persistent storage
- Check write permissions
- Verify path is accessible

### No Audio Recorded
**Problem**: File created but no audio

**Solution**:
- Check microphone is not used by another app
- Verify microphone permission granted
- Test with different quality settings

### Wave Not Showing
**Problem**: Wave widget not displaying

**Solution**:
- Ensure `recordingState` is passed correctly
- Check if amplitude stream is active
- Verify widget is in widget tree

---

## 💡 Tips & Best Practices

### 1. Initialize Early
```dart
@override
void initState() {
  super.initState();
  recorder.initialize(); // Do this early
}
```

### 2. Always Dispose
```dart
@override
void dispose() {
  recorder.dispose(); // Clean up
  super.dispose();
}
```

### 3. Handle Errors
```dart
final recorder = VoiceRecorder(
  onError: (error) {
    // Show user-friendly message
    showDialog(...);
  },
);
```

### 4. Use Visible Storage for Important Recordings
```dart
await recorder.start(
  storageConfig: StorageConfig.visible(),
);
```

### 5. Format Duration for Display
```dart
String formatDuration(Duration d) {
  return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
}
```

---

## 🎓 Examples

Check out the `/example` folder for complete examples:

1. **Basic Controls** - Start, pause, resume, stop
2. **Customization** - Quality presets, storage options
3. **Wave Visualization** - Real-time waveform display
4. **Complete App** - Production-ready example

Run examples:
```bash
cd example
flutter run
```

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Credits

Built with these amazing packages:
- [record](https://pub.dev/packages/record) - Core recording functionality
- [audio_session](https://pub.dev/packages/audio_session) - Audio session management
- [path_provider](https://pub.dev/packages/path_provider) - File path utilities

---

## 📞 Support

- 📧 **Issues**: [GitHub Issues](https://github.com/yourusername/voice_recorder/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/yourusername/voice_recorder/discussions)
- 📖 **Documentation**: [API Docs](https://pub.dev/documentation/voice_recorder/latest/)

---

## ⭐ Show Your Support

If this package helped you, please:
- ⭐ Star the repo on GitHub
- 👍 Like on pub.dev
- 📢 Share with others
- 🐛 Report bugs
- 💡 Suggest features

---

<div align="center">

**Made with ❤️ for the Flutter community**

[⬆ Back to Top](#-voice-recorder)

</div>
