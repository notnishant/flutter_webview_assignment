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
    _initializeWebView();
  }

  void _initializeWebView() {
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
      ..addJavaScriptChannel(
        'flutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message);
            _handleMessage(data);
          } catch (e) {
            debugPrint('Error processing message: $e');
          }
        },
      )
      ..loadRequest(Uri.parse(reactAppUrl));
  }

  void _handleMessage(Map<String, dynamic> data) {
    final String type = data['type'] ?? '';
    final Map<String, dynamic> payload = data['data'] ?? {};

    switch (type) {
      case 'alert':
        _showAlert(
          title: payload['title'] ?? 'Alert',
          message: payload['message'] ?? '',
          isError: payload['isError'] ?? false,
        );
        break;
      case 'formSubmit':
        _handleFormSubmit(payload);
        break;
    }
  }

  void _handleFormSubmit(Map<String, dynamic> formData) {
    Navigator.pushNamed(
      context,
      '/result',
      arguments: {'data': formData, 'timestamp': DateTime.now().toString()},
    );
  }

  // Send data to React
  void _sendToReact(String type, Map<String, dynamic> data) {
    final message = jsonEncode({'type': type, 'data': data});
    _controller.runJavaScript(
      'window.receiveFromFlutter && window.receiveFromFlutter($message);',
    );
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none && mounted) {
      _showAlert(
        title: 'Network Error',
        message: 'No internet connection. Please check your network.',
        isError: true,
      );
    }
  }

  Future<void> _showAlert({
    required String title,
    required String message,
    bool isError = false,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        backgroundColor: isError ? Colors.red[50] : Colors.white,
        titleTextStyle: TextStyle(
          color: isError ? Colors.red[700] : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: isError ? Colors.red[900] : Colors.black87,
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
        title: const Text('React WebView'),
        backgroundColor: Colors.blue,
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
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}
