import 'package:flutter/material.dart';

class GenreFilter extends StatelessWidget {
  const GenreFilter({
    super.key,
    required this.selectedGenre,
    required this.onChanged,
  });
  final String selectedGenre;
  final ValueChanged<String> onChanged;
  static const genres = ['전체', '드라마', 'SF', '애니메이션', '스릴러', '로맨스', '다큐멘터리'];

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: genres.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final selected = selectedGenre == genres[index];
        return ChoiceChip(
          label: Text(genres[index]),
          selected: selected,
          showCheckmark: false,
          selectedColor: Theme.of(context).colorScheme.primary,
          backgroundColor: const Color(0xFFE6E0E9),
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
          onSelected: (_) => onChanged(genres[index]),
        );
      },
    ),
  );
}
