import 'package:go_router/go_router.dart';
import 'package:movielog/auth/sign_up_screen.dart';
import 'package:movielog/home/home_screen.dart';
import 'package:movielog/movie/movie_detail_screen.dart';
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
      GoRoute(
        path: '/register',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/movies',
        builder: (context, state) => const MovieListScreen(),
        routes: [
          GoRoute(
            path: ':movieId',
            builder: (context, state) =>
                MovieDetailScreen(movieId: state.pathParameters['movieId']!),
          ),
        ],
      ),
      GoRoute(path: '/my', builder: (context, state) => const ProfileScreen()),
    ],
  );
}
