import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/theme/app_colors.dart';

class MovieLogBottomNavigationBar extends StatelessWidget {
  const MovieLogBottomNavigationBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (label: '홈', icon: 'home.svg', selectedIcon: Icons.home_rounded),
    (label: '영화', icon: 'movie.svg', selectedIcon: Icons.movie_rounded),
    (label: '마이', icon: 'person.svg', selectedIcon: Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      ),
      backgroundColor: AppColors.surfaceBase,
      indicatorColor: AppColors.primary200,
      destinations: [
        for (final tab in _tabs)
          NavigationDestination(
            label: tab.label,
            icon: SvgPicture.asset(
              'assets/icons/${tab.icon}',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.secondary500,
                BlendMode.srcIn,
              ),
            ),
            selectedIcon: Icon(
              tab.selectedIcon,
              size: 24,
              color: AppColors.primary600,
            ),
          ),
      ],
    );
  }
}
