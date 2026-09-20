import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:movielog/start_screen.dart';

void main() => runApp(const MovieLogApp());

class MovieLogApp extends StatelessWidget {
  const MovieLogApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const StartScreen(),
  );
}
