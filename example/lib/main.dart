import 'package:flutter/material.dart';
import 'examples/basic_controls.dart';
import 'examples/customization.dart';
import 'examples/wave_visualization.dart';
import 'examples/complete_app.dart';

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
      home: const ExampleListScreen(),
    );
  }
}

class ExampleListScreen extends StatelessWidget {
  const ExampleListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Recorder Examples'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice Recorder Package',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Simple examples to get you started quickly!',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Example 1
          _buildExampleCard(
            context,
            number: '1',
            title: 'Basic Recording Controls',
            description: 'Start, pause, resume, stop recording',
            icon: Icons.play_circle_outline,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BasicControls()),
            ),
          ),
          
          // Example 2
          _buildExampleCard(
            context,
            number: '2',
            title: 'Customization',
            description: 'Audio quality, storage options, configurations',
            icon: Icons.tune,
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Customization()),
            ),
          ),
          
          // Example 3
          _buildExampleCard(
            context,
            number: '3',
            title: 'Wave Visualization',
            description: 'Real-time audio waveform display',
            icon: Icons.graphic_eq,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WaveVisualization()),
            ),
          ),
          
          // Example 4
          _buildExampleCard(
            context,
            number: '4',
            title: 'Complete App',
            description: 'All features combined in production-ready app',
            icon: Icons.rocket_launch,
            color: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompleteApp()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context, {
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Number badge
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    number,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Icon
              Icon(icon, color: color, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
