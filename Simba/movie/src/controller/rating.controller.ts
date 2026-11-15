import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { LoginMember } from '../decorator/login-member.decorator';
import { CreateRatingDto, UpdateRatingDto } from '../dto/rating-request.dto';
import { RatingResponseDto } from '../dto/rating-response.dto';
import { AuthGuard } from '../guard/auth.guard';
import { RatingService } from '../service/rating.service';

// 7주차: 쓰기 API는 "누가"를 URL이 아니라 토큰에서 꺼낸다.
// 조회(members/:memberId/ratings)와 쓰기(ratings/...)의 경로 앞부분이 달라서
// @Controller()에 접두사를 두지 않고 메서드마다 전체 경로를 적는다.
// 경로 id가 숫자가 아니면 ParseIntPipe가 400으로 응답한다.
@Controller()
export class RatingController {
  constructor(private readonly ratingService: RatingService) {}

  // GET /members/{memberId}/ratings — 공개 조회 (토큰 불필요)
  @Get('members/:memberId/ratings')
  getMemberRatings(
    @Param('memberId', ParseIntPipe) memberId: number,
  ): Promise<RatingResponseDto[]> {
    return this.ratingService.getRatingsByMember(memberId);
  }

  // POST /ratings — 내 평점 등록
  @Post('ratings')
  @HttpCode(201)
  @UseGuards(AuthGuard)
  createRating(
    @LoginMember() memberId: number,
    @Body() dto: CreateRatingDto,
  ): Promise<RatingResponseDto> {
    return this.ratingService.createRating(memberId, dto);
  }

  // PATCH /ratings/{ratingId} — 내 평점 수정
  @Patch('ratings/:ratingId')
  @UseGuards(AuthGuard)
  updateRating(
    @LoginMember() memberId: number,
    @Param('ratingId', ParseIntPipe) ratingId: number,
    @Body() dto: UpdateRatingDto,
  ): Promise<RatingResponseDto> {
    return this.ratingService.updateRating(memberId, ratingId, dto);
  }

  // DELETE /ratings/{ratingId} — 내 평점 삭제.
  // 공통 응답 { isSuccess, code, message, result: null }을 보내야 하므로 204가 아니라 200.
  @Delete('ratings/:ratingId')
  @HttpCode(200)
  @UseGuards(AuthGuard)
  async deleteRating(
    @LoginMember() memberId: number,
    @Param('ratingId', ParseIntPipe) ratingId: number,
  ): Promise<null> {
    await this.ratingService.deleteRating(memberId, ratingId);
    return null;
  }
}
