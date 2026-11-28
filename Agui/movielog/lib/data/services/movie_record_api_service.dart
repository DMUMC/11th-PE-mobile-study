import 'package:dio/dio.dart';

import '../models/common_response.dart';
import '../models/movie_record_request.dart';
import '../models/movie_record_response.dart';

class MovieRecordApiService {
  MovieRecordApiService(this._authDio);
  final Dio _authDio;

  Future<MovieRecordResponseDto> createMovieRecord(
    CreateMovieRecordRequest request,
  ) async {
    final response = await _authDio.post<dynamic>(
      '/v8/movie-records',
      data: request.toJson(),
    );
    final data = response.data;
    if (response.statusCode != 201 || data is! Map<String, dynamic>) {
      throw const FormatException('영화 기록 저장 결과를 확인하지 못했습니다.');
    }
    final body = CommonResponse<MovieRecordResponseDto>.fromJson(
      data,
      MovieRecordResponseDto.fromJson,
    );
    final result = body.result;
    if (!body.isSuccess ||
        result == null ||
        result.rating.movieId != request.movieId ||
        (result.favorite != null &&
            result.favorite!.movieId != request.movieId) ||
        request.addToFavorites != (result.favorite != null)) {
      throw const FormatException('영화 기록 저장 결과가 요청과 일치하지 않습니다.');
    }
    return result;
  }
}
