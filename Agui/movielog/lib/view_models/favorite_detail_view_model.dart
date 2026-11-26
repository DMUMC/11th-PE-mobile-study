import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/network/api_error.dart';
import '../core/session/session_guard.dart';
import '../core/utils/safe_notify.dart';
import '../data/services/favorite_api_service.dart';

class FavoriteDetailViewModel extends ChangeNotifier with SafeNotify {
  FavoriteDetailViewModel({
    required this.movieId,
    required this.favoriteApi,
    required this.sessionGuard,
    required this.accountId,
  }) : _sessionGeneration = sessionGuard.generation;

  final int movieId;
  final FavoriteApiService favoriteApi;
  final SessionGuard sessionGuard;
  final String accountId;
  final int _sessionGeneration;

  bool isFavorite = false;
  bool hasLoadedStatus = false;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  bool get isCurrent =>
      !isDisposed && sessionGuard.isCurrent(_sessionGeneration, accountId);

  Future<void> load() async {
    if (!isCurrent || isLoading || isSaving) return;
    isLoading = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      final result = await favoriteApi.checkFavorite(movieId: movieId);
      if (!isCurrent) return;
      isFavorite = result.isFavorite;
      hasLoadedStatus = true;
    } catch (_) {
      if (!isCurrent) return;
      errorMessage = '즐겨찾기 여부를 확인하지 못했습니다.';
    } finally {
      if (isCurrent) {
        isLoading = false;
        notifyIfAlive();
      }
    }
  }

  // A null message means no request was made, or the session has changed.
  Future<String?> toggle() async {
    if (!isCurrent || isSaving || isLoading || !hasLoadedStatus) return null;
    final before = isFavorite;
    isSaving = true;
    errorMessage = null;
    notifyIfAlive();
    try {
      if (before) {
        await favoriteApi.deleteFavorite(movieId: movieId);
      } else {
        await favoriteApi.addFavorite(movieId: movieId);
      }
      if (!isCurrent) return null;
      isFavorite = !before;
    } on DioException catch (error) {
      if (!isCurrent) return null;
      final code = apiErrorCode(error);
      if (code == 'FAVORITE409_1' || code == 'FAVORITE404_1') {
        try {
          final synced = await favoriteApi.checkFavorite(movieId: movieId);
          if (!isCurrent) return null;
          isFavorite = synced.isFavorite;
        } catch (_) {
          if (!isCurrent) return null;
          isFavorite = before;
          errorMessage = '서버 상태를 다시 확인하지 못했습니다.';
        }
      } else {
        isFavorite = before;
        errorMessage = code == 'MEMBER404_1'
            ? '회원 정보를 찾을 수 없습니다.'
            : before
            ? '즐겨찾기 해제에 실패했습니다.'
            : '즐겨찾기 등록에 실패했습니다.';
      }
    } catch (_) {
      if (!isCurrent) return null;
      isFavorite = before;
      errorMessage = before ? '즐겨찾기 해제에 실패했습니다.' : '즐겨찾기 등록에 실패했습니다.';
    } finally {
      if (isCurrent) {
        isSaving = false;
        notifyIfAlive();
      }
    }
    if (!isCurrent) return null;
    return errorMessage ?? (isFavorite ? '즐겨찾기에 추가했습니다.' : '즐겨찾기에서 삭제했습니다.');
  }
}
