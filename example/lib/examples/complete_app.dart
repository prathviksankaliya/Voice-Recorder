import 'package:flutter/material.dart';
import 'package:voice_recorder/voice_recorder.dart';

/// Example 4: Complete App
/// 
/// This example combines all features:
/// - Recording controls (start, pause, resume, stop)
/// - Wave visualization
/// - Duration tracking
/// - Error handling
/// - Customization options
class CompleteApp extends StatefulWidget {
  const CompleteApp({super.key});

  @override
  State<CompleteApp> createState() => _CompleteAppState();
}

class _CompleteAppState extends State<CompleteApp> {
  late VoiceRecorder _recorder;
  RecordingState _state = RecordingState.idle;
  Duration _duration = Duration.zero;
  String? _fileName;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _recorder = VoiceRecorder(
      onStateChanged: (state) {
        setState(() {
          _state = state;
          _fileName = _recorder.currentRecordingFileName;
        });
      },
      onError: (error) {
        setState(() => _errorMessage = error.message);
      },
      onInterruption: (interruption) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Interrupted: ${interruption.type.name}'),
            backgroundColor: Colors.orange,
          ),
        );
      },
    );
    
    _recorder.initialize();
    
    _recorder.durationStream.listen((duration) {
      setState(() => _duration = duration);
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example 4: Complete App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Complete App'),
                  content: const Text(
                    'This example combines:\n\n'
                    '• All recording controls\n'
                    '• Wave visualization\n'
                    '• Duration tracking\n'
                    '• Error handling\n'
                    '• Interruption handling\n'
                    '• File metadata',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Error display
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _errorMessage = null),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Wave visualization
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AudioWaveWidget(
              amplitudeStream: _recorder.amplitudeStream.map((amp) => amp.current),
              recordingState: _state,
              config: WaveConfig.modern(),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.purple.shade50],
                ),
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
          
          const SizedBox(height: 24),
          
          // Duration display
          if (_state == RecordingState.recording || _state == RecordingState.paused)
            Text(
              _formatDuration(_duration),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Info card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'State: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStateColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _state.name.toUpperCase(),
                          style: TextStyle(
                            color: _getStateColor(),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_fileName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'File: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Expanded(
                          child: Text(
                            _fileName!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
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
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (_state == RecordingState.idle)
                  ElevatedButton.icon(
                    onPressed: () => _recorder.start(
                      config: RecorderConfig.voice(),
                      storageConfig: StorageConfig.visible(),
                    ),
                    icon: const Icon(Icons.fiber_manual_record),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (_state == RecordingState.recording)
                  ElevatedButton.icon(
                    onPressed: () => _recorder.pause(),
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),
                if (_state == RecordingState.paused)
                  ElevatedButton.icon(
                    onPressed: () => _recorder.resume(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  ),
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
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (_state != RecordingState.idle)
                  ElevatedButton.icon(
                    onPressed: () => _recorder.delete(),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ],
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
