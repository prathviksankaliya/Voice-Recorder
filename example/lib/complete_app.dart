import 'package:flutter/material.dart';
import 'package:voice_recorder/voice_recorder.dart';

/// Example 4: Complete App
///
/// This example demonstrates ALL features of the VoiceRecorder package:
/// - Recording controls (start, stop, pause, resume, restart, delete)
/// - Real-time wave visualization
/// - Duration tracking with HH:MM:SS format
/// - Amplitude monitoring
/// - Error handling
/// - Interruption handling (phone calls, headphones, etc.)
/// - Background recording support
/// - Recording history
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
  String? _filePath;
  String? _errorMessage;
  double _currentAmplitude = 0.0;
  int _fileSize = 0;
  
  // Interruption tracking
  final List<InterruptionData> _interruptionLog = [];
  InterruptionData? _currentInterruption;
  
  // Recording history
  final List<Recording> _recordingHistory = [];
  
  // Settings
  bool _backgroundRecordingEnabled = true;
  bool _showAdvancedSettings = false;

  @override
  void initState() {
    super.initState();
    _recorder = VoiceRecorder(
      onStateChanged: (state) {
        setState(() {
          _state = state;
          _fileName = _recorder.currentRecordingFileName;
          _filePath = _recorder.currentRecordingFullPath;
        });
      },
      onError: (error) {
        setState(() => _errorMessage = error.message);
        _showErrorDialog(error.message);
      },
      onInterruption: (interruption) {
        setState(() {
          _currentInterruption = interruption;
          _interruptionLog.add(interruption);
        });
        _showInterruptionSnackBar(interruption);
      },
    );

    _recorder.initialize();

    // Listen to duration updates
    _recorder.durationStream.listen((duration) {
      setState(() => _duration = duration);
    });

    // Listen to amplitude updates for visualization
    _recorder.amplitudeStream.listen((amplitude) {
      setState(() {
        _currentAmplitude = amplitude.current;
      });
    });
  }

  @override
  void dispose() {
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
        backgroundColor: interruption.isInterrupted ? Colors.orange : Colors.green,
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
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() => _showAdvancedSettings = !_showAdvancedSettings);
            },
          ),
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
            if (_errorMessage != null) _buildErrorBanner(),

            // Current interruption alert
            if (_currentInterruption?.isInterrupted == true)
              _buildInterruptionAlert(),

            const SizedBox(height: 16),

            // Status Dashboard
            _buildStatusDashboard(),

            const SizedBox(height: 20),

            // Wave visualization with fixed stream handling
            _buildWaveVisualization(),

            const SizedBox(height: 24),

            // Duration display (HH:MM:SS format)
            if (_state == RecordingState.recording ||
                _state == RecordingState.paused)
              _buildDurationDisplay(),

            const SizedBox(height: 16),

            // Amplitude meter
            if (_state == RecordingState.recording)
              _buildAmplitudeMeter(),

            const SizedBox(height: 16),

            // Advanced settings panel
            if (_showAdvancedSettings) _buildAdvancedSettings(),

            const SizedBox(height: 16),

            // Control buttons
            _buildControlButtons(),

            const SizedBox(height: 16),

            // Interruption log
            if (_interruptionLog.isNotEmpty) _buildInterruptionLog(),

            // Recording history
            if (_recordingHistory.isNotEmpty) _buildRecordingHistory(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Error banner widget
  Widget _buildErrorBanner() {
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
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.red),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  /// Current interruption alert
  Widget _buildInterruptionAlert() {
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
                  'Recording Interrupted: ${_currentInterruption!.type.name}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Time: ${_formatDuration(DateTime.now().difference(_currentInterruption!.timestamp))}',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                  ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStateColor().withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStateColor(), width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getStateIcon(), size: 16, color: _getStateColor()),
                      const SizedBox(width: 4),
                      Text(
                        _state.name.toUpperCase(),
                        style: TextStyle(
                          color: _getStateColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (_backgroundRecordingEnabled && _state == RecordingState.recording)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_queue, size: 14, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'BG',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            if (_fileName != null) ...[
              const Divider(height: 24),
              _buildInfoRow(Icons.insert_drive_file, 'File', _fileName!),
            ],
            
            if (_filePath != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.folder_open, 'Path', _filePath!, isPath: true),
            ],
            
            if (_state != RecordingState.idle) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.timer,
                'Duration',
                _formatDuration(_duration),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Info row helper
  Widget _buildInfoRow(IconData icon, String label, String value, {bool isPath = false}) {
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

  /// Wave visualization with proper stream handling
  Widget _buildWaveVisualization() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AudioWaveWidget(
        // Fixed: Properly handle the amplitude stream
        amplitudeStream: _recorder.amplitudeStream.map((amp) => amp.current),
        recordingState: _state,
        config: WaveConfig(
          height: 120.0,
          barWidth: 5.0,
          barSpacing: 4.0,
          barCount: 50,
          minBarHeight: 8.0,
          waveColor: _getStateColor(),
          inactiveColor: Colors.grey.shade300,
          style: WaveStyle.rounded,
          barBorderRadius: BorderRadius.circular(4.0),
          alignment: WaveAlignment.center,
          animationDuration: const Duration(milliseconds: 150),
          animationCurve: Curves.easeInOut,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _getStateColor().withOpacity(0.1),
              _getStateColor().withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getStateColor().withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: _getStateColor().withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
      ),
    );
  }

  /// Duration display with HH:MM:SS format
  Widget _buildDurationDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: _getStateColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStateColor().withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            _formatDuration(_duration),
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: _getStateColor(),
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 4,
            ),
          ),
          Text(
            _state == RecordingState.paused ? 'PAUSED' : 'RECORDING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getStateColor(),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  /// Amplitude meter
  Widget _buildAmplitudeMeter() {
    final normalizedAmplitude = (_currentAmplitude + 160) / 160; // Normalize -160 to 0 dB
    final clampedAmplitude = normalizedAmplitude.clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.graphic_eq, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Audio Level',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentAmplitude.toStringAsFixed(1)} dB',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: clampedAmplitude,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    clampedAmplitude > 0.8
                        ? Colors.red
                        : clampedAmplitude > 0.5
                            ? Colors.orange
                            : Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Advanced settings panel
  Widget _buildAdvancedSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.tune, size: 20),
                SizedBox(width: 8),
                Text(
                  'Advanced Settings',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 24),
            SwitchListTile(
              title: const Text('Background Recording'),
              subtitle: const Text('Continue recording when app is in background'),
              value: _backgroundRecordingEnabled,
              onChanged: (value) {
                setState(() => _backgroundRecordingEnabled = value);
              },
              secondary: const Icon(Icons.cloud_queue),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.high_quality),
              title: const Text('Audio Quality'),
              subtitle: const Text('Voice optimized (default)'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Show quality selector dialog
                _showQualityDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Control buttons section
  Widget _buildControlButtons() {
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
          if (_state == RecordingState.idle)
            _buildControlButton(
              icon: Icons.fiber_manual_record,
              label: 'Start',
              color: Colors.red,
              onPressed: () => _startRecording(),
            ),
          
          // Pause button
          if (_state == RecordingState.recording)
            _buildControlButton(
              icon: Icons.pause,
              label: 'Pause',
              color: Colors.orange,
              onPressed: () => _recorder.pause(),
            ),
          
          // Resume button
          if (_state == RecordingState.paused)
            _buildControlButton(
              icon: Icons.play_arrow,
              label: 'Resume',
              color: Colors.green,
              onPressed: () => _recorder.resume(),
            ),
          
          // Stop button
          if (_state == RecordingState.recording || _state == RecordingState.paused)
            _buildControlButton(
              icon: Icons.stop,
              label: 'Stop',
              color: Colors.green,
              onPressed: () => _stopRecording(),
            ),
          
          // Restart button
          if (_state == RecordingState.recording || _state == RecordingState.paused)
            _buildControlButton(
              icon: Icons.refresh,
              label: 'Restart',
              color: Colors.blue,
              onPressed: () => _restartRecording(),
            ),
          
          // Delete button
          if (_state != RecordingState.idle)
            _buildControlButton(
              icon: Icons.delete,
              label: 'Delete',
              color: Colors.grey,
              onPressed: () => _deleteRecording(),
            ),
        ],
      ),
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
  Widget _buildInterruptionLog() {
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
                  onPressed: () => setState(() => _interruptionLog.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const Divider(height: 16),
            ..._interruptionLog.reversed.take(5).map((interruption) {
              return ListTile(
                dense: true,
                leading: Icon(
                  interruption.isInterrupted ? Icons.warning_amber : Icons.check_circle,
                  color: interruption.isInterrupted ? Colors.orange : Colors.green,
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
                    color: interruption.isInterrupted ? Colors.orange : Colors.green,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Recording history
  Widget _buildRecordingHistory() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.library_music, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Recording History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Text(
                  '${_recordingHistory.length} recordings',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 16),
            ..._recordingHistory.reversed.take(5).map((recording) {
              return ListTile(
                dense: true,
                leading: const Icon(Icons.audiotrack, color: Colors.blue),
                title: Text(
                  recording.path.split('/').last,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Duration: ${_formatDuration(recording.duration)} • '
                  'Size: ${(recording.sizeInBytes / 1024).toStringAsFixed(1)} KB',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  '${recording.timestamp.hour}:${recording.timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12),
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
            serviceConfig: _backgroundRecordingEnabled
                ? AndroidServiceConfig(
                    title: "Audio Recorder",
                    content: "Recording in progress...",
                    icon: "ic_launcher",
                  )
                : null,
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
                '• Switching to another app',
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

  /// Show quality selector dialog
  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audio Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Voice (Default)'),
              subtitle: const Text('Optimized for voice recording'),
              leading: const Icon(Icons.mic),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('High Quality'),
              subtitle: const Text('Better quality, larger file size'),
              leading: const Icon(Icons.high_quality),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Custom'),
              subtitle: const Text('Configure manually'),
              leading: const Icon(Icons.tune),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Get state color
  Color _getStateColor() {
    switch (_state) {
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
  IconData _getStateIcon() {
    switch (_state) {
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
