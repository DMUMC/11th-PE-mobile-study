import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/home/movie_log_bottom_navigation_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: MovieLogBottomNavigationBar(
        navigationShell: navigationShell,
      ),
    );
  }
}
