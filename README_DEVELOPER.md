# Recording Module - Developer Guide

## 🎯 Project Overview

This is a Flutter audio recording application with advanced features:
- ✅ Background recording (Android + iOS)
- ✅ Interruption handling (15+ types)
- ✅ Live waveform visualization
- ✅ Full recording controls (start/pause/resume/stop/restart/delete)

---

## 📚 Architecture

This project follows the **Orchestrator Pattern** with clean separation of concerns:

```
┌─────────────────────────────────────┐
│         UI Layer (Provider)         │
│  - RecordingProvider                │
│  - Recording Screen                 │
│  - Waveform Widget                  │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│    Orchestration Layer              │
│  - RecorderManager                  │
│    (coordinates all services)       │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│         Service Layer               │
│  - RecorderService                  │
│  - AudioSessionService              │
│  - BackgroundService                │
│  - WaveDataManager                  │
│  - StorageHandler                   │
└─────────────┬───────────────────────┘
              │
┌─────────────▼───────────────────────┐
│      Infrastructure Layer           │
│  - record package                   │
│  - audio_session package            │
│  - flutter_background package       │
└─────────────────────────────────────┘
```

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── enums/
│   │   └── enums.dart                    # RecordingState, InterruptionType
│   └── models/
│       └── interruption_data.dart        # Interruption event model
│
├── services/
│   └── recording_services/
│       ├── recorder_storage_handler.dart # File operations
│       ├── recorder_service.dart         # Recording wrapper
│       ├── audio_session_service.dart    # Interruption detection
│       └── recording_background_service.dart # Background execution
│
├── widgets/
│   └── live_wave_form_widget/
│       └── wave_data_manager.dart        # Amplitude buffer
│
├── screens/
│   └── recorder_view/
│       ├── manager/
│       │   └── recorder_manager.dart     # Main orchestrator
│       ├── provider/                     # TODO: Phase 4
│       └── widgets/                      # TODO: Phase 5
│
└── main.dart                             # TODO: Phase 4
```

---

## 🔧 Services Explained

### 1. RecorderManager (Orchestrator)
**Purpose:** Single entry point for all recording operations

**Key Methods:**
```dart
await manager.initialize()           // Setup all services
await manager.startRecording()       // Start recording
await manager.pauseRecording()       // Pause recording
await manager.resumeRecording()      // Resume recording
await manager.stopRecording()        // Stop and save
await manager.deleteRecording()      // Delete current
await manager.restartRecording()     // Restart from scratch
await manager.dispose()              // Cleanup
```

**Streams:**
```dart
manager.interruptionStream           // Listen to interruptions
manager.amplitudeStream              // Listen to amplitude
manager.waveManager.waveformStream   // Listen to waveform data
```

**State:**
```dart
manager.isRecording                  // bool
manager.isPaused                     // bool
manager.isStopped                    // bool
manager.recordingState               // RecordingState enum
manager.currentRecordingFileName     // String?
manager.waveformBuffer               // List<double>
```

---

### 2. RecorderService
**Purpose:** Low-level recording operations

**Features:**
- Wraps `record` package
- AAC-LC codec, 44.1kHz, 128kbps
- Auto-generated filenames: `recording_<timestamp>.m4a`
- Amplitude streaming every 100ms

---

### 3. AudioSessionService (Singleton)
**Purpose:** Audio session and interruption management

**Detects:**
- Phone calls (regular + VoIP)
- Headphone/Bluetooth disconnect
- Media playback conflicts
- Camera usage
- Screen recording
- Voice assistant
- And more...

**Usage:**
```dart
final service = AudioSessionService.instance;
await service.initialize();
await service.configureForRecording();

service.interruptionEvents.listen((interruption) {
  print('Interruption: ${interruption.type}');
});
```

---

### 4. RecordingBackgroundService (Singleton)
**Purpose:** Background execution

**Platform-Specific:**
- **Android:** Foreground service with notification
- **iOS:** Native audio background mode

**Usage:**
```dart
final service = RecordingBackgroundService.instance;
await service.initialize();
await service.startService();  // Start background mode
await service.stopService();   // Stop background mode
```

---

### 5. WaveDataManager (Singleton)
**Purpose:** Waveform visualization data

**Features:**
- Circular buffer (100 values max)
- Normalized amplitude (0.0 to 1.0)
- Real-time stream updates
- Curved normalization for better visuals

**Usage:**
```dart
final manager = WaveDataManager.instance;
manager.initialize();

manager.waveformStream.listen((amplitudes) {
  // Update UI with waveform
  // amplitudes is List<double> with values 0.0-1.0
});
```

---

### 6. RecorderStorageHandler
**Purpose:** File system operations

**Features:**
- Generate unique file paths
- Hidden storage (temp files)
- Public storage (finalized files)
- File deletion and cleanup

---

## 🚀 Quick Start Guide

### Basic Recording Flow

```dart
// 1. Create manager
final manager = RecorderManager();

// 2. Initialize
final initialized = await manager.initialize();
if (!initialized) {
  print('Initialization failed');
  return;
}

// 3. Start recording
try {
  await manager.startRecording();
  print('Recording started');
} catch (e) {
  print('Failed to start: $e');
}

// 4. Pause (optional)
await manager.pauseRecording();

// 5. Resume (optional)
await manager.resumeRecording();

// 6. Stop and get file
final (file, timestamp) = await manager.stopRecording();
print('Recording saved: ${file.path}');
print('Duration: ${timestamp.difference(startTime)}');

// 7. Cleanup
await manager.dispose();
```

---

### With Waveform Visualization

```dart
final manager = RecorderManager();
await manager.initialize();

// Listen to waveform data
manager.waveManager.waveformStream.listen((amplitudes) {
  // amplitudes is List<double> with 0-100 values
  // Each value is between 0.0 (silence) and 1.0 (max)
  
  // Update your waveform widget
  setState(() {
    waveformData = amplitudes;
  });
});

await manager.startRecording();
// Waveform will update automatically every 100ms
```

---

### With Interruption Handling

```dart
final manager = RecorderManager();
await manager.initialize();

// Listen to interruptions
manager.interruptionStream.listen((interruption) {
  print('Interruption type: ${interruption.type}');
  print('Should pause: ${interruption.shouldPause}');
  
  if (interruption.shouldPause && manager.isRecording) {
    // Auto-pause on interruption
    manager.pauseRecording();
    
    // Show message to user
    showSnackBar('Recording paused: ${interruption.type}');
  }
});

await manager.startRecording();
```

---

## 📦 Dependencies

```yaml
dependencies:
  record: ^5.2.1              # Audio recording
  audio_session: ^0.1.25      # Session management
  permission_handler: ^11.4.0 # Permissions
  flutter_background: ^1.3.0  # Background service
  path_provider: ^2.1.5       # File paths
  provider: ^6.1.5            # State management
```

---

## 🔐 Permissions Required

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### iOS (Info.plist)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record audio</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

---

## 🎨 Recording Configuration

### Audio Settings
- **Format:** AAC-LC (m4a)
- **Sample Rate:** 44100 Hz (CD quality)
- **Bit Rate:** 128 kbps
- **Encoder:** AAC-LC

### File Naming
- **Pattern:** `recording_<timestamp>.m4a`
- **Example:** `recording_1704067200000.m4a`
- **Location:** App documents directory

### Waveform Settings
- **Buffer Size:** 100 values
- **Update Interval:** 100ms
- **Value Range:** 0.0 (silence) to 1.0 (maximum)
- **Normalization:** Curved for better visualization

---

## 🐛 Error Handling

All services include comprehensive error handling:

```dart
try {
  await manager.startRecording();
} catch (e) {
  // Handle error
  print('Recording error: $e');
  
  // Cleanup is automatic
  // Services will clean up on error
}
```

---

## 🧪 Testing

### Unit Testing Services

```dart
// Mock services for testing
final mockRecorder = MockRecorderService();
final mockAudioSession = MockAudioSessionService();

final manager = RecorderManager(
  recorder: mockRecorder,
  audioSessionService: mockAudioSession,
);

// Test your logic
await manager.initialize();
verify(mockRecorder.initialize()).called(1);
```

---

## 📝 Code Quality

✅ **Comprehensive Documentation** - Every class and method  
✅ **Simple & Readable** - Easy to understand  
✅ **Error Handling** - Try-catch throughout  
✅ **Resource Cleanup** - Proper dispose methods  
✅ **Stream-Based** - Reactive architecture  
✅ **Testable** - Dependency injection  
✅ **No Over-Engineering** - Keep it simple  

---

## 🎯 Implementation Status

### ✅ Completed (Phases 1-3)
- [x] Core enums and models
- [x] All service layer
- [x] RecorderManager orchestrator
- [x] Waveform data management
- [x] Background service support
- [x] Interruption detection
- [x] File management

### ⏳ TODO (Phases 4-7)
- [ ] Provider state management
- [ ] UI screens and widgets
- [ ] Platform configuration
- [ ] Permission handling UI
- [ ] Testing

---

## 💡 Tips for Developers

1. **Always initialize before use**
   ```dart
   await manager.initialize();
   ```

2. **Always dispose when done**
   ```dart
   await manager.dispose();
   ```

3. **Check state before operations**
   ```dart
   if (manager.isRecording) {
     await manager.pauseRecording();
   }
   ```

4. **Handle interruptions gracefully**
   ```dart
   manager.interruptionStream.listen((interruption) {
     // Handle interruption
   });
   ```

5. **Use RecorderManager, not services directly**
   ```dart
   // ✅ Good
   await manager.startRecording();
   
   // ❌ Bad
   await recorderService.startRecording();
   ```

---

## 📚 Additional Resources

- `IMPLEMENTATION_SUMMARY.md` - Technical details
- `PHASES_1_2_3_COMPLETE.md` - Completion status
- `RECORDING_MODULE_ARCHITECTURE.md` - Architecture guide

---

## 🤝 Contributing

When adding new features:
1. Follow the existing architecture
2. Add comprehensive doc comments
3. Include error handling
4. Add dispose/cleanup methods
5. Keep code simple and readable

---

## 📞 Support

For questions about the implementation:
1. Check the doc comments in the code
2. Review the architecture documentation
3. Look at the usage examples above

---

**Version:** 1.0  
**Status:** Phases 1-3 Complete ✅  
**Next:** Phase 4 - Provider State Management
