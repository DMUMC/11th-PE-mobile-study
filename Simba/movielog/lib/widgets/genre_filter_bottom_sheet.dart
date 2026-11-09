import 'package:flutter/material.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../theme/app_colors.dart';

/// 3주차에 만든 드래그 가능한 장르 필터 BottomSheet를 TMDB 장르(id/name)로 재사용한다.
/// 확인을 누르면 선택된 장르 ID 목록을 반환하고, 바깥을 눌러 닫으면 null을 반환한다.
class GenreFilterBottomSheet extends StatefulWidget {
  const GenreFilterBottomSheet({
    super.key,
    required this.genres,
    required this.initialSelectedIds,
  });

  final List<TmdbGenreDto> genres;
  final List<int> initialSelectedIds;

  static Future<List<int>?> show(
    BuildContext context, {
    required List<TmdbGenreDto> genres,
    required List<int> initialSelectedIds,
  }) {
    return showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.warmWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => GenreFilterBottomSheet(
        genres: genres,
        initialSelectedIds: initialSelectedIds,
      ),
    );
  }

  @override
  State<GenreFilterBottomSheet> createState() => _GenreFilterBottomSheetState();
}

class _GenreFilterBottomSheetState extends State<GenreFilterBottomSheet> {
  late final Set<int> _tempSelectedIds;

  @override
  void initState() {
    super.initState();
    _tempSelectedIds = {...widget.initialSelectedIds};
  }

  void _toggle(int genreId, bool checked) {
    setState(() {
      if (checked) {
        _tempSelectedIds.add(genreId);
      } else {
        _tempSelectedIds.remove(genreId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '장르 필터',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                '여러 장르를 선택할 수 있어요',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 12),
              // 스크롤 가능한 장르 목록 영역
              Expanded(
                child: Scrollbar(
                  controller: scrollController,
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: widget.genres.length,
                    itemBuilder: (context, index) {
                      final genre = widget.genres[index];
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.violet,
                        title: Text(genre.name),
                        value: _tempSelectedIds.contains(genre.id),
                        onChanged: (checked) => _toggle(genre.id, checked ?? false),
                      );
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // 하단 고정 확인 버튼: 선택이 비어 있으면 빈 목록(= 전체)을 반환한다.
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.violet,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final orderedIds = [
                      for (final genre in widget.genres)
                        if (_tempSelectedIds.contains(genre.id)) genre.id,
                    ];
                    Navigator.pop(context, orderedIds);
                  },
                  child: const Text(
                    '확인',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
