# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-11-26

### Added
- Initial release of the voice_recorder package
- `RecorderManager` for easy recording management
- Multiple quality presets (low, medium, high, voice)
- Custom recording configuration support
- Real-time waveform visualization with amplitude streaming
- Automatic interruption handling for:
  - Phone calls (regular and VoIP)
  - Media playback from other apps
  - Headphone/Bluetooth disconnection
  - Audio ducking events
  - System audio route changes
- Pause/resume recording functionality
- Flexible storage configuration options
- Comprehensive error handling with specific error types
- State management with callbacks
- Clean architecture with dependency injection
- Full documentation and examples

### Features
- **RecorderManager**: Main API for recording operations
- **RecorderConfig**: Flexible configuration with presets
- **StorageConfig**: Customizable storage options
- **WaveDataManager**: Real-time waveform data management
- **AudioSessionService**: Automatic audio session handling
- **RecorderException**: Structured error handling
- **InterruptionData**: Detailed interruption information

### Supported Platforms
- ✅ Android (API 21+)
- ✅ iOS (iOS 12.0+)

### Dependencies
- `record: ^6.1.2` - Core audio recording
- `audio_session: ^0.2.2` - Audio session management
- `permission_handler: ^12.0.1` - Permission handling
- `path_provider: ^2.1.5` - File path management

### Documentation
- Comprehensive README with examples
- API documentation with dartdoc comments
- Example app demonstrating all features
- Migration guide for converting apps to packages

### Known Issues
- None

### Breaking Changes
- None (initial release)

---

## [Unreleased]

### Planned Features
- [ ] Recording metadata (duration, file size, etc.)
- [ ] Audio playback integration
- [ ] Recording list management
- [ ] Cloud storage integration
- [ ] Audio format conversion
- [ ] Background recording support
- [ ] Recording trimming/editing
- [ ] Audio effects (filters, normalization)
- [ ] Multi-track recording
- [ ] Web platform support

---

## Version History

- **0.1.0** - Initial release (2024-11-26)

---

## Migration Guides

### From 0.0.x to 0.1.0
This is the initial release, no migration needed.

---

## Support

For issues, questions, or contributions, please visit:
- [GitHub Issues](https://github.com/yourusername/recorder/issues)
- [GitHub Discussions](https://github.com/yourusername/recorder/discussions)

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
