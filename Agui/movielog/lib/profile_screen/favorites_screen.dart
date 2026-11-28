import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/favorite_list_item.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../theme/app_theme.dart';
import '../view_models/load_phase.dart';
import '../view_models/favorites_view_model.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster_image.dart';

/// Connects the existing screen to the current account's API-backed state.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoritesViewModel>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) => Consumer<FavoritesViewModel>(
    builder: (context, vm, _) => FavoritesScreen(
      phase: vm.phase,
      items: vm.items,
      errorMessage: vm.errorMessage,
      onRefresh: vm.refresh,
      onRetryMovie: vm.retryMovie,
      retryingMovieIds: vm.retryingMovieIds,
    ),
  );
}

/// Display-only screen; development previews can still supply example data.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    super.key,
    this.phase = LoadPhase.empty,
    this.items = const [],
    this.errorMessage,
    this.onRefresh,
    this.onOpenMovie,
    this.onRetryMovie,
    this.retryingMovieIds = const {},
    this.posterAssets = const {},
  });

  final LoadPhase phase;
  final List<FavoriteListItem> items;
  final String? errorMessage;
  final Future<void> Function()? onRefresh;
  final Future<void> Function(TmdbMovieDto movie)? onOpenMovie;
  final Future<void> Function(int movieId)? onRetryMovie;
  final Set<int> retryingMovieIds;

  // Optional local images for offline previews; API data uses TmdbPosterImage.
  final Map<int, String> posterAssets;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const background = Color(0xFFFEFCF9);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        toolbarHeight: AppComponentHeight.appBar,
        centerTitle: true,
        leading: IconButton(
          tooltip: '뒤로 가기',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, size: 24),
        ),
        title: Text(
          '내 즐겨찾기',
          style: TextStyle(
            fontSize: 20,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: colors.primary,
          ),
        ),
      ),
      body: SafeArea(child: _body(context)),
    );
  }

  Widget _body(BuildContext context) {
    if (phase == LoadPhase.idle || phase == LoadPhase.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (phase == LoadPhase.error) {
      return _FavoritesStatus(
        message: errorMessage ?? '즐겨찾기를 불러오지 못했습니다.',
        onRetry: onRefresh,
      );
    }
    if (phase == LoadPhase.empty || items.isEmpty) {
      return const _FavoritesStatus(
        isEmpty: true,
        message: '아직 즐겨찾기한 영화가 없습니다.',
      );
    }

    final list = ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        final movie = item.movie;
        return _FavoriteMovieCard(
          key: ValueKey(item.favorite.favoriteId),
          item: item,
          posterAsset: posterAssets[item.favorite.movieId],
          isRetrying: retryingMovieIds.contains(item.favorite.movieId),
          onRetry: onRetryMovie == null
              ? onRefresh
              : () => onRetryMovie!(item.favorite.movieId),
          onTap: movie == null
              ? null
              : () async {
                  if (onOpenMovie != null) {
                    await onOpenMovie!(movie);
                  } else {
                    await context.push('/movies/${movie.id}', extra: movie);
                  }
                  if (context.mounted) await onRefresh?.call();
                },
        );
      },
    );
    return onRefresh == null
        ? list
        : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}

class _FavoritesStatus extends StatelessWidget {
  const _FavoritesStatus({
    required this.message,
    this.isEmpty = false,
    this.onRetry,
  });

  final String message;
  final bool isEmpty;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Align(
            alignment: const Alignment(0, -0.24),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEmpty) ...[
                    SvgPicture.asset(
                      'assets/icons/bookmark.svg',
                      width: 32,
                      height: 32,
                      excludeFromSemantics: true,
                      colorFilter: ColorFilter.mode(
                        colors.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                  if (isEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '영화 상세에서 북마크를 눌러보세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 32),
                    MovieLogButton(
                      label: '다시 시도',
                      width: 224,
                      onPressed: onRetry,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteMovieCard extends StatelessWidget {
  const _FavoriteMovieCard({
    super.key,
    required this.item,
    this.posterAsset,
    this.onTap,
    this.onRetry,
    this.isRetrying = false,
  });

  final FavoriteListItem item;
  final String? posterAsset;
  final VoidCallback? onTap;
  final Future<void> Function()? onRetry;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final movie = item.movie;
    final year = movie?.releaseDate?.split('-').first;
    final radius = BorderRadius.circular(12);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 146),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: posterAsset == null
                      ? TmdbPosterImage(
                          posterPath: movie?.posterPath,
                          width: 72,
                          height: 120,
                        )
                      : Image.asset(
                          posterAsset!,
                          width: 72,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        movie?.title ?? '영화 #${item.favorite.movieId}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (year != null && year.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          year,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '즐겨찾기한 영화',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.primary,
                        ),
                      ),
                      if (movie == null) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.errorMessage ?? '영화 정보를 불러오지 못했습니다.',
                          style: const TextStyle(fontSize: 12),
                        ),
                        TextButton(
                          onPressed: isRetrying ? null : onRetry,
                          child: isRetrying
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('정보 재조회'),
                        ),
                      ],
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
}
