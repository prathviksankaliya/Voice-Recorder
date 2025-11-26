import 'package:flutter/material.dart';
import 'package:voice_recorder/voice_recorder.dart';

void main() {
  runApp(const RecorderExampleApp());
}

class RecorderExampleApp extends StatelessWidget {
  const RecorderExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recorder Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const RecorderExampleScreen(),
    );
  }
}

class RecorderExampleScreen extends StatefulWidget {
  const RecorderExampleScreen({super.key});

  @override
  State<RecorderExampleScreen> createState() => _RecorderExampleScreenState();
}

class _RecorderExampleScreenState extends State<RecorderExampleScreen> {
  late RecorderManager _recorder;
  RecordingState _state = RecordingState.idle;
  String? _errorMessage;
  String? _fileName;
  List<double> _waveform = [];

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  void _initializeRecorder() {
    _recorder = RecorderManager(
      config: RecorderConfig.voice(),
      storageConfig: StorageConfig.visible(),
      onStateChanged: (state) {
        setState(() {
          _state = state;
          _fileName = _recorder.currentRecordingFileName;
        });
      },
      onError: (error) {
        setState(() {
          _errorMessage = error.message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
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

    // Listen to waveform updates
    _recorder.amplitudeStream.listen((amplitude) {
      setState(() {
        _waveform = _recorder.waveformBuffer;
      });
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      await _recorder.startRecording();
    } catch (e) {
      // Error handled by callback
    }
  }

  Future<void> _pauseRecording() async {
    try {
      await _recorder.pauseRecording();
    } catch (e) {
      // Error handled by callback
    }
  }

  Future<void> _resumeRecording() async {
    try {
      await _recorder.resumeRecording();
    } catch (e) {
      // Error handled by callback
    }
  }

  Future<void> _stopRecording() async {
    try {
      final (file, timestamp) = await _recorder.stopRecording();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recording saved: ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Error handled by callback
    }
  }

  Future<void> _deleteRecording() async {
    try {
      await _recorder.deleteRecording();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording deleted'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // Error handled by callback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recorder Example'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Error message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
            ),

          // Waveform visualization
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: _waveform.isEmpty
                    ? Text(
                        'No audio data',
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    : CustomPaint(
                        size: Size(
                          MediaQuery.of(context).size.width - 32,
                          200,
                        ),
                        painter: WaveformPainter(_waveform),
                      ),
              ),
            ),
          ),

          // State indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'State: ${_state.name.toUpperCase()}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (_fileName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'File: $_fileName',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),

          // Controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                if (_state == RecordingState.idle)
                  ElevatedButton.icon(
                    onPressed: _startRecording,
                    icon: const Icon(Icons.fiber_manual_record),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (_state == RecordingState.recording)
                  ElevatedButton.icon(
                    onPressed: _pauseRecording,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  ),
                if (_state == RecordingState.paused)
                  ElevatedButton.icon(
                    onPressed: _resumeRecording,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  ),
                if (_state == RecordingState.recording ||
                    _state == RecordingState.paused)
                  ElevatedButton.icon(
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (_state == RecordingState.recording ||
                    _state == RecordingState.paused ||
                    _state == RecordingState.stopped)
                  ElevatedButton.icon(
                    onPressed: _deleteRecording,
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

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveform;

  WaveformPainter(this.waveform);

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    for (int i = 0; i < waveform.length; i++) {
      final x = (i / waveform.length) * width;
      final y = centerY + (waveform[i] * centerY);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.waveform != waveform;
  }
}
