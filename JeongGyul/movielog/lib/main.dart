import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:movielog/screens/start_screen.dart';
import 'package:movielog/screens/profile_screen.dart';

void main() => runApp(const MovieLogApp());

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const ProfileScreen(),
  );
}
