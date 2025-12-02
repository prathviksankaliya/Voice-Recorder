import 'package:flutter/material.dart';
import 'package:voice_recorder/voice_recorder.dart';

/// Example 3: Wave Visualization
/// 
/// This example shows how to use the AudioWaveWidget:
/// - Default wave widget
/// - Customized colors and styles
/// - Wave presets
class WaveVisualization extends StatefulWidget {
  const WaveVisualization({super.key});

  @override
  State<WaveVisualization> createState() => _WaveVisualizationState();
}

class _WaveVisualizationState extends State<WaveVisualization> {
  late VoiceRecorder _recorder;
  RecordingState _state = RecordingState.idle;
  String _selectedPreset = 'Modern';

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

  WaveConfig _getWaveConfig() {
    switch (_selectedPreset) {
      case 'Minimal':
        return WaveConfig.minimal();
      case 'Standard':
        return WaveConfig.standard();
      case 'Modern':
        return WaveConfig.modern();
      case 'Custom':
        return WaveConfig(
          waveColor: Colors.purple,
          inactiveColor: Colors.grey.shade300,
          height: 100,
          barWidth: 4,
          barSpacing: 3,
          style: WaveStyle.rounded,
          barBorderRadius: BorderRadius.circular(4),
        );
      default:
        return WaveConfig.standard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example 3: Wave Visualization'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          
          // Wave widget
          Padding(
            padding: const EdgeInsets.all(16),
            child: AudioWaveWidget(
              amplitudeStream: _recorder.amplitudeStream.map((amp) => amp.current),
              recordingState: _state,
              config: _getWaveConfig(),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Preset selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Minimal', label: Text('Minimal')),
                ButtonSegment(value: 'Standard', label: Text('Standard')),
                ButtonSegment(value: 'Modern', label: Text('Modern')),
                ButtonSegment(value: 'Custom', label: Text('Custom')),
              ],
              selected: {_selectedPreset},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() => _selectedPreset = newSelection.first);
              },
            ),
          ),
          
          const Spacer(),
          
          // Info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
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
                Text('• Use AudioWaveWidget'),
                Text('• Apply wave presets'),
                Text('• Customize colors and styles'),
                Text('• Add decorations'),
              ],
            ),
          ),
          
          // Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_state == RecordingState.idle)
                  ElevatedButton.icon(
                    onPressed: () => _recorder.start(),
                    icon: const Icon(Icons.fiber_manual_record),
                    label: const Text('Start Recording'),
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
                    onPressed: () => _recorder.stop(),
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
}
