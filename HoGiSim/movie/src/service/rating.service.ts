import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Member } from '../entity/member.entity.js';
import { Rating } from '../entity/rating.entity.js';
import { RatingResponseDto } from '../dto/rating-response.dto.js';
import type { RatingsQueryDto } from '../dto/ratings-query.dto.js';

@Injectable()
export class RatingService {
  constructor(
    @InjectRepository(Rating) private readonly ratings: Repository<Rating>,
    @InjectRepository(Member) private readonly members: Repository<Member>,
  ) {}

  async getRatingsByMember(
    memberId: number,
    query: RatingsQueryDto,
  ): Promise<RatingResponseDto[]> {
    const id = String(memberId);
    if (!(await this.members.existsBy({ memberId: id }))) {
      throw new NotFoundException('존재하지 않는 유저입니다.');
    }
    const paginated = query.page !== undefined || query.size !== undefined;
    const take = query.size ?? 10;
    const rows = await this.ratings.find({
      where: { member: { memberId: id } },
      order: { ratingId: 'DESC' },
      ...(paginated ? { skip: (query.page ?? 0) * take, take } : {}),
    });
    return rows.map((rating) => RatingResponseDto.from(rating));
  }
}
