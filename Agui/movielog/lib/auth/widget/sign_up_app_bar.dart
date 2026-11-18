import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_theme.dart';

class SignUpAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SignUpAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(AppComponentHeight.appBar);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: '뒤로 가기',
        onPressed: () => context.go('/start'),
        icon: const Icon(Icons.arrow_back, size: 24),
      ),
      centerTitle: true,
      toolbarHeight: AppComponentHeight.appBar,
      title: Text(
        '회원가입',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: 20,
          height: 1.4,
          color: colors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
