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

  void _handleMessage(Map<String, dynamic> data) async {
    final String type = data['type'] ?? '';
    final Map<String, dynamic> payload = data['data'] ?? {};

    switch (type) {
      case 'alert':
        _showToast(
          message: payload['message'] ?? '',
          isError: payload['isError'] ?? false,
          field: payload['field'],
        );
        break;
      case 'formSubmit':
        final result = await Navigator.pushNamed(
          context,
          '/result',
          arguments: {'data': payload, 'timestamp': DateTime.now().toString()},
        );

        if (result != null) {
          final reviewData = result as Map<String, dynamic>;
          final combinedData = {...payload, ...reviewData};
          _sendToReact('navigateToReview', combinedData);
        }
        break;
    }
  }

  void _sendToReact(String type, Map<String, dynamic> data) {
    final message = jsonEncode({'type': type, 'data': data});

    _controller.runJavaScript('''
      if (typeof window.receiveFromFlutter !== 'function') {
        window.receiveFromFlutter = function(data) {
          const parsedData = typeof data === 'string' ? JSON.parse(data) : data;
          if (parsedData.type === 'navigateToReview') {
            localStorage.setItem('reviewData', JSON.stringify(parsedData.data));
            if (window.flutterBridge && window.flutterBridge.handleFlutterMessage) {
              window.flutterBridge.handleFlutterMessage(parsedData);
            }
          }
        };
      }
      localStorage.setItem('reviewData', JSON.stringify(${jsonEncode(data)}));
      window.receiveFromFlutter(${jsonEncode(message)});
    ''');
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none && mounted) {
      _showToast(
        message: 'No internet connection. Please check your network.',
        isError: true,
      );
    }
  }

  void _showToast({
    required String message,
    bool isError = false,
    String? field,
  }) {
    final Color backgroundColor = isError
        ? const Color(0xFFDC3545).withOpacity(0.95)
        : const Color(0xFF28A745).withOpacity(0.95);

    final Widget content = Row(
      children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isError ? 'Error' : 'Success',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (field != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Field: ${field.replaceFirst(field[0], field[0].toUpperCase())}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 2),
              Text(
                message,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: content,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.of(context).size.height * 0.1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(milliseconds: 4000),
        dismissDirection: DismissDirection.horizontal,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
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
