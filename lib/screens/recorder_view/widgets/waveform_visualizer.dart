import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/recording_provider.dart';

/// Waveform visualizer widget
/// 
/// Displays a live waveform visualization of the audio being recorded.
/// Shows amplitude bars that update in real-time based on audio levels.
class WaveformVisualizer extends StatelessWidget {
  const WaveformVisualizer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordingProvider>(
      builder: (context, provider, child) {
        // Show placeholder when not recording
        if (!provider.isRecording && !provider.isPaused && !provider.hasWaveformData) {
          return _buildPlaceholder(context);
        }

        // Show waveform
        return StreamBuilder<List<double>>(
          stream: provider.waveformStream,
          initialData: provider.waveformBuffer,
          builder: (context, snapshot) {
            final amplitudes = snapshot.data ?? [];
            
            if (amplitudes.isEmpty) {
              return _buildPlaceholder(context);
            }

            return CustomPaint(
              painter: WaveformPainter(
                amplitudes: amplitudes,
                color: provider.isRecording
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
                isPaused: provider.isPaused,
              ),
              size: Size.infinite,
            );
          },
        );
      },
    );
  }

  /// Builds placeholder when no waveform data
  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.graphic_eq,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Start recording to see waveform',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for drawing the waveform
/// 
/// Draws vertical bars representing audio amplitude levels.
/// Each bar's height corresponds to the amplitude value (0.0 to 1.0).
class WaveformPainter extends CustomPainter {
  /// List of amplitude values (0.0 to 1.0)
  final List<double> amplitudes;
  
  /// Color of the waveform bars
  final Color color;
  
  /// Whether the recording is paused
  final bool isPaused;

  WaveformPainter({
    required this.amplitudes,
    required this.color,
    this.isPaused = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..color = isPaused ? color.withOpacity(0.5) : color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Calculate bar width and spacing
    final barCount = amplitudes.length;
    final totalWidth = size.width - 32; // Padding
    final barWidth = (totalWidth / barCount).clamp(2.0, 8.0);

    // Center vertically
    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.8;

    // Draw bars
    for (int i = 0; i < barCount; i++) {
      final amplitude = amplitudes[i];
      
      // Calculate bar height (minimum 4px for visibility)
      final barHeight = (amplitude * maxBarHeight / 2).clamp(4.0, maxBarHeight / 2);
      
      // Calculate x position (right-aligned, newest on right)
      final x = size.width - 16 - (barCount - i) * barWidth;
      
      // Skip if outside visible area
      if (x < 16) continue;

      // Draw bar (centered vertically)
      canvas.drawLine(
        Offset(x, centerY - barHeight),
        Offset(x, centerY + barHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes ||
        oldDelegate.color != color ||
        oldDelegate.isPaused != isPaused;
  }
}
