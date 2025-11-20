import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../provider/recording_provider.dart';

/// Waveform visualizer widget
/// 
/// Displays a live waveform visualization of the audio being recorded.
/// Shows animated amplitude bars that update in real-time based on audio levels.
/// Features smooth animations, gradient colors, and voice synchronization.
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

            return Center(
              child: Container(
                height: 120, // Compact height
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: CustomPaint(
                  painter: WaveformPainter(
                    amplitudes: amplitudes,
                    color: provider.isRecording
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                    isPaused: provider.isPaused,
                  ),
                  size: const Size(double.infinity, 120),
                ),
              ),
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
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
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
/// Draws animated vertical bars representing audio amplitude levels.
/// Each bar's height corresponds to the amplitude value (0.0 to 1.0).
/// Features gradient colors, rounded caps, and smooth animations.
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

    // Center vertically
    final centerY = size.height / 2;
    final maxBarHeight = size.height * 0.4;

    // Calculate optimal bar count and spacing
    final visibleBarCount = math.min(amplitudes.length, 50);
    final barSpacing = 4.0;
    final totalSpacing = barSpacing * (visibleBarCount - 1);
    final availableWidth = size.width - totalSpacing;
    final barWidth = (availableWidth / visibleBarCount).clamp(2.5, 5.0);

    // Get the most recent amplitudes
    final startIndex = math.max(0, amplitudes.length - visibleBarCount);
    final visibleAmplitudes = amplitudes.sublist(startIndex);

    // Draw bars from left to right (oldest to newest)
    for (int i = 0; i < visibleAmplitudes.length; i++) {
      final amplitude = visibleAmplitudes[i];
      
      // Calculate bar height with minimum visibility
      final normalizedAmplitude = amplitude.clamp(0.0, 1.0);
      final barHeight = (normalizedAmplitude * maxBarHeight).clamp(3.0, maxBarHeight);
      
      // Calculate x position (left to right)
      final x = i * (barWidth + barSpacing) + barWidth / 2;
      
      // Simple opacity based on amplitude and pause state
      final opacity = isPaused ? 0.5 : (0.7 + (normalizedAmplitude * 0.3));
      final barColor = color.withOpacity(opacity);

      // Create paint with rounded caps
      final paint = Paint()
        ..color = barColor
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

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
