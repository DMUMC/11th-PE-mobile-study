import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/member_api.dart';
import '../widgets/movielog_button.dart';

typedef MovieLookup = Future<Movie> Function(int movieId);

sealed class MyRatingsState {
  const MyRatingsState();
}

class RatingsLoading extends MyRatingsState {
  const RatingsLoading();
}

class RatingsEmpty extends MyRatingsState {
  const RatingsEmpty();
}

class RatingsError extends MyRatingsState {
  const RatingsError(this.message);
  final String message;
}

class RatingsSuccess extends MyRatingsState {
  const RatingsSuccess(this.items);
  final List<({MemberRating rating, Movie movie})> items;
}

class MyRatingsViewModel extends ChangeNotifier {
  MyRatingsViewModel(this.api, this.lookup);
  static const memberId = 1;

  final MemberApi api;
  final MovieLookup lookup;
  MyRatingsState _state = const RatingsLoading();
  MyRatingsState get state => _state;
  int _request = 0;

  Future<void> load() async {
    final request = ++_request;
    _state = const RatingsLoading();
    notifyListeners();
    MyRatingsState result;
    try {
      final ratings = await api.fetchRatings(memberId);
      final movies = <int, Future<Movie>>{};
      result = ratings.isEmpty
          ? const RatingsEmpty()
          : RatingsSuccess(
              await Future.wait(
                ratings.map(
                  (rating) async => (
                    rating: rating,
                    movie: await movies.putIfAbsent(
                      rating.movieId,
                      () => lookup(rating.movieId),
                    ),
                  ),
                ),
              ),
            );
    } on MemberApiException catch (error) {
      result = RatingsError(error.message);
    } on Exception {
      result = const RatingsError('평점 또는 영화 정보를 불러오지 못했습니다.');
    }
    if (request != _request) return;
    _state = result;
    notifyListeners();
  }

  @override
  void dispose() {
    _request++;
    super.dispose();
  }
}

class MyRatingsScreen extends StatefulWidget {
  const MyRatingsScreen({super.key, required this.api, required this.lookup});
  final MemberApi api;
  final MovieLookup lookup;

  @override
  State<MyRatingsScreen> createState() => _MyRatingsScreenState();
}

class _MyRatingsScreenState extends State<MyRatingsScreen> {
  late final _model = MyRatingsViewModel(widget.api, widget.lookup);

  @override
  void initState() {
    super.initState();
    _model.load();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('내가 등록한 평점')),
    body: ListenableBuilder(
      listenable: _model,
      builder: (context, _) => switch (_model.state) {
        RatingsLoading() => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('평점을 불러오는 중입니다.'),
            ],
          ),
        ),
        RatingsEmpty() => const Center(child: Text('아직 등록한 평점이 없습니다.')),
        RatingsError(:final message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 36),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                MovieLogButton(label: '다시 시도', onPressed: _model.load),
              ],
            ),
          ),
        ),
        RatingsSuccess(:final items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '회원 #1 · 평점 ${items.length}개',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final item in items)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.movie_outlined),
                  title: Text(item.movie.title),
                  subtitle: Text('TMDB 영화 ID ${item.rating.movieId}'),
                  trailing: Text('★ ${item.rating.score}'),
                ),
              ),
          ],
        ),
      },
    ),
  );
}
