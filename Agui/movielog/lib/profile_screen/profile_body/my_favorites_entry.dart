import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class MyFavoritesEntry extends StatelessWidget {
  const MyFavoritesEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.primary.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/my/favorites'),
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '내 즐겨찾기',
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(Icons.chevron_right, size: 24, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
