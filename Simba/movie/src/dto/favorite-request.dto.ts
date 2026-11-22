import { ApiProperty } from '@nestjs/swagger';
import { IsDefined, IsInt, Min } from 'class-validator';

// POST /favorites 요청 본문 (memberId는 토큰에서 꺼내므로 받지 않는다)
export class CreateFavoriteDto {
  @ApiProperty({ description: 'TMDB 영화 id (양의 정수)', example: 550 })
  @IsDefined({ message: 'movieId는 필수입니다.' })
  @IsInt({ message: 'movieId는 정수여야 합니다.' })
  @Min(1, { message: 'movieId는 양의 정수여야 합니다.' })
  movieId: number;
}
