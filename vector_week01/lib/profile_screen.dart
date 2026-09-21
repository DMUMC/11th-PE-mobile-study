import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 프로필')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),

              // 프로필 사진
              const Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage(
                    'assets/images/profile/profile_movielog.jpg',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 닉네임
              const Text(
                '무비러버',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              // 소개
              const Text(
                '매주 주말엔 영화관으로 출근하는 프로 관람객.\n좋은 영화를 보고 기록하는 것을 좋아합니다.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // 프로필 수정 버튼
              Center(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('프로필 수정'),
                ),
              ),

              const SizedBox(height: 32),

              // 통계 카드 3개
              const Row(
                children: [
                  Expanded(
                    child: StatItem(label: '본 영화', value: '342'),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: StatItem(label: '평점', value: '4.2'),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: StatItem(label: '즐겨찾기', value: '58'),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 선호 장르
              const Text(
                '선호하는 장르',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              const Row(
                children: [
                  GenreChip(label: '드라마'),
                  SizedBox(width: 8),
                  GenreChip(label: 'SF'),
                  SizedBox(width: 8),
                  GenreChip(label: '애니메이션'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 통계 카드
class StatItem extends StatelessWidget {
  const StatItem({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// 장르 Chip
class GenreChip extends StatelessWidget {
  const GenreChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Chip(
      label: Text(label),
      backgroundColor: colors.primary.withValues(alpha: 0.12),
      side: BorderSide.none,
    );
  }
}
