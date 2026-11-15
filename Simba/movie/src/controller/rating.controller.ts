import { Controller, Get, Param, ParseIntPipe } from '@nestjs/common';
import { RatingResponseDto } from '../dto/rating-response.dto';
import { RatingService } from '../service/rating.service';

// 파일은 자원(Rating) 기준으로 나누고, URL은 프론트가 이해하기 쉬운 /members/... 모양을 쓴다.
@Controller('members')
export class RatingController {
  constructor(private readonly ratingService: RatingService) {}

  // GET /members/{memberId}/ratings — 숫자가 아니면 ParseIntPipe가 400으로 응답한다.
  @Get(':memberId/ratings')
  getMemberRatings(
    @Param('memberId', ParseIntPipe) memberId: number,
  ): Promise<RatingResponseDto[]> {
    return this.ratingService.getRatingsByMember(memberId);
  }
}
