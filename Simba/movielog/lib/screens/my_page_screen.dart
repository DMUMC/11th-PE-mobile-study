import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../widgets/common_app_bar.dart';
import 'profile_screen.dart';

/// 마이 탭. 3주차 프로필 화면 구성에 「내가 등록한 평점」 진입 항목을 더한다.
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: '내 프로필'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileHeader(
                imagePath: 'assets/images/profile/profile_movielog.jpg',
              ),
              const SizedBox(height: 24),
              const ProfileStats(),
              const SizedBox(height: 28),
              const FavoriteGenres(),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const Icon(Icons.star_rate_rounded,
                      color: AppColors.violet),
                  title: const Text(
                    '내가 등록한 평점',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  // root Navigator 위에 push → 뒤로가면 마이페이지로 돌아온다.
                  onTap: () => context.push('/my/ratings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
