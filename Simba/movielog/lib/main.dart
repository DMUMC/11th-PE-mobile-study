import 'package:flutter/material.dart';
import 'screens/profile_screen.dart';
import 'screens/sign_up_screen.dart'; // 1. SignUpScreen import 추가
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
      // 시작 화면: const StartScreen()
      // 프로필 화면: const ProfileScreen()
      // 회원가입 화면: const SignUpScreen()
      home: const SignUpScreen(), // 2. 회원가입 화면으로 지정
    );
  }
}