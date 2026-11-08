import 'package:flutter/material.dart';

import '../widgets/movielog_button.dart';

class ButtonWidthsScreen extends StatelessWidget {
  const ButtonWidthsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MovieLogButton 너비 비교')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            for (final (caption, width) in [
              ('null · 내용에 맞춤', null),
              ('double.infinity · 부모 너비 채움', double.infinity),
              ('200 · 고정 너비', 200.0),
            ])
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(caption),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: MovieLogButton(
                          label: '중복 확인',
                          width: width,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
