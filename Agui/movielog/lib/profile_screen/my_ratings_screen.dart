import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'profile_body/my_rating_card.dart';

class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppComponentHeight.appBar,
        centerTitle: true,
        leading: IconButton(
          tooltip: '뒤로 가기',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, size: 24),
        ),
        title: Text(
          '내가 등록한 평점',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 20,
            height: 1.4,
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            AppSpacing.x4,
            18,
            AppSpacing.x3,
          ),
          // Figma의 화면 예시입니다. 평점 조회는 API 연동 미션에서 연결합니다.
          children: const [
            MyRatingCard(title: '영화 제목', score: 4, comment: '다시 봐도 좋아요'),
            SizedBox(height: AppSpacing.x2),
            MyRatingCard(title: '영화 #13', score: 3, comment: '포스터 정보 없음'),
          ],
        ),
      ),
    );
  }
}
