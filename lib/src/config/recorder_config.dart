import 'package:record/record.dart';

/// Configuration for the audio recorder
/// 
/// Provides customizable settings for recording quality, format, and behavior.
/// Use predefined presets or create custom configurations.
class RecorderConfig {
  /// Audio encoder to use
  final AudioEncoder encoder;
  
  /// Bit rate in bits per second (e.g., 128000 for 128 kbps)
  final int bitRate;
  
  /// Sample rate in Hz (e.g., 44100 for CD quality)
  final int sampleRate;
  
  /// Number of audio channels (1 for mono, 2 for stereo)
  final int numChannels;
  
  /// Enable automatic gain control
  final bool autoGain;
  
  /// Enable echo cancellation
  final bool echoCancel;
  
  /// Enable noise suppression
  final bool noiseSuppress;
  
  /// Prefix for recording filenames
  final String filePrefix;
  
  /// File extension (without dot)
  final String fileExtension;
  
  /// Android-specific configuration
  final AndroidRecorderConfig? androidConfig;
  
  /// iOS-specific configuration
  final IOSRecorderConfig? iosConfig;

  const RecorderConfig({
    this.encoder = AudioEncoder.aacLc,
    this.bitRate = 128000,
    this.sampleRate = 44100,
    this.numChannels = 1,
    this.autoGain = true,
    this.echoCancel = true,
    this.noiseSuppress = true,
    this.filePrefix = 'recording',
    this.fileExtension = 'm4a',
    this.androidConfig,
    this.iosConfig,
  });

  /// Low quality preset (64 kbps, 22.05 kHz)
  /// Good for voice memos, smallest file size
  factory RecorderConfig.lowQuality() {
    return const RecorderConfig(
      bitRate: 64000,
      sampleRate: 22050,
      numChannels: 1,
    );
  }

  /// Medium quality preset (128 kbps, 44.1 kHz)
  /// Balanced quality and file size
  factory RecorderConfig.mediumQuality() {
    return const RecorderConfig(
      bitRate: 128000,
      sampleRate: 44100,
      numChannels: 1,
    );
  }

  /// High quality preset (256 kbps, 48 kHz)
  /// Best quality, larger file size
  factory RecorderConfig.highQuality() {
    return const RecorderConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 256000,
      sampleRate: 48000,
      numChannels: 2,
    );
  }

  /// Voice optimized preset
  /// Optimized for voice recording with noise suppression
  factory RecorderConfig.voice() {
    return const RecorderConfig(
      bitRate: 96000,
      sampleRate: 44100,
      numChannels: 1,
      autoGain: true,
      echoCancel: true,
      noiseSuppress: true,
    );
  }

  /// Converts to RecordConfig for the record package
  RecordConfig toRecordConfig() {
    return RecordConfig(
      encoder: encoder,
      bitRate: bitRate,
      sampleRate: sampleRate,
      numChannels: numChannels,
      autoGain: autoGain,
      echoCancel: echoCancel,
      noiseSuppress: noiseSuppress,
      androidConfig: androidConfig?.toAndroidRecordConfig() ?? 
        const AndroidRecordConfig(
          audioSource: AndroidAudioSource.mic,
          useLegacy: true,
          muteAudio: false,
        ),
    );
  }

  RecorderConfig copyWith({
    AudioEncoder? encoder,
    int? bitRate,
    int? sampleRate,
    int? numChannels,
    bool? autoGain,
    bool? echoCancel,
    bool? noiseSuppress,
    String? filePrefix,
    String? fileExtension,
    AndroidRecorderConfig? androidConfig,
    IOSRecorderConfig? iosConfig,
  }) {
    return RecorderConfig(
      encoder: encoder ?? this.encoder,
      bitRate: bitRate ?? this.bitRate,
      sampleRate: sampleRate ?? this.sampleRate,
      numChannels: numChannels ?? this.numChannels,
      autoGain: autoGain ?? this.autoGain,
      echoCancel: echoCancel ?? this.echoCancel,
      noiseSuppress: noiseSuppress ?? this.noiseSuppress,
      filePrefix: filePrefix ?? this.filePrefix,
      fileExtension: fileExtension ?? this.fileExtension,
      androidConfig: androidConfig ?? this.androidConfig,
      iosConfig: iosConfig ?? this.iosConfig,
    );
  }
}

/// Android-specific recorder configuration
class AndroidRecorderConfig {
  /// Audio source to use
  final AndroidAudioSource audioSource;
  
  /// Use legacy audio API
  final bool useLegacy;
  
  /// Mute audio during recording
  final bool muteAudio;
  
  /// Foreground service configuration
  final AndroidServiceConfig? serviceConfig;

  const AndroidRecorderConfig({
    this.audioSource = AndroidAudioSource.mic,
    this.useLegacy = true,
    this.muteAudio = false,
    this.serviceConfig,
  });

  AndroidRecordConfig toAndroidRecordConfig() {
    return AndroidRecordConfig(
      audioSource: audioSource,
      useLegacy: useLegacy,
      muteAudio: muteAudio,
      service: serviceConfig?.toAndroidService(),
    );
  }
}

/// Android foreground service configuration
class AndroidServiceConfig {
  /// Service notification title
  final String title;
  
  /// Service notification content
  final String content;
  
  /// Notification icon (optional)
  final String? icon;

  const AndroidServiceConfig({
    required this.title,
    required this.content,
    this.icon,
  });

  AndroidService toAndroidService() {
    return AndroidService(
      title: title,
      content: content,
    );
  }
}

/// iOS-specific recorder configuration
class IOSRecorderConfig {
  /// Audio quality
  final int audioQuality;
  
  /// Enable background recording
  final bool backgroundRecording;

  const IOSRecorderConfig({
    this.audioQuality = 127,
    this.backgroundRecording = false,
  });
}
