import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_movie_dto.dart';
import '../view_models/favorite_detail_view_model.dart';
import '../view_models/movie_detail_view_model.dart';
import '../widgets/favorite_button.dart';
import '../widgets/movielog_button.dart';
import '../widgets/tmdb_poster_image.dart';
import 'data/mock_movies.dart';
import 'widgets/movie_rating_dialog.dart';

const _detailBackground = Color(0xFFFEFCF9);
const _detailPrimary = Color(0xFF6750A4);
const _detailText = Color(0xFF25232A);
const _detailSecondary = Color(0xFF655F6C);

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({
    super.key,
    required this.movieId,
    this.movie,
    this.genreNames = const [],
    this.imageAsset,
  });

  final String movieId;
  final TmdbMovieDto? movie;
  final List<String> genreNames;
  final String? imageAsset;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<FavoriteDetailViewModel>().load();
    });
  }

  Future<void> _showRatingDialog() async {
    final viewModel = context.read<MovieDetailViewModel>();
    final favorites = context.read<FavoriteDetailViewModel>();
    if (!favorites.isCurrent ||
        !favorites.hasLoadedStatus ||
        favorites.isLoading ||
        favorites.isSaving) {
      return;
    }
    final alreadyFavorite = favorites.isFavorite;
    final saved = await showDialog<Object>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MovieRatingDialog(
        showAddToFavorite: !alreadyFavorite,
        onSubmit: (score, comment, addToFavorites) => alreadyFavorite
            ? viewModel.createRating(score: score, comment: comment)
            : viewModel.createMovieRecord(
                score: score,
                comment: comment,
                addToFavorites: addToFavorites,
              ),
      ),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('평점을 저장했습니다.')));
      await favorites.load();
    } else if (saved is RatingSubmissionException && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(saved.message)));
      if (saved.closeDialog) await favorites.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteDetailViewModel>();
    final movie = widget.movie;
    final example = movie == null
        ? findMovieById(int.tryParse(widget.movieId))
        : null;
    final hasMovie = movie != null || example != null;
    final year = movie?.releaseDate?.split('-').first;
    final genres = widget.genreNames.isNotEmpty
        ? widget.genreNames
        : movie?.genreNames ?? const <String>[];
    final metadata = movie == null
        ? '${example?.year ?? ''} · ${example?.genre ?? ''}'
        : [if (year != null && year.isNotEmpty) year, ...genres].join(' · ');
    final overview = movie == null
        ? '서로의 일상에 스며든 두 사람의 이야기.'
        : movie.overview.trim().isEmpty
        ? '영화 소개가 준비 중입니다.'
        : movie.overview.trim();
    final imageAsset = widget.imageAsset ?? example?.posterAsset;

    return Scaffold(
      backgroundColor: _detailBackground,
      appBar: AppBar(
        backgroundColor: _detailBackground,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        centerTitle: true,
        leading: IconButton(
          tooltip: '뒤로 가기',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/movies');
            }
          },
          icon: SvgPicture.asset(
            'assets/icons/arrow_back.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(_detailText, BlendMode.srcIn),
          ),
        ),
        title: const Text(
          '영화 상세',
          style: TextStyle(
            color: _detailPrimary,
            fontSize: 20,
            height: 1.35,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: !hasMovie
          ? const Center(child: Text('영화를 찾을 수 없습니다.'))
          : SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageAsset != null
                                ? Image.asset(
                                    imageAsset,
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                  )
                                : TmdbPosterImage(
                                    posterPath:
                                        movie?.backdropPath ??
                                        movie?.posterPath,
                                    width: double.infinity,
                                    height: 220,
                                  ),
                          ),
                          const SizedBox(height: 17),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 3),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        movie?.title ?? example!.title,
                                        style: const TextStyle(
                                          fontSize: 25,
                                          height: 34 / 25,
                                          fontWeight: FontWeight.w700,
                                          color: _detailText,
                                        ),
                                      ),
                                      if (metadata.isNotEmpty) ...[
                                        const SizedBox(height: 13),
                                        Text(
                                          metadata,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            height: 18 / 13,
                                            color: _detailSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const FavoriteButton(),
                            ],
                          ),
                          const SizedBox(height: 26),
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 80),
                            child: Text(
                              overview,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 26 / 14,
                                color: _detailSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          MovieLogButton(
                            label: '평점 남기기',
                            width: double.infinity,
                            backgroundColor: _detailPrimary,
                            onPressed:
                                favorites.isCurrent &&
                                    favorites.hasLoadedStatus &&
                                    !favorites.isLoading &&
                                    !favorites.isSaving
                                ? _showRatingDialog
                                : null,
                          ),
                          const _FavoriteErrorNotice(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _FavoriteErrorNotice extends StatelessWidget {
  const _FavoriteErrorNotice();

  @override
  Widget build(BuildContext context) => Consumer<FavoriteDetailViewModel>(
    builder: (context, vm, _) {
      final error = vm.errorMessage;
      if (error == null || vm.isLoading || vm.isSaving || !vm.isCurrent) {
        return const SizedBox.shrink();
      }
      final message = error == '즐겨찾기 등록에 실패했습니다.' || error == '즐겨찾기 해제에 실패했습니다.'
          ? '저장하지 못했습니다. 다시 시도해 주세요.'
          : error;
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Semantics(
          liveRegion: true,
          child: Container(
            alignment: Alignment.centerLeft,
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                height: 18 / 13,
                color: Color(0xFFB3261E),
              ),
            ),
          ),
        ),
      );
    },
  );
}
