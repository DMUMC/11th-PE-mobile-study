import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseIntPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ApiOperation, ApiParam, ApiTags } from '@nestjs/swagger';
import { ErrorStatus } from '../common/error-status';
import {
  ApiAuth,
  ApiFailure,
  ApiSuccess,
  ApiValidationFailure,
} from '../common/swagger';
import { LoginMember } from '../decorator/login-member.decorator';
import { CreateFavoriteDto } from '../dto/favorite-request.dto';
import {
  FavoriteResponseDto,
  FavoriteStatusResponseDto,
} from '../dto/favorite-response.dto';
import { AuthGuard } from '../guard/auth.guard';
import { PositiveIntPipe } from '../pipe/positive-int.pipe';
import { FavoriteService } from '../service/favorite.service';

const FAVORITE_EXAMPLE = {
  favoriteId: 3,
  movieId: 550,
  createdAt: '2026-11-22T12:00:00.000Z',
};

// 8주차: 즐겨찾기는 "내" 데이터만 다루므로 모든 API가 토큰을 요구한다.
// memberId는 URL·본문이 아니라 AuthGuard가 검증한 토큰에서만 꺼낸다.
@ApiTags('Favorite')
@ApiAuth()
@Controller('favorites')
@UseGuards(AuthGuard)
export class FavoriteController {
  constructor(private readonly favoriteService: FavoriteService) {}

  // POST /favorites — 즐겨찾기 추가
  @Post()
  @HttpCode(201)
  @ApiOperation({ summary: '즐겨찾기 추가' })
  @ApiSuccess(201, FAVORITE_EXAMPLE)
  @ApiValidationFailure('movieId는 양의 정수여야 합니다.')
  @ApiFailure(ErrorStatus.MEMBER_NOT_FOUND, ErrorStatus.FAVORITE_DUPLICATED)
  addFavorite(
    @LoginMember() memberId: number,
    @Body() dto: CreateFavoriteDto,
  ): Promise<FavoriteResponseDto> {
    return this.favoriteService.addFavorite(memberId, dto);
  }

  // GET /favorites — 내 즐겨찾기 목록 (최신순, 없으면 [])
  @Get()
  @ApiOperation({ summary: '내 즐겨찾기 목록 (favoriteId 내림차순)' })
  @ApiSuccess(200, [FAVORITE_EXAMPLE])
  getMyFavorites(
    @LoginMember() memberId: number,
  ): Promise<FavoriteResponseDto[]> {
    return this.favoriteService.getMyFavorites(memberId);
  }

  // GET /favorites/{movieId} — 이 영화를 즐겨찾기했는지 여부
  @Get(':movieId')
  @ApiOperation({
    summary: '즐겨찾기 여부 확인 (안 했으면 false, 오류 아님)',
  })
  @ApiParam({ name: 'movieId', description: 'TMDB 영화 id', example: 550 })
  @ApiSuccess(200, { isFavorite: true })
  @ApiValidationFailure('movieId는 양의 정수여야 합니다.')
  getFavoriteStatus(
    @LoginMember() memberId: number,
    @Param('movieId', ParseIntPipe, PositiveIntPipe) movieId: number,
  ): Promise<FavoriteStatusResponseDto> {
    return this.favoriteService.getFavoriteStatus(memberId, movieId);
  }

  // DELETE /favorites/{movieId} — 즐겨찾기 해제. 공통 응답을 보내기 위해 200 + result: null.
  @Delete(':movieId')
  @HttpCode(200)
  @ApiOperation({ summary: '즐겨찾기 해제' })
  @ApiParam({ name: 'movieId', description: 'TMDB 영화 id', example: 550 })
  @ApiSuccess(200, null)
  @ApiValidationFailure('movieId는 양의 정수여야 합니다.')
  @ApiFailure(ErrorStatus.FAVORITE_NOT_FOUND)
  async removeFavorite(
    @LoginMember() memberId: number,
    @Param('movieId', ParseIntPipe, PositiveIntPipe) movieId: number,
  ): Promise<null> {
    await this.favoriteService.removeFavorite(memberId, movieId);
    return null;
  }
}
