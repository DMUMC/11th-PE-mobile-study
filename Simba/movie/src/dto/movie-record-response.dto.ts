import { FavoriteResponseDto } from './favorite-response.dto';
import { RatingResponseDto } from './rating-response.dto';

// addToFavorites가 false면 favorite은 null이다.
export class MovieRecordResponseDto {
  rating: RatingResponseDto;
  favorite: FavoriteResponseDto | null;
}
