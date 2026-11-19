import 'package:flutter/material.dart';

class MoviePoster extends StatelessWidget {
  const MoviePoster({super.key, required this.source});
  final String source;
  @override
  Widget build(BuildContext context) {
    Widget fallback() => ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Center(child: Icon(Icons.movie_outlined, size: 48)),
    );
    if (source.isEmpty) return fallback();
    if (source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : fallback(),
      );
    }
    return Image.asset(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback(),
    );
  }
}
