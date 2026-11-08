import { Rating } from '../entity/rating.entity';

// API 명세의 응답 모양. Entity를 그대로 내보내지 않고 화면에 필요한 값만 담는다.
export class RatingResponseDto {
  ratingId: number;
  movieId: number;
  score: number;
  comment: string | null;
  createdAt: Date;
  updatedAt: Date;

  static from(rating: Rating): RatingResponseDto {
    return {
      // BIGINT 컬럼이 문자열로 오더라도 명세대로 number로 응답한다.
      ratingId: Number(rating.ratingId),
      movieId: Number(rating.movieId),
      score: rating.score,
      comment: rating.comment,
      createdAt: rating.createdAt,
      updatedAt: rating.updatedAt,
    };
  }
}
