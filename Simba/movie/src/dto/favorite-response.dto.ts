import { Favorite } from '../entity/favorite.entity';

export class FavoriteResponseDto {
  favoriteId: number;
  movieId: number;
  createdAt: Date;

  static from(favorite: Favorite): FavoriteResponseDto {
    return {
      favoriteId: Number(favorite.favoriteId),
      movieId: Number(favorite.movieId),
      createdAt: favorite.createdAt,
    };
  }
}

// GET /favorites/{movieId} — 즐겨찾기하지 않은 영화도 오류가 아니라 false로 응답한다.
export class FavoriteStatusResponseDto {
  isFavorite: boolean;
}
