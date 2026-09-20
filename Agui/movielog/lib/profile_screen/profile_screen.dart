import 'package:flutter/material.dart';
import 'package:movielog/profile_screen/profile_body/profile_header.dart';
import 'package:movielog/profile_screen/profile_body/profile_stats.dart';

import '../theme/app_theme.dart';
import 'app_bar/app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MovieLogAppBar(title: '내 프로필'),
      body: SafeArea(
        minimum: EdgeInsets.symmetric(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2,
            vertical: AppSpacing.x4,
          ),
          child: const Column(
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
            ],
          ),
        ),
      ),
    );
  }
}
