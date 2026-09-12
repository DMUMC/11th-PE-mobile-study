import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 16
          ),
          child: Column(
            children: [
              const Text(
                'FLUTTER 0주차',
                textAlign: TextAlign.center
                ),

              const SizedBox(height: 50),

              const Icon(
                Icons.movie_outlined,
                size: 72,
                color: Colors.deepPurple,
              ),

              const SizedBox(height: 50),

              const Text(
                '영화의 순간을\n기록하세요',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Text(
                '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                textAlign: TextAlign.center
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: () {
                  debugPrint('시작하기 버튼을 눌렀습니다.');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)
                  ),
                ),
                child: const Text('시작하기'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
