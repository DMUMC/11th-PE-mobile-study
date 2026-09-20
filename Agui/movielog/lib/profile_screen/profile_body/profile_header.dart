import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_theme.dart';
import 'edit_profile_button.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    this.profileImagePath = _defaultProfileImagePath,
  });

  static const _defaultProfileImagePath =
      'assets/images/profile/profile_movielo.jpg';

  final String? profileImagePath;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final defaultProfileIcon = SvgPicture.asset(
      'assets/icons/person.svg',
      width: 72,
      height: 72,
      semanticsLabel: '기본 프로필 아이콘',
      colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
    );

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              CircleAvatar(
                radius: 72,
                backgroundColor: colors.surface,
                child: profileImagePath == null
                    ? defaultProfileIcon
                    : ClipOval(
                        child: Image.asset(
                          profileImagePath!,
                          width: 144,
                          height: 144,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              defaultProfileIcon,
                        ),
                      ),
              ),
              Positioned(
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
          const SizedBox(height: AppSpacing.x2),
          const EditProfileButton(),
        ],
      ),
    );
  }
}
