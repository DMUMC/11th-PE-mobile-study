import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../widgets/movie_card.dart';

class MoviesScreen extends StatefulWidget {
  const MoviesScreen({super.key, required this.selectedGenres});
  final Set<String> selectedGenres;
  @override
  State<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends State<MoviesScreen> {
  final searchController = TextEditingController();
  bool searching = false;
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _showFilters() async {
    // 임시 선택은 BottomSheet 안에서만 변경하고 확인 결과만 URL에 적용합니다.
    final selected = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => GenreFilterSheet(selected: widget.selectedGenres),
    );
    if (!mounted || selected == null) return;
    final ordered = movieGenres.where(selected.contains).toList();
    context.go(
      Uri(
        path: '/movies',
        queryParameters: ordered.isEmpty ? null : {'genre': ordered},
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = movies
        .where(
          (movie) =>
              (widget.selectedGenres.isEmpty ||
                  movie.genres.any(widget.selectedGenres.contains)) &&
              movie.title.contains(searchController.text.trim()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('영화'),
        actions: [
          IconButton(
            tooltip: searching ? '검색 닫기' : '영화 검색',
            onPressed: () => setState(() {
              searching = !searching;
              if (!searching) searchController.clear();
            }),
            icon: Icon(searching ? Icons.close : Icons.search),
          ),
          IconButton(
            tooltip: '장르 필터',
            onPressed: _showFilters,
            icon: Badge(
              isLabelVisible: widget.selectedGenres.isNotEmpty,
              label: Text('${widget.selectedGenres.length}'),
              child: const Icon(Icons.filter_list),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (searching)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                controller: searchController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '영화 제목을 검색하세요',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          if (widget.selectedGenres.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '선택 장르: ${movieGenres.where(widget.selectedGenres.contains).join(' · ')}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          Expanded(
            child: visible.isEmpty
                ? const Center(child: Text('조건에 맞는 영화가 없습니다.'))
                : LayoutBuilder(
                    builder: (context, constraints) => GridView.builder(
                      key: const PageStorageKey('movies-scroll'),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                        mainAxisExtent:
                            (constraints.maxWidth - 48) / 2 * 1.5 +
                            72 * MediaQuery.textScalerOf(context).scale(1),
                      ),
                      itemCount: visible.length,
                      itemBuilder: (context, index) => MovieCard(
                        movie: visible[index],
                        onTap: () {
                          final query = GoRouterState.of(context).uri.query;
                          context.go(
                            '/movies/${visible[index].id}${query.isEmpty ? '' : '?$query'}',
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class GenreFilterSheet extends StatefulWidget {
  const GenreFilterSheet({super.key, required this.selected});
  final Set<String> selected;
  @override
  State<GenreFilterSheet> createState() => _GenreFilterSheetState();
}

class _GenreFilterSheetState extends State<GenreFilterSheet> {
  late final Set<String> draft = {...widget.selected};
  final sheetController = DraggableScrollableController();
  @override
  void dispose() {
    sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => DraggableScrollableSheet(
      controller: sheetController,
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (details) => sheetController.jumpTo(
              (sheetController.size - details.delta.dy / constraints.maxHeight)
                  .clamp(0.35, 0.9),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCAC4D0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 12, 4),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '장르 선택',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(draft.clear),
                        child: const Text('전체 해제'),
                      ),
                      IconButton(
                        tooltip: '필터 닫기',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('여러 장르를 선택할 수 있어요.'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: movieGenres.length,
              itemBuilder: (context, index) {
                final genre = movieGenres[index];
                return CheckboxListTile(
                  title: Text(genre),
                  value: draft.contains(genre),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (checked) => setState(() {
                    checked == true ? draft.add(genre) : draft.remove(genre);
                  }),
                );
              },
            ),
          ),
          const Divider(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, draft),
                  child: Text(
                    draft.isEmpty
                        ? '확인 · 전체 영화 보기'
                        : '확인 · ${draft.length}개 장르 적용',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
