import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/home/home_screen.dart';
import 'package:movielog/movie/movie_list_screen.dart';
import 'package:movielog/profile_screen/profile_screen.dart';
import 'package:movielog/start_screen.dart';

class AppRouter {
  AppRouter._();

  // Change this path to open a different screen when the app starts.
  static const initialLocation = '/start';

  static final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/start', builder: (context, state) => const StartScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/movies',
        builder: (context, state) => const MovieListScreen(),
        routes: [
          GoRoute(
            path: ':movieId',
            builder: (context, state) => _RoutePlaceholder(
              title: '영화 상세',
              subtitle: '영화 ID: ${state.pathParameters['movieId']}',
            ),
          ),
        ],
      ),
      GoRoute(path: '/my', builder: (context, state) => const ProfileScreen()),
    ],
  );
}

class _RoutePlaceholder extends StatelessWidget {
  const _RoutePlaceholder({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text(title), if (subtitle case final value?) Text(value)],
        ),
      ),
    );
  }
}
