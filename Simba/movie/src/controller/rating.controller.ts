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
} from '@nestjs/common';
import { CreateRatingDto, UpdateRatingDto } from '../dto/rating-request.dto';
import { RatingResponseDto } from '../dto/rating-response.dto';
import { RatingService } from '../service/rating.service';

// 파일은 자원(Rating) 기준으로 나누고, URL은 프론트가 이해하기 쉬운 /members/... 모양을 쓴다.
// 경로 id가 숫자가 아니면 ParseIntPipe가 400으로 응답한다.
@Controller('members/:memberId/ratings')
export class RatingController {
  constructor(private readonly ratingService: RatingService) {}

  // GET /members/{memberId}/ratings
  @Get()
  getMemberRatings(
    @Param('memberId', ParseIntPipe) memberId: number,
  ): Promise<RatingResponseDto[]> {
    return this.ratingService.getRatingsByMember(memberId);
  }

  // POST /members/{memberId}/ratings
  @Post()
  @HttpCode(201)
  createRating(
    @Param('memberId', ParseIntPipe) memberId: number,
    @Body() dto: CreateRatingDto,
  ): Promise<RatingResponseDto> {
    return this.ratingService.createRating(memberId, dto);
  }

  // PATCH /members/{memberId}/ratings/{ratingId}
  @Patch(':ratingId')
  updateRating(
    @Param('memberId', ParseIntPipe) memberId: number,
    @Param('ratingId', ParseIntPipe) ratingId: number,
    @Body() dto: UpdateRatingDto,
  ): Promise<RatingResponseDto> {
    return this.ratingService.updateRating(memberId, ratingId, dto);
  }

  // DELETE /members/{memberId}/ratings/{ratingId}
  @Delete(':ratingId')
  @HttpCode(204)
  deleteRating(
    @Param('memberId', ParseIntPipe) memberId: number,
    @Param('ratingId', ParseIntPipe) ratingId: number,
  ): Promise<void> {
    return this.ratingService.deleteRating(memberId, ratingId);
  }
}
