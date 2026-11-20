import 'package:flutter/material.dart';

/// MovieLog 화면에서 공통으로 사용하는 상단 앱 바입니다.
class MovieLogAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MovieLogAppBar({super.key, required this.title, this.actions});

  static const _toolbarHeight = 64.0;

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(_toolbarHeight + 1);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: false,
      toolbarHeight: _toolbarHeight,
      titleSpacing: 16,
      actions: actions,
      title: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
