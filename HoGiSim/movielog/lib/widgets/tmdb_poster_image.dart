import 'package:flutter/material.dart';

class TmdbPosterImage extends StatelessWidget {
  const TmdbPosterImage({
    required this.posterPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    super.key,
  });
  final String? posterPath;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final path = posterPath;
    if (path == null || path.isEmpty) return _placeholder();
    return Image.network(
      'https://image.tmdb.org/t/p/w500$path',
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (_, child, progress) =>
          progress == null ? child : _placeholder(loading: true),
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder({bool loading = false}) => Container(
    key: Key(loading ? 'poster-loading' : 'poster-placeholder'),
    width: width,
    height: height,
    color: const Color(0xFFEAE7F0),
    alignment: Alignment.center,
    child: Icon(
      loading ? Icons.downloading_outlined : Icons.image_not_supported_outlined,
      color: const Color(0xFF777280),
      semanticLabel: loading ? '포스터를 불러오는 중' : '포스터 없음',
    ),
  );
}
