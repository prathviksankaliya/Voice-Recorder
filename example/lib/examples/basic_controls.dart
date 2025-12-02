import 'package:flutter/material.dart';
import 'package:voice_recorder/voice_recorder.dart';

/// Example 1: Basic Recording Controls
/// 
/// This example shows the simplest way to use the voice recorder:
/// - Start recording
/// - Pause recording
/// - Resume recording
/// - Stop recording
/// - Delete recording
class BasicControls extends StatefulWidget {
  const BasicControls({super.key});

  @override
  State<BasicControls> createState() => _BasicControlsState();
}

class _BasicControlsState extends State<BasicControls> {
  // Create recorder instance
  late VoiceRecorder _recorder;
  
  // Track recording state
  RecordingState _state = RecordingState.idle;
  Duration _duration = Duration.zero;
  String? _fileName;

  @override
  void initState() {
    super.initState();
    
    // Initialize recorder
    _recorder = VoiceRecorder(
      onStateChanged: (state) {
        setState(() {
          _state = state;
          _fileName = _recorder.currentRecordingFileName;
        });
      },
    );
    
    _recorder.initialize();
    
    // Listen to duration updates
    _recorder.durationStream.listen((duration) {
      setState(() => _duration = duration);
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  // Format duration as MM:SS
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example 1: Basic Controls'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // State indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _getStateColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _state.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _getStateColor(),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Duration display (when recording or paused)
            if (_state == RecordingState.recording || _state == RecordingState.paused)
              Text(
                _formatDuration(_duration),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            
            const SizedBox(height: 40),
            
            // File name (when recording)
            if (_fileName != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'File: $_fileName',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            
            const SizedBox(height: 60),
            
            // Control buttons
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                // Start button
                if (_state == RecordingState.idle)
                  ElevatedButton.icon(
                    onPressed: () => _recorder.start(),
                    icon: const Icon(Icons.fiber_manual_record),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                
                // Pause button
                if (_state == RecordingState.recording)
                  ElevatedButton.icon(
                    onPressed: () => _recorder.pause(),
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                
                // Resume button
                if (_state == RecordingState.paused)
                  ElevatedButton.icon(
                    onPressed: () => _recorder.resume(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                
                // Stop button
                if (_state == RecordingState.recording || 
                    _state == RecordingState.paused)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final recording = await _recorder.stop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Recording saved!\n'
                              'Duration: ${recording.duration.inSeconds}s\n'
                              'Size: ${(recording.sizeInBytes / 1024).toStringAsFixed(1)} KB',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                
                // Delete button
                if (_state != RecordingState.idle)
                  ElevatedButton.icon(
                    onPressed: () => _recorder.delete(),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 60),
            
            // Info card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
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
                  Text('• Initialize VoiceRecorder'),
                  Text('• Start/Pause/Resume/Stop recording'),
                  Text('• Track recording state'),
                  Text('• Display duration'),
                  Text('• Delete recording'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStateColor() {
    switch (_state) {
      case RecordingState.recording:
        return Colors.red;
      case RecordingState.paused:
        return Colors.orange;
      case RecordingState.stopped:
        return Colors.green;
      case RecordingState.idle:
        return Colors.grey;
    }
  }
}
