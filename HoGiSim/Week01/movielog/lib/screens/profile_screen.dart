import 'package:flutter/material.dart';

import '../widgets/movie_log_app_bar.dart';
import '../widgets/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MovieLogAppBar(title: '내 프로필'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileHeader(),
              SizedBox(height: 32),
              ProfileStats(),
              SizedBox(height: 32),
              FavoriteGenres(),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        CircleAvatar(
          radius: 64,
          backgroundColor: colors.surfaceContainerHighest,
          child: Icon(Icons.person, size: 64, color: colors.primary),
        ),
        const SizedBox(height: 16),
        Text('무비러버', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '매주 주말엔 영화관으로 출근하는 프로 관람객. '
          '좋은 영화를 보고 기록하는 것을 좋아합니다.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 128,
          height: 42,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('프로필 수정'),
          ),
        ),
      ],
    );
  }
}

class ProfileStatData {
  const ProfileStatData({required this.label, required this.value});

  final String label;
  final String value;
}

class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  static const stats = [
    ProfileStatData(label: '본 영화', value: '342'),
    ProfileStatData(label: '평점', value: '4.2'),
    ProfileStatData(label: '즐겨찾기', value: '58'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == stats.length - 1 ? 0 : 8),
            child: StatItem(label: stat.label, value: stat.value),
          ),
        );
      }).toList(),
    );
  }
}

class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key});

  static const genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '선호하는 장르',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genres.map((genre) => Chip(label: Text(genre))).toList(),
        ),
      ],
    );
  }
}
