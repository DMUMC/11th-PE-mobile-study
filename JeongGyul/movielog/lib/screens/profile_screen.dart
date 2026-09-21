import 'package:flutter/material.dart';

import '../widgets/genre_chip.dart';
import '../widgets/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          '내 프로필',
          style: textTheme.bodyLarge?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 64,
                backgroundImage: AssetImage(
                  'assets/images/profile/profile_movielog.jpg',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '무비러버',
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋은 영화로 보고 기록하는 것을 좋아합니다.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  backgroundColor: colors.surface,
                  foregroundColor: colors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: colors.primary),
                ),
                child: Text(
                  '프로필 수정',
                  style: textTheme.labelLarge?.copyWith(color: colors.primary),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: const [
                  Expanded(
                    child: StatItem(label: '본 영화', value: '342'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: StatItem(label: '평점', value: '4.2'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: StatItem(label: '즐겨찾기', value: '58'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '선호하는 장르',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    GenreChip(label: '드라마'),
                    GenreChip(label: 'SF'),
                    GenreChip(label: '애니메이션'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
