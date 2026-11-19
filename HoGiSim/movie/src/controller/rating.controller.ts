import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { RatingService } from '../service/rating.service.js';
import { CreateRatingDto, UpdateRatingDto } from '../dto/rating-write.dto.js';
import { success } from '../dto/api-response.js';
import { SafeIdPipe } from './safe-member-id.pipe.js';
import { RatingsQueryDto } from '../dto/ratings-query.dto.js';
import type { RatingResponseDto } from '../dto/rating-response.dto.js';

@Controller('members')
export class RatingController {
  constructor(private readonly ratingService: RatingService) {}

  @Post(':memberId/ratings')
  async create(
    @Param('memberId', SafeIdPipe) memberId: string,
    @Body() dto: CreateRatingDto,
  ) {
    const ratingId = await this.ratingService.create(memberId, dto);
    return success(201, '평점 등록에 성공했습니다.', ratingId);
  }

  @Patch(':memberId/ratings/:ratingId')
  async update(
    @Param('memberId', SafeIdPipe) memberId: string,
    @Param('ratingId', SafeIdPipe) ratingId: string,
    @Body() dto: UpdateRatingDto,
  ) {
    await this.ratingService.update(memberId, ratingId, dto);
    return success(200, '평점 수정에 성공했습니다.', null);
  }

  @Delete(':memberId/ratings/:ratingId')
  @HttpCode(204)
  async delete(
    @Param('memberId', SafeIdPipe) memberId: string,
    @Param('ratingId', SafeIdPipe) ratingId: string,
  ): Promise<void> {
    await this.ratingService.delete(memberId, ratingId);
  }

  @Get(':memberId/ratings')
  getRatings(
    @Param('memberId', SafeIdPipe) memberId: string,
    @Query() query: RatingsQueryDto,
  ): Promise<RatingResponseDto[]> {
    return this.ratingService.getRatingsByMember(Number(memberId), query);
  }
}
