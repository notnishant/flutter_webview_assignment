import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final data = args['data'] as Map<String, dynamic>;
    final timestamp = args['timestamp'];

    return Scaffold(
      appBar: AppBar(title: const Text('Form Submission Result')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Submitted Data:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...data.entries.map((entry) => Text('${entry.key}: ${entry.value}')),
            const SizedBox(height: 24),
            Text('Submitted at: $timestamp'),
          ],
        ),
      ),
    );
  }
}
