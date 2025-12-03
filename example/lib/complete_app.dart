import 'package:flutter/material.dart';
import 'package:voice_recorder/voice_recorder.dart';

/// Example 4: Complete App (Optimized with ValueNotifier)
///
/// This example demonstrates ALL features of the VoiceRecorder package:
/// - Recording controls (start, stop, pause, resume, restart, delete)
/// - Real-time wave visualization (optimized with isolated widget)
/// - Duration tracking with HH:MM:SS format
/// - Amplitude monitoring
/// - Error handling
/// - Interruption handling (phone calls, headphones, etc.)
/// - Background recording support
/// - Recording history
/// - Customization options
///
/// Performance Optimizations:
/// - ValueNotifier for efficient state management
/// - Isolated wave widget to prevent unnecessary rebuilds
/// - RepaintBoundary for wave visualization
/// - ValueListenableBuilder to minimize widget rebuilds
class CompleteApp extends StatefulWidget {
  const CompleteApp({super.key});

  @override
  State<CompleteApp> createState() => _CompleteAppState();
}

class _CompleteAppState extends State<CompleteApp> {
  late VoiceRecorder _recorder;
  
  // ValueNotifiers for efficient state management
  final ValueNotifier<RecordingState> _stateNotifier = 
      ValueNotifier(RecordingState.idle);
  final ValueNotifier<Duration> _durationNotifier = 
      ValueNotifier(Duration.zero);
  final ValueNotifier<String?> _fileNameNotifier = ValueNotifier(null);
  final ValueNotifier<String?> _filePathNotifier = ValueNotifier(null);
  final ValueNotifier<String?> _errorMessageNotifier = ValueNotifier(null);
  final ValueNotifier<InterruptionData?> _currentInterruptionNotifier = 
      ValueNotifier(null);
  final ValueNotifier<List<InterruptionData>> _interruptionLogNotifier = 
      ValueNotifier([]);

  // Recording history
  final List<Recording> _recordingHistory = [];

  @override
  void initState() {
    super.initState();
    _recorder = VoiceRecorder(
      onStateChanged: (state) {
        _stateNotifier.value = state;
        _fileNameNotifier.value = _recorder.currentRecordingFileName;
        _filePathNotifier.value = _recorder.currentRecordingFullPath;
      },
      onError: (error) {
        _errorMessageNotifier.value = error.message;
        _showErrorDialog(error.message);
      },
      onInterruption: (interruption) {
        _currentInterruptionNotifier.value = interruption;
        _interruptionLogNotifier.value = [
          ..._interruptionLogNotifier.value,
          interruption
        ];
        _showInterruptionSnackBar(interruption);
      },
    );

    _recorder.initialize();

    // Listen to duration updates without setState
    _recorder.durationStream.listen((duration) {
      _durationNotifier.value = duration;
    });
  }

  @override
  void dispose() {
    _stateNotifier.dispose();
    _durationNotifier.dispose();
    _fileNameNotifier.dispose();
    _filePathNotifier.dispose();
    _errorMessageNotifier.dispose();
    _currentInterruptionNotifier.dispose();
    _interruptionLogNotifier.dispose();
    _recorder.dispose();
    super.dispose();
  }

  /// Format duration as HH:MM:SS
  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show interruption snackbar
  void _showInterruptionSnackBar(InterruptionData interruption) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Interrupted: ${interruption.type.name}\n'
                '${interruption.isInterrupted ? "Recording paused" : "Interruption ended"}',
              ),
            ),
          ],
        ),
        backgroundColor: interruption.isInterrupted
            ? Colors.orange
            : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete App - All Features'),
        actions: [
          // Info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Error banner
            ValueListenableBuilder<String?>(
              valueListenable: _errorMessageNotifier,
              builder: (context, errorMessage, child) {
                if (errorMessage == null) return const SizedBox.shrink();
                return _buildErrorBanner(errorMessage);
              },
            ),

            // Current interruption alert
            ValueListenableBuilder<InterruptionData?>(
              valueListenable: _currentInterruptionNotifier,
              builder: (context, interruption, child) {
                if (interruption?.isInterrupted != true) {
                  return const SizedBox.shrink();
                }
                return _buildInterruptionAlert(interruption!);
              },
            ),

            const SizedBox(height: 16),

            // Status Dashboard
            _buildStatusDashboard(),

            const SizedBox(height: 20),

            // Wave visualization - isolated with RepaintBoundary
            RepaintBoundary(
              child: _IsolatedWaveWidget(
                recorder: _recorder,
                stateNotifier: _stateNotifier,
              ),
            ),

            const SizedBox(height: 24),

            // Duration display (HH:MM:SS format)
            ValueListenableBuilder<RecordingState>(
              valueListenable: _stateNotifier,
              builder: (context, state, child) {
                if (state != RecordingState.recording &&
                    state != RecordingState.paused) {
                  return const SizedBox.shrink();
                }
                return _buildDurationDisplay();
              },
            ),

            const SizedBox(height: 16),

            // Control buttons
            _buildControlButtons(),

            const SizedBox(height: 16),

            // Interruption log
            ValueListenableBuilder<List<InterruptionData>>(
              valueListenable: _interruptionLogNotifier,
              builder: (context, log, child) {
                if (log.isEmpty) return const SizedBox.shrink();
                return _buildInterruptionLog(log);
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Error banner widget
  Widget _buildErrorBanner(String errorMessage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.red.shade100,
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.red),
            onPressed: () => _errorMessageNotifier.value = null,
          ),
        ],
      ),
    );
  }

  /// Current interruption alert
  Widget _buildInterruptionAlert(InterruptionData interruption) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recording Interrupted: ${interruption.type.name}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Time: ${_formatDuration(DateTime.now().difference(interruption.timestamp))}',
                  style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Status dashboard card
  Widget _buildStatusDashboard() {
    return ValueListenableBuilder<RecordingState>(
      valueListenable: _stateNotifier,
      builder: (context, state, child) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // State indicator
                Row(
                  children: [
                    const Text(
                      'State: ',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStateColor(state).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStateColor(state), width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getStateIcon(state), size: 16, color: _getStateColor(state)),
                          const SizedBox(width: 4),
                          Text(
                            state.name.toUpperCase(),
                            style: TextStyle(
                              color: _getStateColor(state),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                ValueListenableBuilder<String?>(
                  valueListenable: _fileNameNotifier,
                  builder: (context, fileName, child) {
                    if (fileName == null) return const SizedBox.shrink();
                    return Column(
                      children: [
                        const Divider(height: 24),
                        _buildInfoRow(Icons.insert_drive_file, 'File', fileName),
                      ],
                    );
                  },
                ),

                ValueListenableBuilder<String?>(
                  valueListenable: _filePathNotifier,
                  builder: (context, filePath, child) {
                    if (filePath == null) return const SizedBox.shrink();
                    return Column(
                      children: [
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.folder_open,
                          'Path',
                          filePath,
                          isPath: true,
                        ),
                      ],
                    );
                  },
                ),

                if (state != RecordingState.idle)
                  ValueListenableBuilder<Duration>(
                    valueListenable: _durationNotifier,
                    builder: (context, duration, child) {
                      return Column(
                        children: [
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.timer,
                            'Duration',
                            _formatDuration(duration),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Info row helper
  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isPath = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            overflow: isPath ? TextOverflow.ellipsis : TextOverflow.visible,
            maxLines: isPath ? 1 : null,
          ),
        ),
      ],
    );
  }

  /// Duration display with HH:MM:SS format
  Widget _buildDurationDisplay() {
    return ValueListenableBuilder<RecordingState>(
      valueListenable: _stateNotifier,
      builder: (context, state, child) {
        return ValueListenableBuilder<Duration>(
          valueListenable: _durationNotifier,
          builder: (context, duration, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: _getStateColor(state).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getStateColor(state).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: _getStateColor(state),
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    state == RecordingState.paused ? 'PAUSED' : 'RECORDING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStateColor(state),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Control buttons section
  Widget _buildControlButtons() {
    return ValueListenableBuilder<RecordingState>(
      valueListenable: _stateNotifier,
      builder: (context, state, child) {
        return Container(
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
              // Start button
              if (state == RecordingState.idle)
                _buildControlButton(
                  icon: Icons.fiber_manual_record,
                  label: 'Start',
                  color: Colors.red,
                  onPressed: () => _startRecording(),
                ),

              // Pause button
              if (state == RecordingState.recording)
                _buildControlButton(
                  icon: Icons.pause,
                  label: 'Pause',
                  color: Colors.orange,
                  onPressed: () => _recorder.pause(),
                ),

              // Resume button
              if (state == RecordingState.paused)
                _buildControlButton(
                  icon: Icons.play_arrow,
                  label: 'Resume',
                  color: Colors.green,
                  onPressed: () => _recorder.resume(),
                ),

              // Stop button
              if (state == RecordingState.recording ||
                  state == RecordingState.paused)
                _buildControlButton(
                  icon: Icons.stop,
                  label: 'Stop',
                  color: Colors.green,
                  onPressed: () => _stopRecording(),
                ),

              // Restart button
              if (state == RecordingState.recording ||
                  state == RecordingState.paused)
                _buildControlButton(
                  icon: Icons.refresh,
                  label: 'Restart',
                  color: Colors.blue,
                  onPressed: () => _restartRecording(),
                ),

              // Delete button
              if (state != RecordingState.idle)
                _buildControlButton(
                  icon: Icons.delete,
                  label: 'Delete',
                  color: Colors.grey,
                  onPressed: () => _deleteRecording(),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Control button helper
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }

  /// Interruption log
  Widget _buildInterruptionLog(List<InterruptionData> log) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Interruption Log',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _interruptionLogNotifier.value = [],
                  child: const Text('Clear'),
                ),
              ],
            ),
            const Divider(height: 16),
            ...log.reversed.take(5).map((interruption) {
              return ListTile(
                dense: true,
                leading: Icon(
                  interruption.isInterrupted
                      ? Icons.warning_amber
                      : Icons.check_circle,
                  color: interruption.isInterrupted
                      ? Colors.orange
                      : Colors.green,
                  size: 20,
                ),
                title: Text(
                  interruption.type.name,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  '${interruption.timestamp.hour}:${interruption.timestamp.minute}:${interruption.timestamp.second}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  interruption.isInterrupted ? 'Started' : 'Ended',
                  style: TextStyle(
                    fontSize: 12,
                    color: interruption.isInterrupted
                        ? Colors.orange
                        : Colors.green,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Start recording with configuration
  Future<void> _startRecording() async {
    try {
      await _recorder.start(
        config: RecorderConfig(
          androidConfig: AndroidRecorderConfig(
            serviceConfig: AndroidServiceConfig(
              title: "Audio Recorder",
              content: "Recording in progress...",
            ),
          ),
        ),
        storageConfig: StorageConfig.visible(),
      );
    } catch (e) {
      // Error handled by onError callback
    }
  }

  /// Stop recording and save to history
  Future<void> _stopRecording() async {
    try {
      final recording = await _recorder.stop();
      setState(() {
        _recordingHistory.add(recording);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Recording saved!\n'
              'Duration: ${_formatDuration(recording.duration)}\n'
              'Size: ${(recording.sizeInBytes / 1024).toStringAsFixed(1)} KB',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Could open file location or play recording
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Error handled by onError callback
    }
  }

  /// Restart recording
  Future<void> _restartRecording() async {
    try {
      await _recorder.restart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording restarted from beginning'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Error handled by onError callback
    }
  }

  /// Delete recording
  Future<void> _deleteRecording() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _recorder.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording deleted'),
              backgroundColor: Colors.grey,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // Error handled by onError callback
      }
    }
  }

  /// Show info dialog
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Complete App Features'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This example demonstrates ALL features:\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('✓ Start, Stop, Pause, Resume'),
              Text('✓ Restart recording'),
              Text('✓ Delete recording'),
              Text('✓ Real-time wave visualization'),
              Text('✓ Duration tracking (HH:MM:SS)'),
              Text('✓ Amplitude monitoring'),
              Text('✓ Error handling'),
              Text('✓ Interruption handling'),
              Text('✓ Background recording'),
              Text('✓ Recording history'),
              Text('✓ Interruption log'),
              Text('✓ Advanced settings'),
              SizedBox(height: 12),
              Text(
                'Try interrupting the recording by:\n'
                '• Receiving a phone call\n'
                '• Disconnecting headphones\n'
                '• Play audio into another app',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  /// Get state color
  Color _getStateColor(RecordingState state) {
    switch (state) {
      case RecordingState.recording:
        return Colors.red;
      case RecordingState.paused:
        return Colors.orange;
      case RecordingState.stopped:
        return Colors.green;
      case RecordingState.idle:
        return Colors.blue;
    }
  }

  /// Get state icon
  IconData _getStateIcon(RecordingState state) {
    switch (state) {
      case RecordingState.recording:
        return Icons.fiber_manual_record;
      case RecordingState.paused:
        return Icons.pause;
      case RecordingState.stopped:
        return Icons.stop;
      case RecordingState.idle:
        return Icons.mic_none;
    }
  }
}

/// Isolated Wave Widget - prevents rebuilds from parent state changes
/// 
/// This widget is isolated to ensure that wave visualization only rebuilds
/// when the recording state changes, not when other parts of the UI update
/// (like duration, file info, etc.). This dramatically improves performance.
class _IsolatedWaveWidget extends StatelessWidget {
  final VoiceRecorder recorder;
  final ValueNotifier<RecordingState> stateNotifier;

  const _IsolatedWaveWidget({
    required this.recorder,
    required this.stateNotifier,
  });

  Color _getStateColor(RecordingState state) {
    switch (state) {
      case RecordingState.recording:
        return Colors.red;
      case RecordingState.paused:
        return Colors.orange;
      case RecordingState.stopped:
        return Colors.green;
      case RecordingState.idle:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RecordingState>(
      valueListenable: stateNotifier,
      builder: (context, state, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getStateColor(state).withOpacity(0.1),
                    _getStateColor(state).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _getStateColor(state).withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getStateColor(state).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AudioWaveWidget(
                  amplitudeStream: recorder.amplitudeStream.map((amp) => amp.current),
                  recordingState: state,
                  config: WaveConfig(
                    height: 100.0,
                    barWidth: 4.0,
                    barSpacing: 3.0,
                    barCount: 60,
                    minBarHeight: 6.0,
                    waveColor: Colors.blue,
                    inactiveColor: Colors.grey.shade300,
                    style: WaveStyle.rounded,
                    barBorderRadius: BorderRadius.circular(4.0),
                    alignment: WaveAlignment.center,
                    animationDuration: const Duration(milliseconds: 100),
                    animationCurve: Curves.easeInOutCubic,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
