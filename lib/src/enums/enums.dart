/// Core enums for the recording module.
library;

/// Represents the current state of the audio recorder
/// 
/// Used to track and manage the recording lifecycle:
/// - [idle]: Recorder is ready but not recording
/// - [recording]: Actively recording audio
/// - [paused]: Recording is paused, can be resumed
/// - [stopped]: Recording has been stopped and saved
enum RecordingState {
  /// Initial state, recorder is ready to start
  idle,
  
  /// Currently recording audio
  recording,
  
  /// Recording is paused, can be resumed
  paused,
  
  /// Recording has been stopped and saved
  stopped,
}

/// Types of audio interruptions that can occur during recording
/// 
/// These interruptions are detected by the AudioSessionService and
/// can trigger automatic pause/resume behavior.
enum InterruptionType {
  /// Regular phone call (incoming or outgoing)
  phoneCall,
  
  /// VoIP call (WhatsApp, Teams, Zoom, etc.)
  voipCall,
  
  /// Other media playback (Spotify, YouTube, etc.)
  mediaPlayback,
  
  /// Wired headphones were unplugged
  headphoneDisconnect,
  
  /// Bluetooth device was disconnected
  bluetoothDisconnect,
  
  /// Sudden audio route change (becoming noisy)
  becomingNoisy,
  
  /// Audio route changed (speaker/headphone switch)
  audioRouteChange,
  
  /// Audio volume reduced (navigation, notifications)
  duck,
  
  /// Camera app started using audio
  cameraUsage,
  
  /// Screen recording started
  screenRecording,
  
  /// Voice assistant activated (Siri, Google Assistant)
  voiceAssistant,
  
  /// Device entered low battery mode
  lowBattery,
  
  /// Split screen mode activated (Android)
  splitScreen,
  
  /// Unknown interruption type
  unknown,
}
