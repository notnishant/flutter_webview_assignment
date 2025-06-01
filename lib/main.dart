import 'package:flutter/material.dart';
import 'package:flutter_webview_assignment/screens/result_screen.dart';
import 'screens/home_screen.dart';
import 'screens/webview_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WebView Assignment',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/webview': (context) => const WebViewScreen(),
        '/result': (context) => const ResultScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
