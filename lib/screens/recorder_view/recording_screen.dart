import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/permission_helper.dart';
import 'provider/recording_provider.dart';
import 'widgets/recording_controls.dart';
import 'widgets/recording_timer.dart';
import 'widgets/waveform_visualizer.dart';

/// Main recording screen
/// 
/// Displays the recording interface with:
/// - Waveform visualization
/// - Recording timer
/// - Control buttons (start, pause, resume, stop, restart, delete)
/// - Permission handling
/// - Error messages
class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool _isInitializing = true;
  bool _hasPermissions = false;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  /// Initializes the recorder and checks permissions
  Future<void> _initializeRecorder() async {
    // Check permissions first
    final hasPermissions = await PermissionHelper.checkRecordingPermissions();
    
    if (!hasPermissions) {
      // Request permissions
      final granted = await PermissionHelper.requestRecordingPermissions();
      
      if (!granted) {
        setState(() {
          _hasPermissions = false;
          _isInitializing = false;
        });
        return;
      }
    }

    setState(() {
      _hasPermissions = true;
    });

    // Initialize provider
    if (mounted) {
      final provider = context.read<RecordingProvider>();
      await provider.initialize();
    }

    setState(() {
      _isInitializing = false;
    });
  }

  /// Requests permissions again
  Future<void> _requestPermissions() async {
    final granted = await PermissionHelper.requestRecordingPermissions();
    
    if (granted) {
      setState(() {
        _hasPermissions = true;
      });
      
      // Initialize provider
      if (mounted) {
        final provider = context.read<RecordingProvider>();
        await provider.initialize();
      }
    } else {
      // Show dialog to open settings
      if (mounted) {
        _showPermissionDialog();
      }
    }
  }

  /// Shows dialog to open app settings
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'Microphone permission is required to record audio. '
          'Please grant permission in app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              PermissionHelper.openSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Recorder'),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermissions
              ? _buildPermissionView()
              : _buildRecordingView(),
    );
  }

  /// Builds the permission request view
  Widget _buildPermissionView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_off,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Microphone Permission Required',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This app needs microphone access to record audio.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestPermissions,
              icon: const Icon(Icons.mic),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main recording view
  Widget _buildRecordingView() {
    return Consumer<RecordingProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            // Error message (if any)
            if (provider.errorMessage != null)
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
                        provider.errorMessage ?? '',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => provider.clearInterruption(),
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ],
                ),
              ),

            // Waveform visualizer
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const WaveformVisualizer(),
              ),
            ),

            // Recording timer
            const RecordingTimer(),

            const SizedBox(height: 24),

            // Recording controls
            const RecordingControls(),

            const SizedBox(height: 32),

            // Recording info
            if (provider.currentRecordingFileName != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'File: ${provider.currentRecordingFileName}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
