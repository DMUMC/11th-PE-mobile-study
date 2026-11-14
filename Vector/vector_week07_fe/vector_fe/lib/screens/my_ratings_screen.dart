import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/movie.dart';
import '../services/member_api.dart';
import '../widgets/movie_poster.dart';
import 'rating_editor.dart';

typedef MovieLookup = Future<Movie> Function(int movieId);
typedef RatingItem = ({MemberRating rating, Movie? movie});

class MyRatingsScreen extends StatefulWidget {
  const MyRatingsScreen({
    super.key,
    required this.api,
    required this.lookup,
    this.memberId = 1,
  });
  final MemberApi api;
  final MovieLookup lookup;
  final int? memberId;

  @override
  State<MyRatingsScreen> createState() => _MyRatingsScreenState();
}

class _MyRatingsScreenState extends State<MyRatingsScreen> {
  List<RatingItem> _items = [];
  final _selected = <int>{};
  bool _editing = false;
  bool _loading = false;
  bool _deleting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? savedMessage}) async {
    final member = widget.memberId;
    if (_loading || member == null) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final ratings = await widget.api.fetchRatings(member);
      final movies = <int, Future<Movie?>>{};
      final items = await Future.wait(
        ratings.map(
          (rating) async => (
            rating: rating,
            movie: await movies.putIfAbsent(rating.movieId, () async {
              try {
                return await widget.lookup(rating.movieId);
              } on Exception {
                return null;
              }
            }),
          ),
        ),
      );
      if (!mounted) return;
      setState(() => _items = items);
      if (savedMessage != null) _notice('$savedMessage · 재조회 완료');
    } on MemberApiException catch (error) {
      if (!mounted) return;
      if (savedMessage == null && _items.isEmpty) {
        setState(() => _loadError = error.message);
      } else {
        _notice(
          '${savedMessage == null ? '' : '$savedMessage · '}재조회 실패. 새로고침해주세요. ${error.message}',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _cancelEditing() => setState(() {
    _editing = false;
    _selected.clear();
  });

  void _select(int? id, bool selected) {
    if (id == null) return;
    setState(() {
      if (selected) {
        _selected.add(id);
      } else {
        _selected.remove(id);
      }
    });
  }

  String _title(RatingItem item) =>
      item.movie?.title ?? '영화 #${item.rating.movieId}';

  Future<void> _edit(RatingItem item) async {
    final id = item.rating.id;
    if (id == null) return;
    final score = await showRatingEditor(
      context,
      movieTitle: _title(item),
      movieId: item.rating.movieId,
      initialScore: item.rating.score.toInt(),
      save: (score) => widget.api.updateRating(widget.memberId!, id, score),
    );
    if (score == null || !mounted) return;
    setState(() {
      _items = [
        for (final current in _items)
          if (current.rating.id == id)
            (
              rating: MemberRating(
                id: id,
                movieId: item.rating.movieId,
                score: score,
                comment: item.rating.comment,
              ),
              movie: current.movie,
            )
          else
            current,
      ];
    });
    await _load(savedMessage: '수정 성공');
  }

  Future<void> _singleDelete(int id) async {
    final removed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SingleDeleteDialog(
        remove: () => widget.api.deleteRating(widget.memberId!, id),
      ),
    );
    if (removed != true || !mounted) return;
    setState(() => _items.removeWhere((item) => item.rating.id == id));
    await _load(savedMessage: '삭제 성공');
  }

  Future<void> _bulkDelete() async {
    if (_selected.isEmpty || _deleting) return;
    final ids = _selected.toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('평점 삭제'),
        content: Text('선택한 ${ids.length}개의 평점을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      final results = await Future.wait(
        ids.map((id) async {
          try {
            await widget.api.deleteRating(widget.memberId!, id);
            return (id: id, error: null);
          } on MemberApiException catch (error) {
            return (id: id, error: error);
          }
        }),
      );
      if (!mounted) return;
      final deleted = {
        for (final result in results)
          if (result.error == null) result.id,
      };
      setState(() {
        _items.removeWhere((item) => deleted.contains(item.rating.id));
        _selected.removeAll(deleted);
        if (_selected.isEmpty) _editing = false;
      });
      final failed = ids.length - deleted.length;
      if (failed == 0) {
        await _load(savedMessage: '${deleted.length}개 삭제 성공');
      } else if (deleted.isEmpty) {
        _notice('삭제에 실패했습니다. ${results.first.error!.message}');
      } else {
        _notice('${deleted.length}개 삭제 성공 · $failed개 삭제 실패');
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _deleting;
    return PopScope(
      canPop: !blocked,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('내가 등록한 평점'),
          leading: BackButton(
            onPressed: () {
              if (!blocked) {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/profile');
                }
              }
            },
          ),
          actions: [
            IconButton(
              tooltip: '새로고침',
              onPressed:
                  _editing || _loading || blocked || widget.memberId == null
                  ? null
                  : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                if (_loading) const LinearProgressIndicator(),
                Expanded(child: _content()),
                if (_editing)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _selected.isEmpty || blocked
                              ? null
                              : _bulkDelete,
                          child: Text('선택한 ${_selected.length}개 삭제'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (blocked) ...[
              const ModalBarrier(dismissible: false, color: Color(0x66000000)),
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  semanticsLabel: '삭제 중',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _content() {
    if (widget.memberId == null) {
      return Center(
        child: TextButton(
          onPressed: () => context.push('/signup'),
          child: const Text('회원가입'),
        ),
      );
    }
    if (_loadError case final error?) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(_loading ? '평점을 불러오는 중입니다.' : '아직 등록한 평점이 없습니다.'),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _editing ? '${_selected.length}개 선택됨' : '회원 #${widget.memberId}',
            ),
            TextButton(
              onPressed:
                  _loading ||
                      _deleting ||
                      !_items.any((item) => item.rating.id != null)
                  ? null
                  : _editing
                  ? _cancelEditing
                  : () => setState(() => _editing = true),
              child: Text(_editing ? '취소' : '편집'),
            ),
          ],
        ),
        for (final item in _items) _card(item),
      ],
    );
  }

  Widget _card(RatingItem item) {
    final id = item.rating.id;
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (_editing)
              Checkbox(
                value: _selected.contains(id),
                onChanged: id == null || _deleting
                    ? null
                    : (value) => _select(id, value ?? false),
              )
            else
              SizedBox(
                width: 64,
                height: 96,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: MoviePoster(source: item.movie?.image ?? ''),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title(item),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text('별점 ${item.rating.score} / 5'),
                  Text('MovieLog movieId ${item.rating.movieId}'),
                  if (item.rating.comment case final comment?) Text(comment),
                ],
              ),
            ),
            if (!_editing)
              Column(
                children: [
                  TextButton(
                    onPressed: id == null || _loading
                        ? null
                        : () => _edit(item),
                    child: const Text('수정'),
                  ),
                  TextButton(
                    onPressed: id == null || _loading
                        ? null
                        : () => _singleDelete(id),
                    child: const Text('삭제'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SingleDeleteDialog extends StatefulWidget {
  const _SingleDeleteDialog({required this.remove});
  final Future<void> Function() remove;

  @override
  State<_SingleDeleteDialog> createState() => _SingleDeleteDialogState();
}

class _SingleDeleteDialogState extends State<_SingleDeleteDialog> {
  bool _loading = false;
  String? _error;

  Future<void> _delete() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.remove();
      if (mounted) Navigator.pop(context, true);
    } on MemberApiException catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_loading,
    child: AlertDialog(
      title: const Text('평점 삭제'),
      content: Text(_error ?? '이 평점을 삭제할까요?'),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _loading ? null : _delete,
          child: _loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('삭제'),
        ),
      ],
    ),
  );
}
