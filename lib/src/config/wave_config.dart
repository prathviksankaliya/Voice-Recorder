import 'package:flutter/material.dart';
import '../enums/enums.dart';

/// Configuration for audio wave visualization
/// 
/// Customize the appearance and behavior of [AudioWaveWidget].
/// 
/// Example:
/// ```dart
/// WaveConfig(
///   waveColor: Colors.blue,
///   inactiveColor: Colors.grey,
///   height: 80,
///   barWidth: 3,
///   barSpacing: 2,
/// )
/// ```
class WaveConfig {
  /// Color for active recording waves
  final Color waveColor;
  
  /// Color for inactive/paused/stopped waves
  final Color inactiveColor;
  
  /// Gradient for active recording waves (overrides waveColor if provided)
  final Gradient? waveGradient;
  
  /// Gradient for inactive waves (overrides inactiveColor if provided)
  final Gradient? inactiveGradient;
  
  /// Height of the wave widget
  final double height;
  
  /// Width of the wave widget (null = expand to available width)
  final double? width;
  
  /// Width of each bar
  final double barWidth;
  
  /// Spacing between bars
  final double barSpacing;
  
  /// Number of bars to display
  final int barCount;
  
  /// Minimum height for bars (when amplitude is 0)
  final double minBarHeight;
  
  /// Maximum height for bars (null = use widget height)
  final double? maxBarHeight;
  
  /// Border radius for bars (used in rounded style)
  final BorderRadius? barBorderRadius;
  
  /// Vertical alignment of bars
  final WaveAlignment alignment;
  
  /// Visual style of the wave
  final WaveStyle style;
  
  /// Duration for smooth animations
  final Duration animationDuration;
  
  /// Animation curve
  final Curve animationCurve;
  
  /// Enable smooth animations
  final bool enableAnimation;
  
  /// Show inactive bars when stopped (if false, shows flat line)
  final bool showInactiveWhenStopped;
  
  /// Enable smooth transitions between states
  final bool smoothTransitions;
  
  const WaveConfig({
    this.waveColor = Colors.blue,
    this.inactiveColor = Colors.grey,
    this.waveGradient,
    this.inactiveGradient,
    this.height = 80.0,
    this.width,
    this.barWidth = 3.0,
    this.barSpacing = 2.0,
    this.barCount = 50,
    this.minBarHeight = 4.0,
    this.maxBarHeight,
    this.barBorderRadius,
    this.alignment = WaveAlignment.center,
    this.style = WaveStyle.bars,
    this.animationDuration = const Duration(milliseconds: 150),
    this.animationCurve = Curves.easeInOut,
    this.enableAnimation = true,
    this.showInactiveWhenStopped = true,
    this.smoothTransitions = true,
  });
  
  /// Minimal preset - simple and clean
  /// 
  /// Small bars, minimal animation, perfect for compact UIs
  factory WaveConfig.minimal() {
    return const WaveConfig(
      height: 40.0,
      barWidth: 2.0,
      barSpacing: 1.5,
      barCount: 30,
      minBarHeight: 2.0,
      waveColor: Colors.blue,
      inactiveColor: Colors.grey,
      style: WaveStyle.bars,
      alignment: WaveAlignment.center,
    );
  }
  
  /// Standard preset - balanced appearance
  /// 
  /// Good default for most use cases
  factory WaveConfig.standard() {
    return const WaveConfig(
      height: 80.0,
      barWidth: 3.0,
      barSpacing: 2.0,
      barCount: 50,
      minBarHeight: 4.0,
      waveColor: Colors.blue,
      inactiveColor: Colors.grey,
      style: WaveStyle.bars,
      alignment: WaveAlignment.center,
    );
  }
  
  /// Modern preset - smooth and stylish
  /// 
  /// Rounded bars with smooth animations
  factory WaveConfig.modern() {
    return WaveConfig(
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
      animationDuration: const Duration(milliseconds: 200),
      animationCurve: Curves.easeInOutCubic,
    );
  }
  
  /// Detailed preset - high resolution
  /// 
  /// Many bars for detailed visualization
  factory WaveConfig.detailed() {
    return const WaveConfig(
      height: 120.0,
      barWidth: 2.0,
      barSpacing: 1.0,
      barCount: 100,
      minBarHeight: 3.0,
      waveColor: Colors.blue,
      inactiveColor: Colors.grey,
      style: WaveStyle.bars,
      alignment: WaveAlignment.center,
    );
  }
  
  /// Creates a copy with modified properties
  WaveConfig copyWith({
    Color? waveColor,
    Color? inactiveColor,
    Gradient? waveGradient,
    Gradient? inactiveGradient,
    double? height,
    double? width,
    double? barWidth,
    double? barSpacing,
    int? barCount,
    double? minBarHeight,
    double? maxBarHeight,
    BorderRadius? barBorderRadius,
    WaveAlignment? alignment,
    WaveStyle? style,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? enableAnimation,
    bool? showInactiveWhenStopped,
    bool? smoothTransitions,
  }) {
    return WaveConfig(
      waveColor: waveColor ?? this.waveColor,
      inactiveColor: inactiveColor ?? this.inactiveColor,
      waveGradient: waveGradient ?? this.waveGradient,
      inactiveGradient: inactiveGradient ?? this.inactiveGradient,
      height: height ?? this.height,
      width: width ?? this.width,
      barWidth: barWidth ?? this.barWidth,
      barSpacing: barSpacing ?? this.barSpacing,
      barCount: barCount ?? this.barCount,
      minBarHeight: minBarHeight ?? this.minBarHeight,
      maxBarHeight: maxBarHeight ?? this.maxBarHeight,
      barBorderRadius: barBorderRadius ?? this.barBorderRadius,
      alignment: alignment ?? this.alignment,
      style: style ?? this.style,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      enableAnimation: enableAnimation ?? this.enableAnimation,
      showInactiveWhenStopped: showInactiveWhenStopped ?? this.showInactiveWhenStopped,
      smoothTransitions: smoothTransitions ?? this.smoothTransitions,
    );
  }
}
