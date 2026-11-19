import {
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class UpdateRatingDto {
  @IsInt({ message: 'score는 정수여야 합니다.' })
  @Min(1, { message: 'score는 1~5여야 합니다.' })
  @Max(5, { message: 'score는 1~5여야 합니다.' })
  score: number;

  @IsOptional()
  @IsString({ message: 'comment는 문자열이어야 합니다.' })
  @MaxLength(500, { message: 'comment는 500자 이하여야 합니다.' })
  comment?: string | null;
}

export class CreateRatingDto extends UpdateRatingDto {
  @IsInt({ message: 'movieId는 양의 안전 정수여야 합니다.' })
  @Min(1, { message: 'movieId는 양의 안전 정수여야 합니다.' })
  @Max(Number.MAX_SAFE_INTEGER, {
    message: 'movieId는 양의 안전 정수여야 합니다.',
  })
  movieId: number;
}
