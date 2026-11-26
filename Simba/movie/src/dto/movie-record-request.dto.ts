import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsDefined,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

// POST /movie-records 요청 본문: 평점 등록과 즐겨찾기 추가를 한 번에 요청한다.
export class CreateMovieRecordDto {
  @ApiProperty({ description: 'TMDB 영화 id (양의 정수)', example: 680 })
  @IsDefined({ message: 'movieId는 필수입니다.' })
  @IsInt({ message: 'movieId는 정수여야 합니다.' })
  @Min(1, { message: 'movieId는 양의 정수여야 합니다.' })
  movieId: number;

  @ApiProperty({ description: '평점 1~5', minimum: 1, maximum: 5, example: 5 })
  @IsDefined({ message: 'score는 필수입니다.' })
  @IsInt({ message: 'score는 정수여야 합니다.' })
  @Min(1, { message: 'score는 1 이상이어야 합니다.' })
  @Max(5, { message: 'score는 5 이하여야 합니다.' })
  score: number;

  @ApiPropertyOptional({
    description: '코멘트 (500자 이하)',
    example: '다시 봐도 명작',
    nullable: true,
  })
  @IsOptional()
  @IsString({ message: 'comment는 문자열이어야 합니다.' })
  @MaxLength(500, { message: 'comment는 500자 이하여야 합니다.' })
  comment?: string | null;

  @ApiProperty({ description: 'true면 즐겨찾기도 함께 추가', example: true })
  @IsDefined({ message: 'addToFavorites는 필수입니다.' })
  @IsBoolean({ message: 'addToFavorites는 true 또는 false여야 합니다.' })
  addToFavorites: boolean;
}
