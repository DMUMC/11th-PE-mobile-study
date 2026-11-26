import 'package:provider/provider.dart';

import '../../view_models/auth_view_model.dart';
import '../../data/models/member_info.dart';

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
      'assets/images/profile/profile_movielog.jpg';

  final String? profileImagePath;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final member = context.select<AuthViewModel, MemberInfo?>(
      (auth) => auth.member,
    );
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
          Text(
            member?.nickname ?? '',
            style: textTheme.titleMedium,
          ),
          if (member != null) ...[
            const SizedBox(height: AppSpacing.x1),
            Text(
              '${member.createdAt.year.toString().padLeft(4, '0')}.${member.createdAt.month.toString().padLeft(2, '0')}.${member.createdAt.day.toString().padLeft(2, '0')} 가입',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            Text(
              member.email,
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: AppSpacing.x2),
          const EditProfileButton(),
        ],
      ),
    );
  }
}
