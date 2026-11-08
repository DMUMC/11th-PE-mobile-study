import {
  IsDefined,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

// POST /members/{memberId}/ratings 요청 본문
export class CreateRatingDto {
  // TMDB 영화 id. movie 테이블이 없으므로 FK가 아니라 양의 정수인지만 확인한다.
  @IsDefined({ message: 'movieId는 필수입니다.' })
  @IsInt({ message: 'movieId는 정수여야 합니다.' })
  @Min(1, { message: 'movieId는 양의 정수여야 합니다.' })
  movieId: number;

  @IsDefined({ message: 'score는 필수입니다.' })
  @IsInt({ message: 'score는 정수여야 합니다.' })
  @Min(1, { message: 'score는 1 이상이어야 합니다.' })
  @Max(5, { message: 'score는 5 이하여야 합니다.' })
  score: number;

  @IsOptional()
  @IsString({ message: 'comment는 문자열이어야 합니다.' })
  @MaxLength(500, { message: 'comment는 500자 이하여야 합니다.' })
  comment?: string | null;
}

// PATCH /members/{memberId}/ratings/{ratingId} 요청 본문
// 보낸 필드만 수정한다. movieId는 바꿀 수 없으므로 DTO에 없다(보내면 forbidNonWhitelisted로 400).
export class UpdateRatingDto {
  @IsOptional()
  @IsInt({ message: 'score는 정수여야 합니다.' })
  @Min(1, { message: 'score는 1 이상이어야 합니다.' })
  @Max(5, { message: 'score는 5 이하여야 합니다.' })
  score?: number;

  // null을 보내면 코멘트를 지운다.
  @IsOptional()
  @IsString({ message: 'comment는 문자열이어야 합니다.' })
  @MaxLength(500, { message: 'comment는 500자 이하여야 합니다.' })
  comment?: string | null;
}
