import 'package:flutter/foundation.dart';

import '../data/models/rating_dto.dart';

/// 현재 로그인 세션에서 등록한 평점을 메모리에 보관한다.
///
/// v7에는 로그인·내 정보 응답에 memberId가 없고, 토큰 기반 "내 평점 목록 GET"도 없다.
/// 그래서 등록 응답으로 받은 Rating만 이 세션에서 수정·삭제할 수 있다.
/// 로그아웃·만료·다른 계정 로그인 시 비우며, 앱을 재시작하면 복원되지 않는다.
class SessionRatingsStore extends ChangeNotifier {
  final List<RatingDto> _ratings = [];

  /// 최신 등록 순(ratingId 내림차순)
  List<RatingDto> get ratings => List.unmodifiable(_ratings);
  bool get isEmpty => _ratings.isEmpty;

  /// 등록·수정 응답의 Rating으로 추가하거나 교체한다.
  void upsert(RatingDto rating) {
    _ratings.removeWhere((r) => r.ratingId == rating.ratingId);
    _ratings.add(rating);
    _ratings.sort((a, b) => b.ratingId.compareTo(a.ratingId));
    notifyListeners();
  }

  void remove(int ratingId) {
    final before = _ratings.length;
    _ratings.removeWhere((r) => r.ratingId == ratingId);
    if (_ratings.length != before) notifyListeners();
  }

  void clear() {
    if (_ratings.isEmpty) return;
    _ratings.clear();
    notifyListeners();
  }
}
