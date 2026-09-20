import 'package:flutter/material.dart';
import 'package:movielog/profile_screen/profile_body/favorite_genrs.dart';
import 'package:movielog/profile_screen/profile_body/profile_header.dart';
import 'package:movielog/profile_screen/profile_body/profile_stats.dart';

import '../theme/app_theme.dart';
import 'app_bar/app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const MovieLogAppBar(title: '내 프로필'),
      body: SafeArea(
        minimum: EdgeInsets.symmetric(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2,
            vertical: AppSpacing.x4,
          ),
          child: Column(
            children: [
              ProfileHeader(),
              SizedBox(height: AppSpacing.x4),
              Row(
                children: [
                  Expanded(
                    child: StatItem(label: '본 영화', value: '24'),
                  ),
                  SizedBox(width: AppSpacing.x1),
                  Expanded(
                    child: StatItem(label: '평점', value: '4.2'),
                  ),
                  SizedBox(width: AppSpacing.x1),
                  Expanded(
                    child: StatItem(label: '즐겨찾기', value: '58'),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.x4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('선호하는 장르', style: textTheme.titleSmall),
              ),
              SizedBox(height: AppSpacing.x2),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: AppSpacing.x1,
                  runSpacing: AppSpacing.x1,
                  children: [
                    FavoriteGenreChip(label: '드라마'),
                    FavoriteGenreChip(label: 'SF'),
                    FavoriteGenreChip(label: '애니메이션'),
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
