import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 72,
                backgroundColor: colors.surface,
                backgroundImage: const AssetImage(
                  'assets/images/profile/profile_movielog.jpg',
                ),
              ),
              Positioned(
                left: 56,
                bottom: -15,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: SvgPicture.asset(
                      'assets/icons/person.svg',
                      width: 28,
                      height: 28,
                      semanticsLabel: '프로필 아이콘',
                      colorFilter: ColorFilter.mode(
                        colors.onPrimary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Text('무비러버', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.x1),
          Text(
            '좋아하는 영화를 기록하고 있어요',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: colors.onSurface,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
