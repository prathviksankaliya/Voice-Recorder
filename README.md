# Voice Recorder

[![pub package](https://img.shields.io/pub/v/voice_recorder.svg)](https://pub.dev/packages/voice_recorder)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A comprehensive audio recording package for Flutter with real-time waveform visualization, automatic interruption handling, and flexible configuration options.

## Features

- 🎙️ **High-Quality Audio Recording** - Multiple quality presets and custom configuration
- 📊 **Real-Time Waveform Visualization** - Live amplitude data for visual feedback
- ⏸️ **Pause/Resume Support** - Full control over recording lifecycle
- 📞 **Automatic Interruption Handling** - Handles phone calls, headphone disconnections, and more
- ⚙️ **Flexible Configuration** - Quality presets and custom settings
- 💾 **Configurable Storage** - Choose where and how recordings are saved
- 🏗️ **Clean Architecture** - Well-structured, testable, and maintainable code
- 🔒 **Production Ready** - Comprehensive error handling and state management

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  voice_recorder: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Platform Setup

### Android

Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                     android:maxSdkVersion="28" />
    
    <application ...>
        ...
    </application>
</manifest>
```

### iOS

Add the following to `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access to record audio</string>
```

## Quick Start

```dart
import 'package:voice_recorder/voice_recorder.dart';

// Create recorder instance
final recorder = RecorderManager(
  config: RecorderConfig.voice(),
  onStateChanged: (state) {
    print('Recording state: $state');
  },
  onError: (error) {
    print('Error: ${error.message}');
  },
);

// Initialize
await recorder.initialize();

// Start recording
await recorder.startRecording();

// Pause recording
await recorder.pauseRecording();

// Resume recording
await recorder.resumeRecording();

// Stop and get file
final (file, timestamp) = await recorder.stopRecording();
print('Recording saved: ${file.path}');

// Clean up
await recorder.dispose();
```

## Configuration

### Quality Presets

Choose from predefined quality presets:

```dart
// Low quality - 64 kbps, 22.05 kHz (smallest file size)
RecorderConfig.lowQuality()

// Medium quality - 128 kbps, 44.1 kHz (balanced)
RecorderConfig.mediumQuality()

// High quality - 256 kbps, 48 kHz (best quality)
RecorderConfig.highQuality()

// Voice optimized - 96 kbps, 44.1 kHz (recommended for voice)
RecorderConfig.voice()
```

### Custom Configuration

Create custom recording configuration:

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
);

final recorder = RecorderManager(config: config);
```

### Storage Configuration

Control where recordings are saved:

```dart
// Use temporary directory (default)
StorageConfig.tempDirectory()

// Use app documents directory
StorageConfig.visible()

// Custom directory
StorageConfig.withDirectory('/path/to/directory')

// Specific file path
StorageConfig.withPath('/path/to/file.m4a')

// Custom naming
StorageConfig.withCustomNaming(
  prefix: 'voice_note',
  extension: 'm4a',
)
```

## Waveform Visualization

Access real-time amplitude data for waveform visualization:

```dart
// Listen to amplitude stream
recorder.amplitudeStream.listen((amplitude) {
  print('Current amplitude: ${amplitude.current} dB');
});

// Get waveform buffer
List<double> waveform = recorder.waveformBuffer;

// Check if data is available
bool hasData = recorder.hasAmplitudeData;

// Access wave manager directly
final waveManager = recorder.waveManager;
waveManager.waveformStream.listen((buffer) {
  // Update UI with waveform data
});
```

## Interruption Handling

Automatically handle audio interruptions:

```dart
final recorder = RecorderManager(
  onInterruption: (interruption) {
    print('Interrupted by: ${interruption.type}');
    
    if (interruption.shouldPause) {
      // Recording was automatically paused
      showNotification('Recording paused due to ${interruption.type}');
    }
  },
);

// Listen to interruption stream
recorder.interruptionStream.listen((interruption) {
  switch (interruption.type) {
    case InterruptionType.phoneCall:
      // Handle phone call
      break;
    case InterruptionType.headphoneDisconnect:
      // Handle headphone disconnect
      break;
    // ... other cases
  }
});
```

Supported interruption types:
- Phone calls (regular and VoIP)
- Media playback from other apps
- Headphone/Bluetooth disconnection
- Audio ducking (navigation, alarms)
- System audio route changes

## Error Handling

Comprehensive error handling with specific error types:

```dart
try {
  await recorder.startRecording();
} on RecorderException catch (e) {
  switch (e.type) {
    case RecorderErrorType.permissionDenied:
      // Request permissions
      break;
    case RecorderErrorType.initializationFailed:
      // Handle initialization error
      break;
    case RecorderErrorType.recordingFailed:
      // Handle recording error
      break;
    case RecorderErrorType.storageError:
      // Handle storage error
      break;
    default:
      // Handle other errors
  }
  
  print('Error: ${e.message}');
  if (e.originalError != null) {
    print('Original error: ${e.originalError}');
  }
}
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:recorder/recorder.dart';

class RecordingScreen extends StatefulWidget {
  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late RecorderManager _recorder;
  RecordingState _state = RecordingState.idle;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  void _initializeRecorder() {
    _recorder = RecorderManager(
      config: RecorderConfig.voice(),
      storageConfig: StorageConfig.visible(),
      onStateChanged: (state) {
        setState(() => _state = state);
      },
      onError: (error) {
        setState(() => _errorMessage = error.message);
      },
      onInterruption: (interruption) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Interrupted: ${interruption.type.name}')),
        );
      },
    );
    
    _recorder.initialize();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      await _recorder.startRecording();
    } catch (e) {
      // Error handled by callback
    }
  }

  Future<void> _stopRecording() async {
    try {
      final (file, timestamp) = await _recorder.stopRecording();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved: ${file.path}')),
      );
    } catch (e) {
      // Error handled by callback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recorder')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('State: ${_state.name}'),
            if (_errorMessage != null)
              Text('Error: $_errorMessage', style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            if (_state == RecordingState.idle)
              ElevatedButton(
                onPressed: _startRecording,
                child: Text('Start Recording'),
              ),
            if (_state == RecordingState.recording)
              ElevatedButton(
                onPressed: _stopRecording,
                child: Text('Stop Recording'),
              ),
          ],
        ),
      ),
    );
  }
}
```

## API Reference

### RecorderManager

Main class for managing audio recordings.

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
- `Future<void> reset()` - Reset to initial state
- `Future<void> dispose()` - Clean up resources

#### Properties

- `RecordingState recordingState` - Current state
- `bool isRecording` - Whether recording
- `bool isPaused` - Whether paused
- `bool isStopped` - Whether stopped
- `bool isInitialized` - Whether initialized
- `String? currentRecordingFileName` - Current file name
- `String? currentRecordingFullPath` - Current file path
- `List<double> waveformBuffer` - Waveform data
- `Stream<Amplitude> amplitudeStream` - Amplitude stream
- `Stream<InterruptionData> interruptionStream` - Interruption stream

## Permissions

The package requires microphone permissions. Use the `permission_handler` package (already included) to request permissions:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestPermissions() async {
  final status = await Permission.microphone.request();
  return status.isGranted;
}
```

## Testing

The package includes comprehensive tests. Run them with:

```bash
flutter test
```

## Example App

A complete example app is included in the `example/` directory. Run it with:

```bash
cd example
flutter run
```

## Troubleshooting

### Permission Denied

Make sure you've added the required permissions to your platform-specific configuration files and requested them at runtime.

### Recording Not Starting

Ensure you've called `initialize()` before starting recording:

```dart
await recorder.initialize();
await recorder.startRecording();
```

### File Not Found

Check your storage configuration and ensure the app has write permissions for the specified directory.

### Interruptions Not Working

Make sure you've initialized the audio session by calling `initialize()` on the RecorderManager.

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📧 Email: support@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/yourusername/recorder/issues)
- 📖 Documentation: [GitHub Wiki](https://github.com/yourusername/recorder/wiki)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes in each version.

## Credits

Built with ❤️ using:
- [record](https://pub.dev/packages/record) - Audio recording
- [audio_session](https://pub.dev/packages/audio_session) - Audio session management
- [permission_handler](https://pub.dev/packages/permission_handler) - Permission handling
- [path_provider](https://pub.dev/packages/path_provider) - File path management
