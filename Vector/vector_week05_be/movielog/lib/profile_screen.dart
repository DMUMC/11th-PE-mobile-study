import 'package:flutter/material.dart';

import 'models/movie.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.store});
  final MovieLogStore store;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('내 프로필')),
      body: ListView(
        key: const PageStorageKey('profile-scroll'),
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
        children: [
          Center(
            child: Container(
              width: 128,
              height: 128,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD5BBFA),
              ),
              child: const ClipOval(
                child: Image(
                  image: AssetImage(
                    'assets/images/profile/profile_movielog.jpg',
                  ),
                  fit: BoxFit.cover,
                  alignment: Alignment(0, -0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            store.nickname,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            store.bio,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.65,
              color: Color(0xFF49454F),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => EditProfileDialog(store: store),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(122, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                '프로필 수정',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Expanded(
                child: StatItem(label: '본 영화', value: '342'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatItem(
                  label: '평점',
                  value: store.ratings.isEmpty
                      ? '4.2'
                      : (store.ratings.values.reduce((a, b) => a + b) /
                                store.ratings.length)
                            .toStringAsFixed(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatItem(
                  label: '즐겨찾기',
                  value: '${58 + store.favorites.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            '선호하는 장르',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GenreChip(label: '드라마'),
              GenreChip(label: 'SF'),
              GenreChip(label: '애니메이션'),
            ],
          ),
        ],
      ),
    ),
  );
}

class StatItem extends StatelessWidget {
  const StatItem({super.key, required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F2FC),
      border: Border.all(color: const Color(0xFFE7DCF7)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF49454F),
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF503984),
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class GenreChip extends StatelessWidget {
  const GenreChip({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(
      label,
      style: const TextStyle(
        color: Color(0xFF210B4A),
        fontWeight: FontWeight.bold,
      ),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    backgroundColor: const Color(0xFFE9DDFB),
  );
}

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key, required this.store});
  final MovieLogStore store;
  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.store.nickname);
  late final bio = TextEditingController(text: widget.store.bio);
  @override
  void dispose() {
    name.dispose();
    bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('프로필 수정'),
    content: SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              maxLength: 20,
              decoration: const InputDecoration(labelText: '닉네임'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '닉네임을 입력해주세요.' : null,
            ),
            TextFormField(
              controller: bio,
              maxLength: 150,
              maxLines: 3,
              decoration: const InputDecoration(labelText: '소개'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('취소'),
      ),
      ElevatedButton(
        onPressed: () {
          if (formKey.currentState!.validate()) {
            widget.store.updateProfile(name.text.trim(), bio.text.trim());
            Navigator.pop(context);
          }
        },
        child: const Text('저장'),
      ),
    ],
  );
}
