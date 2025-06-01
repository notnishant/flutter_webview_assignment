import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isLocal = false; // Toggle for local/remote
  String _username = '';
  bool _isConnected = true;

  final String reactAppUrl = 'https://notnishant.github.io/todo-react-main/';
  final String localHtmlPath =
      'assets/local_react.html'; // Place your local HTML in assets

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _checkConnectivity();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _hasError = false;
          }),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) => setState(() {
            _hasError = true;
            _isLoading = false;
            _errorMessage = error.description ?? 'Could not load page.';
          }),
        ),
      )
      ..addJavaScriptChannel(
        'showAlert',
        onMessageReceived: (JavaScriptMessage message) {
          final data = jsonDecode(message.message);
          if (data['action'] == 'showAlert') {
            _showAlert(context, {
              'type': 'info',
              'title': 'Message from React',
              'message': data['message'],
            });
          }
        },
      );
    _loadWebView();
  }

  void _loadWebView() async {
    if (_isLocal) {
      // Load local HTML file
      final String filePath = await _getLocalFilePath();
      _controller.loadFile(filePath);
    } else {
      _controller.loadRequest(Uri.parse(reactAppUrl));
    }
  }

  Future<String> _getLocalFilePath() async {
    // For webview_flutter, local file loading differs by platform
    if (Platform.isAndroid) {
      return 'file:///android_asset/flutter_assets/$localHtmlPath';
    } else if (Platform.isIOS) {
      return await rootBundle.loadString(localHtmlPath);
    }
    return localHtmlPath;
  }

  void _sendToReact(String type, Map<String, dynamic> data) {
    final message = jsonEncode({'type': type, 'data': data});
    _controller.runJavaScript(
      'window.receiveFromFlutter && window.receiveFromFlutter($message);',
    );
  }

  void _sendUsername() {
    _sendToReact('setUsername', {'username': _username});
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = result != ConnectivityResult.none;
    });
    if (!_isConnected) {
      _showAlert(context, {
        'type': 'validation',
        'title': 'Network Error',
        'message': 'No internet connection. Please check your network.',
      });
    }
  }

  Future<void> _showAlert(
    BuildContext context,
    Map<String, dynamic> alertData,
  ) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alertData['title'] ?? ''),
        content: Text(alertData['message'] ?? ''),
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

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
    });
  }

  Future<void> _saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    setState(() {
      _username = username;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _hasError = false;
                _isLoading = true;
              });
              _loadWebView();
            },
          ),
          IconButton(
            icon: Icon(_isLocal ? Icons.cloud : Icons.insert_drive_file),
            tooltip: _isLocal ? 'Load Remote' : 'Load Local',
            onPressed: () {
              setState(() {
                _isLocal = !_isLocal;
                _hasError = false;
                _isLoading = true;
              });
              _loadWebView();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isConnected)
            Container(
              color: Colors.red[100],
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: const Text(
                'No internet connection',
                style: TextStyle(color: Colors.red),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Username'),
                    controller: TextEditingController(text: _username),
                    onChanged: (val) => _saveUsername(val),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendUsername,
                  child: const Text('Send to React'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                if (_hasError)
                  Center(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 18),
                    ),
                  ),
                if (!_hasError) WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
