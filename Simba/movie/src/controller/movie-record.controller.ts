import { Body, Controller, HttpCode, Post, UseGuards } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';
import { ErrorStatus } from '../common/error-status';
import {
  ApiAuth,
  ApiFailure,
  ApiSuccess,
  ApiValidationFailure,
} from '../common/swagger';
import { LoginMember } from '../decorator/login-member.decorator';
import { CreateMovieRecordDto } from '../dto/movie-record-request.dto';
import { MovieRecordResponseDto } from '../dto/movie-record-response.dto';
import { AuthGuard } from '../guard/auth.guard';
import { MovieRecordService } from '../service/movie-record.service';

@ApiTags('MovieRecord')
@ApiAuth()
@Controller('movie-records')
@UseGuards(AuthGuard)
export class MovieRecordController {
  constructor(private readonly movieRecordService: MovieRecordService) {}

  // POST /movie-records — 평점 등록 + (선택) 즐겨찾기 추가를 한 트랜잭션으로 처리
  @Post()
  @HttpCode(201)
  @ApiOperation({
    summary: '영화 기록 (평점 + 즐겨찾기, 하나의 트랜잭션)',
    description:
      '둘 중 하나라도 실패하면 둘 다 저장되지 않는다. addToFavorites가 false면 favorite은 null.',
  })
  @ApiSuccess(201, {
    rating: {
      ratingId: 12,
      movieId: 680,
      score: 5,
      comment: '다시 봐도 명작',
      createdAt: '2026-11-22T12:00:00.000Z',
      updatedAt: '2026-11-22T12:00:00.000Z',
    },
    favorite: {
      favoriteId: 7,
      movieId: 680,
      createdAt: '2026-11-22T12:00:00.000Z',
    },
  })
  @ApiValidationFailure('score는 5 이하여야 합니다.')
  @ApiFailure(
    ErrorStatus.MEMBER_NOT_FOUND,
    ErrorStatus.RATING_DUPLICATED,
    ErrorStatus.FAVORITE_DUPLICATED,
  )
  createMovieRecord(
    @LoginMember() memberId: number,
    @Body() dto: CreateMovieRecordDto,
  ): Promise<MovieRecordResponseDto> {
    return this.movieRecordService.createMovieRecord(memberId, dto);
  }
}
