# 🎙️ Voice Recorder

[![pub package](https://img.shields.io/pub/v/voice_recorder.svg)](https://pub.dev/packages/voice_recorder)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-green.svg)](https://pub.dev/packages/voice_recorder)

**The easiest way to add audio recording to your Flutter app.** 🚀

Record crystal-clear audio with just **2 lines of code**. Built-in waveforms, background recording support, and automatic interruption handling make this the most developer-friendly audio recorder for Flutter.

✨ **Perfect for:** Voice notes • Interviews • Podcasts • Voice memos • Audio messaging • Language learning apps

---

## ✨ Why Developers Love This Package

- 🚀 **2-Line Setup** - Literally start recording in seconds
- 🎨 **Beautiful Waveforms** - Animated, real-time audio visualization included
- 🔄 **Background Recording** - Keep recording even when app is in background
- ⚡ **Zero Config** - Works out of the box, no complex initialization
- 🎯 **Beginner Friendly** - Crystal-clear docs with copy-paste examples
- 🛡️ **Bulletproof** - Handles phone calls, interruptions, and edge cases automatically
- 🎛️ **Flexible** - Simple for beginners, powerful for pros
- 📱 **True Cross-Platform** - Identical API for Android & iOS
- 🎧 **Smart Interruptions** - Auto-pauses for calls, headphone disconnects, etc.

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

### 2. Record Audio (3 lines!)
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

## 🎨 With Wave Visualization

```dart
final recorder = VoiceRecorder();

// In your widget:
AudioWaveWidget.fromRecorder(recorder: recorder)

// Start recording
await recorder.start();
```

**Result**: Beautiful, animated waveform that syncs with your voice!

---

## 🔧 Platform Setup & Permissions

### 📱 Android Setup

Add these permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Required: Microphone access for recording -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />

<!-- Required for Android 12 and below (auto-ignored on 13+) -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="28" />

<!-- Optional: For background recording (highly recommended) -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />

<!-- Optional: Android 13+ notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

#### 🔄 Background Recording on Android

To enable recording when your app is in the background, add this to your `<application>` tag:

```xml
<application>
  <!-- Your existing config -->
  
  <!-- Add this for background recording -->
  <service
      android:name="com.example.voice_recorder.RecordingService"
      android:foregroundServiceType="microphone"
      android:exported="false" />
</application>
```

**Why?** Android requires a foreground service to record audio in the background. This ensures users know recording is active via a persistent notification.

### 🍎 iOS Setup

Add these keys to `ios/Runner/Info.plist`:

```xml
<!-- Required: Microphone permission -->
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record your voice notes</string>

<!-- Optional but recommended: Background audio -->
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

**Pro Tip:** Customize the `NSMicrophoneUsageDescription` message to explain *why* your app needs the microphone. Users are more likely to grant permission when they understand the reason!

#### 🔄 Background Recording on iOS

iOS automatically supports background recording when you add the `audio` background mode above. The recording continues even when:
- ✅ App is minimized
- ✅ Screen is locked
- ✅ User switches to another app

**Note:** iOS will show a red bar at the top of the screen indicating active recording, which is a system requirement for user privacy.

---

## 📖 Usage Examples

### Basic Recording

```dart
import 'package:voice_recorder/voice_recorder.dart';

// Create recorder
final recorder = VoiceRecorder();

// Start recording
await recorder.start();

await recorder.pause();   // Pause
await recorder.resume();  // Resume

// Stop and get file info
final recording = await recorder.stop();
print('Path: ${recording.path}');
print('Duration: ${recording.duration.inSeconds}s');
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

### Option 2: Manual Control (Full Control)

```dart
recorder.amplitudeStream.listen((amplitude) {
  final decibels = amplitude.current;
  // Build your own custom visualization
});
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

## 📞 Smart Interruption Handling

**Never lose a recording again!** The package automatically handles real-world interruptions:

### What's Handled Automatically

- ☎️ **Phone Calls** - Auto-pauses recording
- 🎧 **Headphone Disconnect** - Pauses to prevent speaker playback
- 📱 **Bluetooth Disconnect** - Handles audio device changes
- 🔊 **Audio Route Changes** - Adapts to new audio output
- 📲 **App Backgrounding** - Continues recording in background (if configured)

### Listen to Interruptions

```dart
final recorder = VoiceRecorder(
  onInterruption: (interruption) {
    switch (interruption.type) {
      case InterruptionType.phoneCall:
        // Recording automatically paused
        showNotification('Recording paused - incoming call');
        break;
      
      case InterruptionType.headphoneDisconnect:
        // Paused to prevent audio playing on speaker
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Headphones Disconnected'),
            content: Text('Recording paused. Reconnect to continue.'),
          ),
        );
        break;
      
      case InterruptionType.audioRouteChange:
        print('Audio route changed: ${interruption.reason}');
        break;
    }
  },
);
```

### Background Recording Behavior

When your app goes to the background:

**iOS:**
- ✅ Recording continues automatically
- ✅ Red status bar indicates active recording
- ✅ Lock screen shows recording status

**Android:**
- ✅ Foreground service keeps recording alive
- ✅ Persistent notification shows recording status

### Customize Background Notification (Android)

```dart
await recorder.start(
  config: RecorderConfig(
    androidConfig: AndroidRecorderConfig(
      serviceConfig: AndroidServiceConfig(
        title: "Audio Recorder",
        content: "Recording is Ongoing...",
      ),
    ),
  ),
storageConfig: StorageConfig.visible(),
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
| `start({config, storageConfig})` | Start recording |
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

---

## 🔐 Runtime Permissions (Important!)



### 🔄 Background Recording Permissions

For apps that need background recording, request additional permissions:

```dart
Future<bool> requestBackgroundPermissions() async {
  // Request microphone first
  final micStatus = await Permission.microphone.request();
  
  if (!micStatus.isGranted) {
    return false;
  }
  
  // For Android 13+ (API 33+), request notification permission
  // This is needed for foreground service notification
  if (Platform.isAndroid) {
    final notificationStatus = await Permission.notification.request();
    if (!notificationStatus.isGranted) {
      print('Notification permission needed for background recording');
    }
  }
  
  return true;
}
```

---

## ❓ Troubleshooting

### 🚫 Permission Denied
**Problem**: Recording fails with "Permission denied" error

**Solutions**:
1. ✅ Add platform permissions to `AndroidManifest.xml` / `Info.plist` (see [Platform Setup](#-platform-setup--permissions))
2. ✅ Request permission at runtime using `permission_handler` package
3. ✅ Check device settings - user may have denied permission
4. ✅ On iOS, check if microphone is restricted in Screen Time settings
5. ✅ Test on a real device (permissions behave differently on simulators)

```dart
// Debug permission status
final status = await Permission.microphone.status;
print('Microphone permission: $status');
```

### 📁 File Not Found
**Problem**: Recording file not found after calling `stop()`

**Solutions**:
- ✅ Use `StorageConfig.visible()` for persistent storage
- ✅ Verify the path is accessible and not in a restricted directory

```dart
// Use visible or custom path config for important recordings
await recorder.start(
  storageConfig: StorageConfig.visible(),
);
```

### 🔇 No Audio Recorded
**Problem**: File is created but contains no audio or is silent

**Solutions**:
- ✅ Check microphone is not being used by another app
- ✅ Verify microphone permission is actually granted (not just requested)
- ✅ Test with different quality settings (try `RecorderConfig.highQuality()`)
- ✅ On Android, check if "Microphone" is disabled in app settings
- ✅ Restart the device (sometimes audio session gets stuck)

```dart
// Test with high quality settings
await recorder.start(
  config: RecorderConfig.highQuality(),
);
```

### 🌊 Wave Not Showing
**Problem**: Wave widget not displaying or not animating

**Solutions**:
- ✅ Ensure recorder is actually recording (check `recorder.isRecording`)
- ✅ Verify `AudioWaveWidget.fromRecorder()` is passed the correct recorder instance
- ✅ Check if widget is in the widget tree and has non-zero size
- ✅ Try different wave configs (e.g., `WaveConfig.modern()`)

```dart
// Debug amplitude stream
recorder.amplitudeStream.listen((amplitude) {
  print('Amplitude: ${amplitude.current}');
});
```

### 🔄 Background Recording Stops
**Problem**: Recording stops when app goes to background

**Solutions**:

**Android:**
- ✅ Add `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_MICROPHONE` permissions
- ✅ Declare the recording service in `AndroidManifest.xml`
- ✅ Request notification permission on Android 13+ (API 33+)
- ✅ Ensure battery optimization is disabled for your app

**iOS:**
- ✅ Add `audio` to `UIBackgroundModes` in `Info.plist`
- ✅ Ensure audio session is configured correctly (handled automatically)
- ✅ Check if Low Power Mode is affecting background tasks


### 📱 App Crashes on Start
**Problem**: App crashes when calling `recorder.start()`

**Solutions**:
- ✅ Ensure all platform permissions are added
- ✅ Check for conflicting audio plugins
- ✅ Verify you're not calling `start()` multiple times simultaneously
- ✅ Make sure to call `dispose()` on old recorder instances
- ✅ Check device logs for specific error messages

```dart
// Proper lifecycle management
@override
void dispose() {
  recorder.dispose(); // Always dispose!
  super.dispose();
}
```

### 🔊 Audio Quality Issues
**Problem**: Recording sounds muffled, distorted, or low quality

**Solutions**:
- ✅ Use `RecorderConfig.highQuality()` for better audio
- ✅ Increase `bitRate` and `sampleRate` in custom config
- ✅ Enable `noiseSuppress: false` if it's affecting quality
- ✅ Test in a quiet environment to rule out background noise
- ✅ Check if device microphone is physically blocked or damaged

```dart
// Maximum quality settings
await recorder.start(
  config: RecorderConfig(
    bitRate: 256000,
    sampleRate: 48000,
    numChannels: 2, // Stereo
    noiseSuppress: false,
  ),
);
```

### 💡 Still Having Issues?

1. **Enable Debug Logging**: Check console for detailed error messages
2. **Test on Real Device**: Emulators have limited audio support
3. **Check Example App**: Run the example app to verify setup
4. **Update Dependencies**: Ensure you're using the latest version
5. **Report Bug**: [Open an issue](https://github.com/prathviksankaliya/voice-recorder/issues) with device info and logs

---

## 🎓 Examples

Check out the `/example` folder for complete production-ready examples:

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

- 📧 **Issues**: [GitHub Issues](https://github.com/prathviksankaliya/voice-recorder/issues)
- 📖 **Documentation**: [API Docs](https://pub.dev/documentation/voice-recorder/latest/)

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
