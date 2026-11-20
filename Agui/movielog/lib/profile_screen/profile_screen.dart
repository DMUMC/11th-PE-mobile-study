import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:movielog/profile_screen/mock_profile_data.dart';
import 'package:movielog/profile_screen/profile_body/favorite_genrs.dart';
import 'package:movielog/profile_screen/profile_body/my_ratings_entry.dart';
import 'package:movielog/profile_screen/profile_body/profile_header.dart';
import 'package:movielog/profile_screen/profile_body/profile_stats.dart';

import '../theme/app_theme.dart';
import '../view_models/auth_view_model.dart';
import '../widgets/movielog_button.dart';
import 'app_bar/app_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final auth = context.watch<AuthViewModel>();
    final isLoading = auth.memberStatus == MemberLoadStatus.loading ||
        (auth.memberStatus == MemberLoadStatus.idle && auth.member == null);
    final hasError = auth.memberStatus == MemberLoadStatus.error;
    final showStatus = isLoading || hasError;
    return Scaffold(
      backgroundColor: showStatus ? const Color(0xFFFEFCF9) : null,
      appBar: MovieLogAppBar(
        title: '내 프로필',
        centerTitle: showStatus,
        backgroundColor: showStatus ? const Color(0xFFFEFCF9) : null,
        actions: [
          if (kDebugMode && !hasError)
            IconButton(
              tooltip: '디버그: 내 정보 불러오기 실패',
              onPressed: isLoading ? null : auth.simulateMemberLoadFailure,
              icon: const Icon(Icons.bug_report_outlined),
            ),
          if (!hasError) TextButton(
            onPressed: context.select<AuthViewModel, bool>(
              (auth) => auth.storageCleanupInProgress,
            )
                ? null
                : () => context.read<AuthViewModel>().logout(),
            child: const Text('로그아웃'),
          ),
        ],
      ),
      body: SafeArea(
        minimum: EdgeInsets.symmetric(),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      auth.message ?? '내 정보를 불러오지 못했어요.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    MovieLogButton(
                      label: '다시 시도',
                      width: 216,
                      onPressed: () => auth.loadMember(force: true),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2,
            vertical: AppSpacing.x4,
          ),
          child: Column(
            children: [
              ProfileHeader(),
              SizedBox(height: AppSpacing.x4),
              Row(
                children: profileStats
                    .asMap()
                    .entries
                    .map<List<Widget>>(
                      (entry) => [
                        if (entry.key > 0) const SizedBox(width: AppSpacing.x1),
                        Expanded(
                          child: StatItem(
                            label: entry.value.label,
                            value: entry.value.value,
                          ),
                        ),
                      ],
                    )
                    .expand<Widget>((widgets) => widgets)
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.x3),
              const MyRatingsEntry(),
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
                  children: favoriteGenres
                      .map((genre) => FavoriteGenreChip(label: genre))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
