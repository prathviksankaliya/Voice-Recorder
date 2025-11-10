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
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RecordingProvider(),
      child: MaterialApp(
        title: 'Audio Recorder',
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
