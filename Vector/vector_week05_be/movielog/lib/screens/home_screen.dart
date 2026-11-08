import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../widgets/movie_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'MovieLog',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: Color(0xFF503984),
        ),
      ),
      actions: [
        IconButton(
          tooltip: '영화 검색',
          onPressed: () => context.go('/movies'),
          icon: const Icon(Icons.search, size: 28),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: ListView(
      key: const PageStorageKey('home-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      children: [
        const Text(
          '오늘은 어떤\n영화를 볼까요?',
          style: TextStyle(
            fontSize: 30,
            height: 1.4,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 20),
        AspectRatio(
          aspectRatio: 2 / 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(movies.first.image, fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x55000000),
                        Color(0x33000000),
                        Color(0xEE000000),
                      ],
                      stops: [0, 0.4, 1],
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF503984),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF8B76AC)),
                        ),
                        child: const Text(
                          '추천 신작',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '별빛 아래 우리',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '로맨스 · 드라마 · 124분',
                        style: TextStyle(
                          fontSize: 17,
                          color: Color(0xFFDDDADD),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.go('/home/starlight'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF50358A),
                            minimumSize: const Size(0, 52),
                          ),
                          icon: const Icon(Icons.info),
                          label: const Text(
                            '상세보기',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '인기 영화',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            TextButton(
              onPressed: () => context.go('/movies'),
              child: const Text('전체보기  ›'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) => SizedBox(
            height:
                constraints.maxWidth / 2 * 1.5 +
                72 * MediaQuery.textScalerOf(context).scale(1),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: movies.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => SizedBox(
                width: (constraints.maxWidth - 12) / 2,
                child: MovieCard(
                  movie: movies[index],
                  onTap: () => context.go('/home/${movies[index].id}'),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
