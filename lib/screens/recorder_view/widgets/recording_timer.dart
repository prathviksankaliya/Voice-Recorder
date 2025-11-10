import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/recording_provider.dart';

/// Recording timer widget
/// 
/// Displays the current recording duration in MM:SS format.
/// Updates every second while recording.
class RecordingTimer extends StatelessWidget {
  const RecordingTimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordingProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: provider.isRecording
                ? Colors.red.withOpacity(0.1)
                : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recording indicator
              if (provider.isRecording)
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              
              // Timer text
              Text(
                provider.formattedDuration,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
              
              // State label
              if (provider.isPaused) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'PAUSED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
