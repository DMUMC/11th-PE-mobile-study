import 'package:flutter/material.dart';

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
      leading: const Icon(Icons.arrow_back),
      centerTitle: true,
      toolbarHeight: AppComponentHeight.appBar,
      title: Text(
        '회원가입',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: colors.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}
