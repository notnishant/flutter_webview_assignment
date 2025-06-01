import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  final String reactAppUrl = 'https://notnishant.github.io/todo-react-main/';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() {
            _hasError = true;
            _isLoading = false;
          }),
        ),
      )
    // Handle alerts and validation messages
      ..addJavaScriptChannel(
        'showAlert',
        onMessageReceived: (JavaScriptMessage message) {
          final alertData = jsonDecode(message.message);
          _showAlert(context, alertData);

          // If it's a validation error with a field, focus that field
          if (alertData['type'] == 'validation' && alertData['field'] != null) {
            _focusField(alertData['field']);
          }
        },
      )
    // Handle field updates and validation
      ..addJavaScriptChannel(
        'updateField',
        onMessageReceived: (JavaScriptMessage message) {
          final data = jsonDecode(message.message);
          debugPrint('Field ${data['field']} updated: ${data['value']}');

          // Handle validation errors
          if (!data['isValid']) {
            debugPrint('Validation error: ${data['error']}');
          }
        },
      )
    // Handle form submission
      ..addJavaScriptChannel(
        'submitForm',
        onMessageReceived: (JavaScriptMessage message) {
          final decoded = jsonDecode(message.message);
          final formData = decoded['data'];
          final timestamp = decoded['timestamp'];

          // Navigate to ResultScreen with the data
          _showAlert(context, {
            'type': 'success',
            'title': 'Success',
            'message': 'Form submitted successfully!',
          }).then((_) {
            // Navigate to result screen after alert is dismissed
            Navigator.pushNamed(
              context,
              '/result',
              arguments: {
                'data': formData,
                'timestamp': timestamp,
              },
            );
          });
        },
      )
    // Handle validation errors
      ..addJavaScriptChannel(
        'validationErrors',
        onMessageReceived: (JavaScriptMessage message) {
          final data = jsonDecode(message.message);
          debugPrint('Validation errors: ${data['errors']}');

          // Send validation errors back to React if needed
          _sendToReact('validationError', {
            'errors': data['errors'],
            'firstErrorField': data['firstErrorField'],
          });
        },
      )
    // Handle initial data request
      ..addJavaScriptChannel(
        'requestInitialData',
        onMessageReceived: (JavaScriptMessage message) {
          // Send any pre-filled data to React
          _sendToReact('prefilledData', {
            'firstName': 'John',
            'lastName': 'Doe',
            'email': 'john.doe@example.com',
          });
        },
      )
      ..loadRequest(Uri.parse(reactAppUrl));
  }

  // Send data back to React
  void _sendToReact(String type, Map<String, dynamic> data) {
    final message = jsonEncode({
      'type': type,
      'data': data,
    });
    _controller.runJavaScript(
        'window.receiveFromFlutter && window.receiveFromFlutter($message);'
    );
  }

  // Focus a specific form field
  void _focusField(String fieldId) {
    _controller.runJavaScript(
        'document.getElementById("$fieldId")?.focus();'
    );
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) {
      if (mounted) {
        _showAlert(context, {
          'type': 'validation',
          'title': 'Network Error',
          'message': 'No internet connection. Please check your network.',
        });
      }
    }
  }

  Future<void> _showAlert(BuildContext context, Map<String, dynamic> alertData) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alertData['title']),
        content: Text(alertData['message']),
        backgroundColor: alertData['type'] == 'validation'
            ? Colors.red[50]
            : Colors.green[50],
        titleTextStyle: TextStyle(
          color: alertData['type'] == 'validation'
              ? Colors.red[700]
              : Colors.green[700],
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: alertData['type'] == 'validation'
              ? Colors.red[900]
              : Colors.green[900],
          fontSize: 16,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Form'),
        backgroundColor: const Color(0xFF4F46E5), // Match React app's primary color
        foregroundColor: Colors.white,
      ),
      body: _hasError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Could not load page.\nPlease check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _controller.reload(),
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          SizedBox.expand(child: WebViewWidget(controller: _controller)),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}