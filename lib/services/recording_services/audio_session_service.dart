import 'dart:async';
import 'package:audio_session/audio_session.dart';
import '../../core/enums/enums.dart';
import '../../core/models/interruption_data.dart';

/// Manages audio session configuration and interruption detection.
///
/// Configures audio for recording/playback and monitors interruptions
/// like phone calls, media playback, and device disconnections.
/// Use [AudioSessionService.instance] to access the singleton.
///
/// Supported audio interruption scenarios:
/// - Phone/VoIP calls (WhatsApp, Teams, Zoom, etc.)
/// - Media playback (Spotify, YouTube, etc.)
/// - Headphone/Bluetooth disconnection
/// - Audio ducking (navigation, alarms)
/// - Becoming noisy (sudden unplugging)
/// - Audio route changes
/// - Camera usage, screen recording
/// - Voice assistants (Siri/Google)
/// - Low battery mode
/// - Split screen mode (Android)
///
class AudioSessionService {
  /// Singleton instance
  static final AudioSessionService instance = AudioSessionService._internal();

  /// Private constructor for singleton
  AudioSessionService._internal();

  /// The audio session instance
  AudioSession? _audioSession;

  /// Whether the service has been initialized
  bool _isInitialized = false;

  /// Stream subscriptions for different interruption types
  StreamSubscription<AudioInterruptionEvent>? _interruptionSubscription;
  StreamSubscription<AudioDevicesChangedEvent>? _devicesSubscription;
  StreamSubscription<void>? _becomingNoisySubscription;

  /// Controller for broadcasting interruption events
  final StreamController<InterruptionData> _interruptionController =
      StreamController<InterruptionData>.broadcast();

  /// Stream of interruption events
  ///
  /// Subscribe to this stream to receive notifications about audio interruptions
  /// like phone calls, headphone disconnections, etc.
  Stream<InterruptionData> get interruptionEvents => _interruptionController.stream;

  /// Whether the service is initialized
  bool get isInitialized => _isInitialized;

  /// The audio session instance (may be null if not initialized)
  AudioSession? get audioSession => _audioSession;

  /// Initializes the audio session service
  ///
  /// Sets up the audio session and starts listening for interruptions.
  /// Should be called once when the app starts or before recording.
  ///
  /// Returns true if initialization was successful.
  Future<bool> initialize() async {
    try {
      if (_isInitialized) {
        print('AudioSessionService: Already initialized');
        return true;
      }

      // Get the audio session instance
      _audioSession = await AudioSession.instance;

      // Setup interruption listeners
      _setupInterruptionStreams();

      _isInitialized = true;
      print('AudioSessionService: Initialized successfully');
      return true;
    } catch (e) {
      print('AudioSessionService: Initialization error - $e');
      return false;
    }
  }

  /// Configures the audio session for recording
  ///
  /// Sets up optimal audio configuration for recording:
  /// - Enables recording mode
  /// - Configures for voice/music recording
  /// - Handles interruptions appropriately
  ///
  /// Returns true if configuration was successful.
  Future<bool> configureForRecording() async {
    try {
      if (_audioSession == null) {
        print('AudioSessionService: Not initialized, initializing now...');
        await initialize();
      }

      final session = _audioSession;
      if (session == null) {
        print('AudioSessionService: Audio session is null after initialization');
        return false;
      }

      // Configure for recording
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.record,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth,
        avAudioSessionMode: AVAudioSessionMode.spokenAudio,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));

      // Activate the audio session
      await session.setActive(true);

      print('AudioSessionService: Configured for recording');
      return true;
    } catch (e) {
      print('AudioSessionService: Configuration error - $e');
      return false;
    }
  }

  /// Sets up listeners for different types of audio interruptions
  void _setupInterruptionStreams() {
    final session = _audioSession;
    if (session == null) return;

    // 1. System interruptions (phone calls, media playback, etc.)
    _interruptionSubscription = session
        .interruptionEventStream
        .listen(_handleSystemInterruption);

    // 2. Device changes (headphones, Bluetooth devices)
    _devicesSubscription = session
        .devicesChangedEventStream
        .listen(_handleDeviceChange);

    // 3. Becoming noisy (sudden audio route change, like unplugging headphones)
    _becomingNoisySubscription = session
        .becomingNoisyEventStream
        .listen(_handleBecomingNoisy);

    print('AudioSessionService: Interruption streams setup complete');
  }

  /// Handles system-level audio interruptions
  ///
  /// Examples: phone calls, VoIP calls, other media playback
  void _handleSystemInterruption(AudioInterruptionEvent event) {
    print('AudioSessionService: System interruption - ${event.type}');

    if (event.begin) {
      // Ignore unknown interruptions (false positives during recording setup)
      // if (event.type == AudioInterruptionType.unknown) {
      //   print('AudioSessionService: Ignoring unknown interruption (likely false positive)');
      //   return;
      // }

      // Interruption started
      final type = _mapInterruptionType(event.type);
      _emitInterruption(type, shouldPause: true);
    } else {
      // Interruption ended - could resume here if needed
      print('AudioSessionService: Interruption ended');
    }
  }

  /// Handles audio device changes
  ///
  /// Examples: headphones plugged/unplugged, Bluetooth connected/disconnected
  void _handleDeviceChange(AudioDevicesChangedEvent event) {
    print('AudioSessionService: Devices changed');

    // Check for removed devices (disconnections)
    for (final device in event.devicesRemoved) {
      print('AudioSessionService: Device removed - ${device.name}');

      final type = _identifyDeviceType(device);
      _emitInterruption(type, shouldPause: true);
    }

    // Could also handle added devices if needed
    for (final device in event.devicesAdded) {
      print('AudioSessionService: Device added - ${device.name}');
    }
  }

  /// Handles "becoming noisy" events
  ///
  /// This occurs when audio output suddenly changes (e.g., headphones unplugged)
  void _handleBecomingNoisy(void event) {
    print('AudioSessionService: Becoming noisy event');

    _emitInterruption(
      InterruptionType.becomingNoisy,
      shouldPause: true,
    );
  }

  /// Maps audio session interruption types to our enum
  InterruptionType _mapInterruptionType(AudioInterruptionType type) {
    switch (type) {
      case AudioInterruptionType.unknown:
        return InterruptionType.unknown;
      case AudioInterruptionType.pause:
        return InterruptionType.mediaPlayback;
      case AudioInterruptionType.duck:
        return InterruptionType.duck;
    }
  }

  /// Identifies the type of audio device for interruption classification
  InterruptionType _identifyDeviceType(AudioDevice device) {
    final name = device.name.toLowerCase();

    if (name.contains('bluetooth') || name.contains('bt')) {
      return InterruptionType.bluetoothDisconnect;
    } else if (name.contains('headphone') || name.contains('headset')) {
      return InterruptionType.headphoneDisconnect;
    } else {
      return InterruptionType.audioRouteChange;
    }
  }

  /// Emits an interruption event to all listeners
  void _emitInterruption(InterruptionType type, {required bool shouldPause}) {
    if (_interruptionController.isClosed) return;

    final event = InterruptionData(
      type: type,
      timestamp: DateTime.now(),
      shouldPause: shouldPause,
      isInterrupted: true,
    );

    _interruptionController.add(event);
    print('AudioSessionService: Emitted interruption - $type');
  }

  /// Resets the audio session
  ///
  /// Deactivates the audio session. Call this after stopping recording.
  Future<void> reset() async {
    try {
      final session = _audioSession;
      if (session != null) {
        await session.setActive(false);
        print('AudioSessionService: Reset complete');
      }
    } catch (e) {
      print('AudioSessionService: Reset error - $e');
    }
  }

  /// Disposes the service and cleans up resources
  ///
  /// Cancels all subscriptions and closes streams.
  void dispose() {
    _interruptionSubscription?.cancel();
    _devicesSubscription?.cancel();
    _becomingNoisySubscription?.cancel();
    _interruptionController.close();

    _isInitialized = false;
    print('AudioSessionService: Disposed');
  }
}
