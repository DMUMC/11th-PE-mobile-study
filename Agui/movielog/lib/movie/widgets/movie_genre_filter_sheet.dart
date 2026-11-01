import 'package:flutter/material.dart';
import 'package:movielog/data/models/tmdb_genre_dto.dart';
import 'package:movielog/theme/app_colors.dart';

class MovieGenreFilterSheet extends StatefulWidget {
  const MovieGenreFilterSheet({
    required this.genres,
    required this.selectedGenreIds,
    super.key,
  });

  final List<TmdbGenreDto> genres;
  final List<int>? selectedGenreIds;

  @override
  State<MovieGenreFilterSheet> createState() => _MovieGenreFilterSheetState();
}

class _MovieGenreFilterSheetState extends State<MovieGenreFilterSheet> {
  late final List<int> _draftGenreIds = [...?widget.selectedGenreIds];
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      snap: true,
      snapSizes: const [0.55, 0.92],
      controller: _sheetController,
      builder: (context, scrollController) {
        return Material(
          color: AppColors.surfaceBase,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  if (!_sheetController.isAttached) return;
                  final screenHeight = MediaQuery.sizeOf(context).height;
                  final nextSize =
                      (_sheetController.size - details.delta.dy / screenHeight)
                          .clamp(0.35, 0.92);
                  _sheetController.jumpTo(nextSize);
                },
                onVerticalDragEnd: (details) {
                  if (!_sheetController.isAttached) return;
                  final velocityY = details.velocity.pixelsPerSecond.dy;
                  final target = velocityY < -100
                      ? 0.92
                      : velocityY > 100
                      ? 0.55
                      : _sheetController.size >= 0.72
                      ? 0.92
                      : 0.55;
                  _sheetController.animateTo(
                    target,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.neutral400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '장르 필터',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '원하는 장르를 여러 개 선택해 주세요',
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          color: AppColors.secondary500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.surfaceContainer),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.genres.length,
                  itemBuilder: (context, index) {
                    final genre = widget.genres[index];
                    return CheckboxListTile(
                      value: _draftGenreIds.contains(genre.id),
                      title: Text(genre.name, textAlign: TextAlign.left),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      visualDensity: const VisualDensity(
                        horizontal: -2,
                        vertical: -2,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      activeColor: AppColors.primary600,
                      onChanged: (checked) {
                        setState(() {
                          if (checked ?? false) {
                            _draftGenreIds.add(genre.id);
                          } else {
                            _draftGenreIds.remove(genre.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context)
                              .pop(List<int>.of(_draftGenreIds)),
                      child: const Text('확인'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
