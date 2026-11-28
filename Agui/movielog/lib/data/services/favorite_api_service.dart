import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/favorite_check_dto.dart';
import '../models/favorite_response_dto.dart';

class FavoriteApiService {
  FavoriteApiService(this._dio);
  final Dio _dio;

  T? _result<T>(Object? data, T Function(Object?) parse) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('즐겨찾기 응답 형식이 올바르지 않습니다.');
    }
    final body = CommonResponse<T>.fromJson(data, parse);
    if (!body.isSuccess) {
      throw const FormatException('즐겨찾기 요청 결과를 확인하지 못했습니다.');
    }
    return body.result;
  }

  Future<FavoriteResponseDto> addFavorite({required int movieId}) async {
    final response = await _dio.post<dynamic>(
      '/v8/favorites',
      data: {'movieId': movieId},
    );
    if (response.statusCode != 201) {
      throw const FormatException('즐겨찾기 등록 결과를 확인하지 못했습니다.');
    }
    final favorite = _result(response.data, FavoriteResponseDto.fromJson);
    if (favorite == null || favorite.movieId != movieId) {
      throw const FormatException('즐겨찾기 영화 ID가 일치하지 않습니다.');
    }
    return favorite;
  }

  Future<List<FavoriteResponseDto>> fetchMyFavorites() async {
    final response = await _dio.get<dynamic>('/v8/favorites');
    final items = _result<List<FavoriteResponseDto>>(response.data, (value) {
      if (value is! List) {
        throw const FormatException('즐겨찾기 목록은 배열이어야 합니다.');
      }
      return value.map(FavoriteResponseDto.fromJson).toList();
    });
    return items ?? (throw const FormatException('즐겨찾기 목록이 없습니다.'));
  }

  Future<FavoriteCheckDto> checkFavorite({required int movieId}) async {
    final response = await _dio.get<dynamic>('/v8/favorites/$movieId');
    return _result(
          response.data,
          (value) => FavoriteCheckDto.fromJson(value, movieId: movieId),
        ) ??
        (throw const FormatException('즐겨찾기 여부가 없습니다.'));
  }

  Future<void> deleteFavorite({required int movieId}) async {
    final response = await _dio.delete<dynamic>('/v8/favorites/$movieId');
    if (response.statusCode != 200 ||
        _result<Object?>(response.data, (value) => value) != null) {
      throw const FormatException('즐겨찾기 해제 결과를 확인하지 못했습니다.');
    }
  }
}
