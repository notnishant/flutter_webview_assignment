import 'dart:convert';
import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> formData;
  late String timestamp;

  // Additional fields
  final TextEditingController _commentsController = TextEditingController();
  String _selectedStatus = 'pending';
  double _rating = 3.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    formData = Map<String, dynamic>.from(args['data'] as Map);
    timestamp = args['timestamp'] as String;
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  void _sendDataToReact() {
    final additionalData = {
      'status': _selectedStatus,
      'rating': _rating,
      'adminComments': _commentsController.text,
      'reviewedAt': DateTime.now().toIso8601String(),
      'timestamp': timestamp,
    };

    // Pop twice to go back to WebView
    Navigator.pop(context, additionalData);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Ensure we send data back when user presses back button
        Navigator.pop(context, {
          'status': _selectedStatus,
          'rating': _rating,
          'adminComments': _commentsController.text,
          'reviewedAt': DateTime.now().toIso8601String(),
          'timestamp': timestamp,
        });
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Screen'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Submitted Data Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Submitted Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...formData.entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${entry.key}:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      entry.value.toString(),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Divider(),
                          Text(
                            'Submitted: $timestamp',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Additional Fields Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Review Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Status Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'pending',
                                child: Text('Pending'),
                              ),
                              DropdownMenuItem(
                                value: 'approved',
                                child: Text('Approved'),
                              ),
                              DropdownMenuItem(
                                value: 'rejected',
                                child: Text('Rejected'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Rating Slider
                          const Text(
                            'Rating',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Slider(
                            value: _rating,
                            min: 1,
                            max: 5,
                            divisions: 4,
                            label: _rating.toString(),
                            onChanged: (value) {
                              setState(() {
                                _rating = value;
                              });
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [Text('Poor'), Text('Excellent')],
                          ),
                          const SizedBox(height: 16),

                          // Comments TextField
                          TextFormField(
                            controller: _commentsController,
                            decoration: const InputDecoration(
                              labelText: 'Admin Comments',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sendDataToReact,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Send Review'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
