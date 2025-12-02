import 'package:flutter/material.dart';
import '../config/wave_config.dart';
import '../enums/enums.dart';

/// Custom painter for rendering audio waveforms
/// 
/// Renders amplitude data as visual waves with different styles:
/// - Bars: Vertical bars
/// - Rounded: Rounded vertical bars
/// - Line: Connected line graph
class WavePainter extends CustomPainter {
  /// ValueNotifier of normalized amplitude values (0.0 to 1.0)
  final ValueNotifier<List<double>> amplitudes;
  
  /// Configuration for wave appearance
  final WaveConfig config;
  
  /// Whether currently recording
  final bool isRecording;
  
  /// Whether recording is paused
  final bool isPaused;
  
  /// Animation for smooth transitions
  final Animation<double> animation;
  
  WavePainter({
    required this.amplitudes,
    required this.config,
    required this.isRecording,
    required this.isPaused,
    required this.animation,
  }) : super(repaint: Listenable.merge([animation, amplitudes]));
  
  @override
  void paint(Canvas canvas, Size size) {
    final amplitudeList = amplitudes.value;
    
    if (amplitudeList.isEmpty) {
      _drawEmptyState(canvas, size);
      return;
    }
    
    switch (config.style) {
      case WaveStyle.bars:
        _drawBars(canvas, size, false);
        break;
      case WaveStyle.rounded:
        _drawBars(canvas, size, true);
        break;
      case WaveStyle.line:
        _drawLine(canvas, size);
        break;
    }
  }
  
  /// Draws vertical bars
  void _drawBars(Canvas canvas, Size size, bool rounded) {
    final amplitudeList = amplitudes.value;
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    // Determine color based on state
    final isActive = isRecording && !isPaused;
    
    if (isActive && config.waveGradient != null) {
      paint.shader = config.waveGradient!.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    } else if (!isActive && config.inactiveGradient != null) {
      paint.shader = config.inactiveGradient!.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    } else {
      paint.color = isActive ? config.waveColor : config.inactiveColor;
    }
    
    final barTotalWidth = config.barWidth + config.barSpacing;
    final totalBarsWidth = amplitudeList.length * barTotalWidth - config.barSpacing;
    final startX = (size.width - totalBarsWidth) / 2;
    
    final maxHeight = config.maxBarHeight ?? size.height;
    
    for (int i = 0; i < amplitudeList.length; i++) {
      final amplitude = amplitudeList[i];
      final barHeight = _calculateBarHeight(amplitude, maxHeight);
      
      final x = startX + (i * barTotalWidth);
      final y = _calculateBarY(barHeight, size.height);
      
      if (rounded && config.barBorderRadius != null) {
        final rect = RRect.fromRectAndCorners(
          Rect.fromLTWH(x, y, config.barWidth, barHeight),
          topLeft: config.barBorderRadius!.topLeft,
          topRight: config.barBorderRadius!.topRight,
          bottomLeft: config.barBorderRadius!.bottomLeft,
          bottomRight: config.barBorderRadius!.bottomRight,
        );
        canvas.drawRRect(rect, paint);
      } else {
        canvas.drawRect(
          Rect.fromLTWH(x, y, config.barWidth, barHeight),
          paint,
        );
      }
    }
  }
  
  /// Draws connected line
  void _drawLine(Canvas canvas, Size size) {
    final amplitudeList = amplitudes.value;
    
    if (amplitudeList.length < 2) {
      _drawBars(canvas, size, false);
      return;
    }
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.barWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    // Determine color based on state
    final isActive = isRecording && !isPaused;
    
    if (isActive && config.waveGradient != null) {
      paint.shader = config.waveGradient!.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    } else if (!isActive && config.inactiveGradient != null) {
      paint.shader = config.inactiveGradient!.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
    } else {
      paint.color = isActive ? config.waveColor : config.inactiveColor;
    }
    
    final path = Path();
    final maxHeight = config.maxBarHeight ?? size.height;
    final spacing = size.width / (amplitudeList.length - 1);
    
    for (int i = 0; i < amplitudeList.length; i++) {
      final amplitude = amplitudeList[i];
      final barHeight = _calculateBarHeight(amplitude, maxHeight);
      
      final x = i * spacing;
      final y = _calculateBarY(barHeight, size.height);
      
      if (i == 0) {
        path.moveTo(x, y + barHeight / 2);
      } else {
        path.lineTo(x, y + barHeight / 2);
      }
    }
    
    canvas.drawPath(path, paint);
  }
  
  /// Draws empty state (flat line)
  void _drawEmptyState(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = config.inactiveColor
      ..style = PaintingStyle.fill;
    
    final centerY = size.height / 2;
    final lineHeight = config.minBarHeight;
    
    canvas.drawRect(
      Rect.fromLTWH(0, centerY - lineHeight / 2, size.width, lineHeight),
      paint,
    );
  }
  
  /// Calculates bar height based on amplitude
  double _calculateBarHeight(double amplitude, double maxHeight) {
    final range = maxHeight - config.minBarHeight;
    return config.minBarHeight + (amplitude * range);
  }
  
  /// Calculates Y position based on alignment
  double _calculateBarY(double barHeight, double containerHeight) {
    switch (config.alignment) {
      case WaveAlignment.top:
        return 0;
      case WaveAlignment.center:
        return (containerHeight - barHeight) / 2;
      case WaveAlignment.bottom:
        return containerHeight - barHeight;
    }
  }
  
  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes ||
           oldDelegate.isRecording != isRecording ||
           oldDelegate.isPaused != isPaused ||
           oldDelegate.config != config;
  }
}
