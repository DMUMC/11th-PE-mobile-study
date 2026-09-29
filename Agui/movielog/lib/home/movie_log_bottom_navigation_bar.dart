import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movielog/theme/app_colors.dart';

class MovieLogBottomNavigationBar extends StatelessWidget {
  const MovieLogBottomNavigationBar({required this.currentIndex, super.key});

  final int currentIndex;

  static const _tabs = [
    (
      label: '홈',
      icon: 'home.svg',
      selectedIcon: Icons.home_rounded,
      path: '/home',
    ),
    (
      label: '영화',
      icon: 'movie.svg',
      selectedIcon: Icons.movie_rounded,
      path: '/movies',
    ),
    (
      label: '마이',
      icon: 'person.svg',
      selectedIcon: Icons.person_rounded,
      path: '/my',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 80,
        decoration: const BoxDecoration(
          color: AppColors.surfaceBase,
          border: Border(top: BorderSide(color: AppColors.surfaceContainer)),
        ),
        child: Row(
          children: [
            for (var index = 0; index < _tabs.length; index++)
              Expanded(
                child: InkWell(
                  onTap: () => context.go(_tabs[index].path),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: currentIndex == index
                              ? AppColors.primary200
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: currentIndex == index
                            ? Icon(
                                _tabs[index].selectedIcon,
                                size: 24,
                                color: AppColors.primary600,
                              )
                            : SvgPicture.asset(
                                'assets/icons/${_tabs[index].icon}',
                                width: 24,
                                height: 24,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.secondary500,
                                  BlendMode.srcIn,
                                ),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _tabs[index].label,
                        style: TextStyle(
                          color: currentIndex == index
                              ? AppColors.primary600
                              : AppColors.secondary500,
                          fontSize: 12,
                          fontWeight: currentIndex == index
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
