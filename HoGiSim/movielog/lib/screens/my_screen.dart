import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          '내 프로필',
          style: TextStyle(color: AppColors.primary, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: const [
          _ProfileSummary(),
          SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _StatCard(value: '342', label: '본 영화'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StatCard(value: '4.2', label: '평점'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _StatCard(value: '58', label: '즐겨찾기'),
              ),
            ],
          ),
          SizedBox(height: 28),
          Text(
            '선호하는 장르',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              Chip(label: Text('드라마')),
              Chip(label: Text('SF')),
              Chip(label: Text('애니메이션')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: AppColors.primaryContainer,
          backgroundImage: AssetImage(
            'assets/images/profile/profile_movielog.jpg',
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          '무비러버',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          '매주 주말엔 영화관으로 출근하는 프로 관람객.\n좋은 영화를 보고 기록하는 것을 좋아합니다.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: _noop, child: const Text('프로필 수정')),
      ],
    );
  }

  static void _noop() {}
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4FF),
        border: Border.all(color: AppColors.primaryContainer),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 7),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
