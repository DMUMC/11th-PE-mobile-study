import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/movie/model/movie.dart';
import 'package:movielog/theme/app_colors.dart';
import 'package:movielog/theme/app_text_style.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/movies/${movie.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _PosterImage(movie: movie),
                ),
                if (movie.rating != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xDD35333A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/star.svg',
                            width: 12,
                            height: 12,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            movie.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMediumBold,
          ),
          const SizedBox(height: 2),
          Text(
            '${movie.year} · ${movie.genre}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMediumRegular.copyWith(
              color: AppColors.secondary500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterImage extends StatelessWidget {
  const _PosterImage({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    if (movie.id == 10) {
      return ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Image.asset(movie.posterAsset, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '별빛 아래 우리',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              const Text(
                'UNDER THE STARLIGHT',
                style: TextStyle(fontSize: 5, letterSpacing: 0.4),
              ),
            ],
          ),
        ),
      );
    }

    if (movie.id == 15) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(movie.posterAsset, fit: BoxFit.cover),
          const Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Text(
              '도시의 선',
              style: TextStyle(
                color: Color(0xFF302D2A),
                fontSize: 25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Positioned(
            right: 10,
            bottom: 10,
            child: Text(
              '감독: 이준우\n상영 시간: 98분\n제작 연도: 2023',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontSize: 7,
                height: 1.4,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
        ],
      );
    }

    return Image.asset(movie.posterAsset, fit: BoxFit.cover);
  }
}
