import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  final List<String> _availableGenres = [
    '드라마', 'SF', '애니메이션', '스릴러', '로맨스', '코미디', '판타지', '다큐멘터리'
  ];
  List<String> _selectedGenres = [];

  List<Movie> get _filteredMovies {
    if (_selectedGenres.isEmpty) return mockMovies;
    return mockMovies.where((m) => _selectedGenres.contains(m.genre)).toList();
  }

  void _openFilterBottomSheet() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return _GenreFilterBottomSheet(
          availableGenres: _availableGenres,
          initialSelected: List.from(_selectedGenres),
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedGenres = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final movies = _filteredMovies;

    return Scaffold(
      appBar: AppBar(
        title: const Text('영화', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _openFilterBottomSheet,
          ),
        ],
      ),
      body: movies.isEmpty
          ? const Center(child: Text('해당 장르의 영화가 없습니다.'))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                itemCount: movies.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (context, index) {
                  final movie = movies[index];
                  return MovieCard(
                    movie: movie,
                    onTap: () => context.push('/movies/${movie.id}'),
                  );
                },
              ),
            ),
    );
  }
}

// 드래그 가능한 장르 필터 BottomSheet
class _GenreFilterBottomSheet extends StatefulWidget {
  const _GenreFilterBottomSheet({
    required this.availableGenres,
    required this.initialSelected,
  });

  final List<String> availableGenres;
  final List<String> initialSelected;

  @override
  State<_GenreFilterBottomSheet> createState() => _GenreFilterBottomSheetState();
}

class _GenreFilterBottomSheetState extends State<_GenreFilterBottomSheet> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
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
              const Text('장르 필터', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('여러 장르를 선택할 수 있어요', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 12),
              // 스크롤 가능한 장르 목록 영역
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.availableGenres.length,
                  itemBuilder: (context, index) {
                    final genre = widget.availableGenres[index];
                    final isChecked = _tempSelected.contains(genre);
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(genre),
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _tempSelected.add(genre);
                          } else {
                            _tempSelected.remove(genre);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              // 하단 고정 확인 버튼
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context, _tempSelected);
                  },
                  child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}