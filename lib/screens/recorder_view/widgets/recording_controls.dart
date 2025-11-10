import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/enums/enums.dart';
import '../provider/recording_provider.dart';

/// Recording control buttons widget
/// 
/// Displays control buttons based on current recording state:
/// - Idle: Start button
/// - Recording: Pause, Stop, Restart buttons
/// - Paused: Resume, Stop, Delete buttons
/// - Stopped: Start, Delete buttons
class RecordingControls extends StatelessWidget {
  const RecordingControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordingProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildControlsForState(context, provider),
        );
      },
    );
  }

  /// Builds controls based on current recording state
  Widget _buildControlsForState(
    BuildContext context,
    RecordingProvider provider,
  ) {
    switch (provider.recordingState) {
      case RecordingState.idle:
        return _buildIdleControls(context, provider);
      
      case RecordingState.recording:
        return _buildRecordingControls(context, provider);
      
      case RecordingState.paused:
        return _buildPausedControls(context, provider);
      
      case RecordingState.stopped:
        return _buildStoppedControls(context, provider);
    }
  }

  /// Controls when idle (not recording)
  Widget _buildIdleControls(
    BuildContext context,
    RecordingProvider provider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Start button
        _buildLargeButton(
          context: context,
          icon: Icons.mic,
          label: 'Start Recording',
          color: Colors.red,
          onPressed: () => provider.startRecording(),
        ),
      ],
    );
  }

  /// Controls when recording
  Widget _buildRecordingControls(
    BuildContext context,
    RecordingProvider provider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Pause button
        _buildSmallButton(
          context: context,
          icon: Icons.pause,
          label: 'Pause',
          onPressed: () => provider.pauseRecording(),
        ),
        
        // Stop button
        _buildLargeButton(
          context: context,
          icon: Icons.stop,
          label: 'Stop',
          color: Colors.red,
          onPressed: () async {
            final result = await provider.stopRecording();
            if (result != null && context.mounted) {
              _showRecordingSavedDialog(context, result.$1.path);
            }
          },
        ),
        
        // Restart button
        _buildSmallButton(
          context: context,
          icon: Icons.refresh,
          label: 'Restart',
          onPressed: () => provider.restartRecording(),
        ),
      ],
    );
  }

  /// Controls when paused
  Widget _buildPausedControls(
    BuildContext context,
    RecordingProvider provider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Delete button
        _buildSmallButton(
          context: context,
          icon: Icons.delete,
          label: 'Delete',
          color: Colors.red,
          onPressed: () => _showDeleteConfirmation(context, provider),
        ),
        
        // Resume button
        _buildLargeButton(
          context: context,
          icon: Icons.play_arrow,
          label: 'Resume',
          color: Colors.green,
          onPressed: () => provider.resumeRecording(),
        ),
        
        // Stop button
        _buildSmallButton(
          context: context,
          icon: Icons.stop,
          label: 'Stop',
          onPressed: () async {
            final result = await provider.stopRecording();
            if (result != null && context.mounted) {
              _showRecordingSavedDialog(context, result.$1.path);
            }
          },
        ),
      ],
    );
  }

  /// Controls when stopped
  Widget _buildStoppedControls(
    BuildContext context,
    RecordingProvider provider,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Delete button
        _buildSmallButton(
          context: context,
          icon: Icons.delete,
          label: 'Delete',
          color: Colors.red,
          onPressed: () => _showDeleteConfirmation(context, provider),
        ),
        
        // Start new button
        _buildLargeButton(
          context: context,
          icon: Icons.mic,
          label: 'New Recording',
          color: Colors.red,
          onPressed: () => provider.startRecording(),
        ),
      ],
    );
  }

  /// Builds a large circular button (primary action)
  Widget _buildLargeButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final buttonColor = color ?? Theme.of(context).colorScheme.primary;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.large(
          onPressed: onPressed,
          backgroundColor: buttonColor,
          child: Icon(icon, size: 36),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }

  /// Builds a small circular button (secondary action)
  Widget _buildSmallButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final buttonColor = color ?? Theme.of(context).colorScheme.secondary;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: buttonColor,
          child: Icon(icon),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  /// Shows confirmation dialog before deleting
  void _showDeleteConfirmation(
    BuildContext context,
    RecordingProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text(
          'Are you sure you want to delete this recording? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteRecording();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Shows dialog when recording is saved
  void _showRecordingSavedDialog(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recording Saved'),
        content: Text('Recording saved successfully!\n\nPath: $path'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
