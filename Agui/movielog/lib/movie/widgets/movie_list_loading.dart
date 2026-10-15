import 'package:flutter/material.dart';
import 'package:movielog/theme/app_colors.dart';

class MovieListLoading extends StatefulWidget {
  const MovieListLoading({super.key});

  @override
  State<MovieListLoading> createState() => _MovieListLoadingState();
}

class _MovieListLoadingState extends State<MovieListLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '영화 목록을 불러오는 중',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final color = Color.lerp(
              AppColors.surfaceContainer,
              AppColors.surfaceHighest,
              _pulse.value,
            )!;

            return LayoutBuilder(
              builder: (context, constraints) => GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 6,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.maxWidth >= 700 ? 3 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 28,
                  mainAxisExtent: 312,
                ),
                itemBuilder: (context, index) =>
                    _MovieCardSkeleton(color: color),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MovieCardSkeleton extends StatelessWidget {
  const _MovieCardSkeleton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SkeletonLine(widthFactor: 0.8, height: 16, color: color),
        const SizedBox(height: 8),
        _SkeletonLine(widthFactor: 0.55, height: 12, color: color),
      ],
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.widthFactor,
    required this.height,
    required this.color,
  });

  final double widthFactor;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
