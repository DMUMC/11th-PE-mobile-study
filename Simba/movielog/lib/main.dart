import 'package:flutter/material.dart';
import 'screens/profile_screen.dart';
import 'screens/start_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MovieLogApp());
}

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MovieLog',
      theme: AppTheme.light,
      // 시작 화면 확인 시: const StartScreen()
      // 프로필 화면 확인 시: const ProfileScreen()
      home: const ProfileScreen(),
    );
  }
}