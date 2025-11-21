import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/recorder_view/provider/recording_provider.dart';
import 'screens/recorder_view/recording_screen.dart';

void main() {
  runApp(const MyApp());
}

/// Main application widget
/// 
/// Sets up the Provider for state management and
/// initializes the recording screen.
/// 
/// This is the demo app. For using the recorder package in your own app,
/// import 'package:recorder/recorder.dart' and use RecorderManager directly.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RecordingProvider(),
      child: MaterialApp(
        title: 'Audio Recorder Demo',
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
        home: const RecordingScreen(),
      ),
    );
  }
}
