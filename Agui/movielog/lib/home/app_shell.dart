import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/home/movie_log_bottom_navigation_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthViewModel>().loadMember();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: MovieLogBottomNavigationBar(
        navigationShell: widget.navigationShell,
      ),
    );
  }
}
