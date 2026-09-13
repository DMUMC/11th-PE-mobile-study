import 'package:flutter/material.dart';
import 'package:movielog/start_screen.dart';

void main() {
  runApp(const MovieLogApp());
}

// lib/movie_log_app.dart
class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: ThemeData(useMaterial3: true),
      home: const StartScreen(), // 첫 실행 화면 지정
    );
  }
}
