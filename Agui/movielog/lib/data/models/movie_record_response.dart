import 'favorite_response_dto.dart';
import 'rating_dto.dart';

class MovieRecordResponseDto {
  const MovieRecordResponseDto({required this.rating, this.favorite});

  final RatingDto rating;
  final FavoriteResponseDto? favorite;

  factory MovieRecordResponseDto.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['rating'] is! Map<String, dynamic>) {
      throw const FormatException('영화 기록 응답 형식이 올바르지 않습니다.');
    }
    return MovieRecordResponseDto(
      rating: RatingDto.fromJson(value['rating'] as Map<String, dynamic>),
      favorite: value['favorite'] == null
          ? null
          : FavoriteResponseDto.fromJson(value['favorite']),
    );
  }
}
