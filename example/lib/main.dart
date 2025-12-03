import 'package:flutter/material.dart';
import 'complete_app.dart';

void main() {
  runApp(const RecorderExampleApp());
}

class RecorderExampleApp extends StatelessWidget {
  const RecorderExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Recorder Examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CompleteApp(),
    );
  }
}
