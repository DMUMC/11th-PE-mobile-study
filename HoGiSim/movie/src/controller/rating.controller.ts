import { Controller, Get, Param, Query } from '@nestjs/common';
import { RatingService } from '../service/rating.service.js';
import { SafeMemberIdPipe } from './safe-member-id.pipe.js';
import { RatingsQueryDto } from '../dto/ratings-query.dto.js';
import type { RatingResponseDto } from '../dto/rating-response.dto.js';

@Controller('members')
export class RatingController {
  constructor(private readonly ratingService: RatingService) {}

  @Get(':memberId/ratings')
  getRatings(
    @Param('memberId', SafeMemberIdPipe) memberId: string,
    @Query() query: RatingsQueryDto,
  ): Promise<RatingResponseDto[]> {
    return this.ratingService.getRatingsByMember(Number(memberId), query);
  }
}
