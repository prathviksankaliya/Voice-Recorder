import 'package:flutter/material.dart';
import 'package:voice_recorder/voice_recorder.dart';

/// Example 2: Customization
/// 
/// This example shows how to customize:
/// - Audio quality (low, medium, high, voice)
/// - Storage location (temp, visible, custom)
/// - Recording configuration
class Customization extends StatefulWidget {
  const Customization({super.key});

  @override
  State<Customization> createState() => _CustomizationState();
}

class _CustomizationState extends State<Customization> {
  late VoiceRecorder _recorder;
  RecordingState _state = RecordingState.idle;
  
  // Customization options
  String _selectedQuality = 'Voice (Default)';
  String _selectedStorage = 'Temp Directory';

  final Map<String, RecorderConfig> _qualityPresets = {
    'Voice (Default)': RecorderConfig.voice(),
    'Low Quality': RecorderConfig.lowQuality(),
    'Medium Quality': RecorderConfig.mediumQuality(),
    'High Quality': RecorderConfig.highQuality(),
  };

  @override
  void initState() {
    super.initState();
    _recorder = VoiceRecorder(
      onStateChanged: (state) => setState(() => _state = state),
    );
    _recorder.initialize();
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    // Get selected quality config
    final config = _qualityPresets[_selectedQuality];
    
    // Get selected storage config
    StorageConfig? storageConfig;
    switch (_selectedStorage) {
      case 'Temp Directory':
        storageConfig = null; // Default
        break;
      case 'Visible Storage':
        storageConfig = StorageConfig.visible();
        break;
      case 'Custom Path':
        storageConfig = StorageConfig.withDirectory('/custom/recordings');
        break;
    }
    
    // Start with selected options
    await _recorder.start(
      config: config,
      storageConfig: storageConfig,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example 2: Customization'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Quality selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Audio Quality',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._qualityPresets.keys.map((quality) => RadioListTile<String>(
                          title: Text(quality),
                          subtitle: Text(_getQualityDescription(quality)),
                          value: quality,
                          groupValue: _selectedQuality,
                          onChanged: _state == RecordingState.idle
                              ? (value) => setState(() => _selectedQuality = value!)
                              : null,
                        )),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Storage selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Storage Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RadioListTile<String>(
                          title: const Text('Temp Directory'),
                          subtitle: const Text('Temporary storage (auto-cleaned)'),
                          value: 'Temp Directory',
                          groupValue: _selectedStorage,
                          onChanged: _state == RecordingState.idle
                              ? (value) => setState(() => _selectedStorage = value!)
                              : null,
                        ),
                        RadioListTile<String>(
                          title: const Text('Visible Storage'),
                          subtitle: const Text('Visible in file manager'),
                          value: 'Visible Storage',
                          groupValue: _selectedStorage,
                          onChanged: _state == RecordingState.idle
                              ? (value) => setState(() => _selectedStorage = value!)
                              : null,
                        ),
                        RadioListTile<String>(
                          title: const Text('Custom Path'),
                          subtitle: const Text('Custom directory path'),
                          value: 'Custom Path',
                          groupValue: _selectedStorage,
                          onChanged: _state == RecordingState.idle
                              ? (value) => setState(() => _selectedStorage = value!)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What you learn:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('• Use quality presets'),
                      Text('• Configure storage location'),
                      Text('• Customize recording settings'),
                      Text('• Pass config to start()'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Control buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_state == RecordingState.idle)
                  ElevatedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.fiber_manual_record),
                    label: const Text('Start with Settings'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                if (_state == RecordingState.recording)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final recording = await _recorder.stop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Saved with $_selectedQuality\n'
                              'Location: $_selectedStorage\n'
                              'Size: ${(recording.sizeInBytes / 1024).toStringAsFixed(1)} KB',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getQualityDescription(String quality) {
    switch (quality) {
      case 'Voice (Default)':
        return 'Optimized for voice (64 kbps)';
      case 'Low Quality':
        return 'Smallest file size (64 kbps)';
      case 'Medium Quality':
        return 'Balanced quality (128 kbps)';
      case 'High Quality':
        return 'Best quality (256 kbps)';
      default:
        return '';
    }
  }
}
