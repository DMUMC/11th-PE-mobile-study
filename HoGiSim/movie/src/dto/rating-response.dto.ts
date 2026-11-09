import { InternalServerErrorException } from '@nestjs/common';
import type { Rating } from '../entity/rating.entity.js';

function toApiId(value: string): number {
  const id = Number(value);
  if (!Number.isSafeInteger(id) || id <= 0) {
    throw new InternalServerErrorException(
      '저장된 식별자를 처리할 수 없습니다.',
    );
  }
  return id;
}

export class RatingResponseDto {
  ratingId: number;
  movieId: number;
  score: number;
  comment: string | null;
  createdAt: string;
  updatedAt: string;

  static from(rating: Rating): RatingResponseDto {
    return {
      ratingId: toApiId(rating.ratingId),
      movieId: toApiId(rating.movieId),
      score: rating.score,
      comment: rating.comment,
      createdAt: rating.createdAt.toISOString(),
      updatedAt: rating.updatedAt.toISOString(),
    };
  }
}
