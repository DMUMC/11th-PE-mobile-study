import type { Rating } from '../entity/rating.entity.js';
import { toApiId } from './api-id.js';

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
