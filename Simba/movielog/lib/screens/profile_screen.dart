import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/stat_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CommonAppBar(
        title: '내 프로필',
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 실제 이미지 경로로 수정 완료
              ProfileHeader(
                imagePath: 'assets/images/profile/profile_movielog.jpg',
              ),
              SizedBox(height: 24),
              ProfileStats(),
              SizedBox(height: 28),
              FavoriteGenres(),
            ],
          ),
        ),
      ),
    );
  }
}

// 1. 프로필 헤더 (Challenge: 이미지 없을 때 기본 Icon fallback)
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key, this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.lightViolet,
            ),
            child: CircleAvatar(
              radius: 54,
              backgroundColor: AppColors.cardBg,
              backgroundImage:
                  imagePath != null ? AssetImage(imagePath!) : null,
              child: imagePath == null
                  ? const Icon(Icons.person, size: 54, color: AppColors.violet)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          const Text('무비러버', style: AppTextStyles.titleLarge),
          const SizedBox(height: 10),
          const Text(
            '매주 주말엔 영화관으로 출근하는 프로 관람객. 좋\n은 영화를 보고 기록하는 것을 좋아합니다.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          // 프로필 수정 아웃라인 버튼
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.violet),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
            child: Text(
              '프로필 수정',
              style: AppTextStyles.chipText.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 2. 통계 카드 영역 (Challenge: List + map 활용)
class ProfileStats extends StatelessWidget {
  const ProfileStats({super.key});

  static const List<Map<String, String>> stats = [
    {'label': '본 영화', 'value': '342'},
    {'label': '평점', 'value': '4.2'},
    {'label': '즐겨찾기', 'value': '58'},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: StatItem(
              label: item['label']!,
              value: item['value']!,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// 3. 선호 장르 영역 (Challenge: List + map 활용 Chip 렌더링)
class FavoriteGenres extends StatelessWidget {
  const FavoriteGenres({super.key});

  static const List<String> genres = ['드라마', 'SF', '애니메이션'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('선호하는 장르', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: genres.map((genre) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.lightViolet,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                genre,
                style: AppTextStyles.chipText,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}