import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'profile_body/profile_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x2,
            vertical: AppSpacing.x4,
          ),
          child: const Column(children: [ProfileHeader()]),
        ),
      ),
    );
  }
}
