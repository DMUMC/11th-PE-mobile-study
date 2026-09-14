import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 64, 32, 56),
          child: Column(
            children: [
              const Text(
                'FLUTTER 0주차',
                style: TextStyle(
                  color: Color(0xFF333333),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.9,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 64),
              const Icon(
                Icons.movie_outlined,
                color: Color(0xFF4B3B8D),
                size: 56,
                semanticLabel: 'MovieLog 영화 아이콘',
              ),
              const SizedBox(height: 68),
              const Text(
                '영화의 순간을\n기록하세요',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF202020),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.22,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF5C5C5C),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('시작하기 버튼을 눌렀습니다.');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B3B8D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '시작하기',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
