import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../view_models/auth_view_model.dart';
import '../view_models/session_ratings_store.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movielog_button.dart';
import 'profile_screen.dart';

/// 마이 탭. GET me로 받은 내 정보(이메일·닉네임·가입일)를 보여준다.
/// 사진·통계·장르는 기존 디자인 예시이며 v7 응답에 없는 값이다.
class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // read가 아니라 watch로 구독해야 프로필 수정 후 새 닉네임이 바로 보인다.
    final auth = context.watch<AuthViewModel>();
    final member = auth.member;

    return Scaffold(
      appBar: CommonAppBar(
        title: '내 프로필',
        actions: [
          TextButton(
            onPressed: auth.storageCleanupInProgress ? null : auth.logout,
            child: const Text('로그아웃'),
          ),
        ],
      ),
      body: SafeArea(
        child: switch ((member, auth.memberStatus)) {
          // (Challenge) 내 정보 로딩 중: 화면 전체 인디케이터
          (null, MemberLoadStatus.idle || MemberLoadStatus.loading) =>
            const Center(
              child: CircularProgressIndicator(color: AppColors.violet),
            ),
          // (Challenge) 실패: 로그아웃하지 않고 재시도
          (null, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: AppColors.gray,
                ),
                const SizedBox(height: 12),
                const Text('내 정보를 불러오지 못했어요.'),
                const SizedBox(height: 16),
                MovieLogButton(
                  label: '다시 시도',
                  width: 96,
                  onPressed: () => auth.loadMember(force: true),
                ),
              ],
            ),
          ),
          (final member?, _) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeader(
                  imagePath: 'assets/images/profile/profile_movielog.jpg',
                  nickname: member.nickname,
                  email: member.email,
                  joinedText: member.joinedText,
                  onEditProfile: () => context.push('/my/profile/edit'),
                ),
                const SizedBox(height: 24),
                const ProfileStats(),
                const SizedBox(height: 28),
                const FavoriteGenres(),
                const SizedBox(height: 20),
                const _MyRatingsEntry(),
              ],
            ),
          ),
        },
      ),
    );
  }
}

class _MyRatingsEntry extends StatelessWidget {
  const _MyRatingsEntry();

  @override
  Widget build(BuildContext context) {
    final count = context.watch<SessionRatingsStore>().ratings.length;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: const Icon(Icons.star_rate_rounded, color: AppColors.violet),
        title: const Text(
          '내가 등록한 평점',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '이번 로그인에서 등록한 평점 $count개',
          style: AppTextStyles.labelSmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        // root Navigator 위에 push → 뒤로가면 마이페이지로 돌아온다.
        onTap: () => context.push('/my/ratings'),
      ),
    );
  }
}
