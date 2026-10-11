import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/movie.dart';
import '../../theme/app_colors.dart';

class FeaturedMovieCard extends StatelessWidget {
  const FeaturedMovieCard({super.key, required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: AspectRatio(
      aspectRatio: 2 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(movie.heroAsset ?? movie.posterAsset, fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xD9000000)],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Chip(
                  label: Text('추천 신작'),
                  backgroundColor: AppColors.primary600,
                  labelStyle: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  movie.title,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '${movie.tags.take(2).join(' · ')} · ${movie.durationMinutes}분',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/movies/${movie.id}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary600,
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.info, size: 18),
                    label: const Text('상세보기'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
