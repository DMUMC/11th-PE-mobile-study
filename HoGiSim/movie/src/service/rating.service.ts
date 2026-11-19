import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Member } from '../entity/member.entity.js';
import { Rating } from '../entity/rating.entity.js';
import { toApiId } from '../dto/api-id.js';
import type {
  CreateRatingDto,
  UpdateRatingDto,
} from '../dto/rating-write.dto.js';
import { writeConflict } from '../write-errors.js';
import { RatingResponseDto } from '../dto/rating-response.dto.js';
import type { RatingsQueryDto } from '../dto/ratings-query.dto.js';

@Injectable()
export class RatingService {
  constructor(
    @InjectRepository(Rating) private readonly ratings: Repository<Rating>,
    @InjectRepository(Member) private readonly members: Repository<Member>,
  ) {}

  async create(memberId: string, dto: CreateRatingDto): Promise<number> {
    await this.requireMember(memberId);
    const movieId = String(dto.movieId);
    const member = { memberId };
    if (await this.ratings.existsBy({ member, movieId })) {
      throw writeConflict('uk_rating_member_movie');
    }

    const rating = await this.ratings.save(
      this.ratings.create({
        member,
        movieId,
        score: dto.score,
        comment: dto.comment ?? null,
      }),
    );
    return toApiId(rating.ratingId);
  }

  async update(
    memberId: string,
    ratingId: string,
    dto: UpdateRatingDto,
  ): Promise<void> {
    await this.requireRatingOwner(memberId, ratingId);
    const result = await this.ratings.update(ratingId, {
      score: dto.score,
      comment: dto.comment ?? null,
    });
    if (result.affected === 0)
      throw new NotFoundException('존재하지 않는 평점입니다.');
  }

  async delete(memberId: string, ratingId: string): Promise<void> {
    await this.requireRatingOwner(memberId, ratingId);
    const result = await this.ratings.delete(ratingId);
    if (result.affected === 0)
      throw new NotFoundException('존재하지 않는 평점입니다.');
  }

  private async requireRatingOwner(
    memberId: string,
    ratingId: string,
  ): Promise<void> {
    const rating = await this.ratings.findOne({
      where: { ratingId },
      relations: { member: true },
    });
    if (!rating) throw new NotFoundException('존재하지 않는 평점입니다.');
    if (rating.member.memberId !== memberId) {
      throw new ForbiddenException(
        '본인의 평점만 수정하거나 삭제할 수 있습니다.',
      );
    }
  }

  private async requireMember(memberId: string): Promise<void> {
    if (!(await this.members.existsBy({ memberId }))) {
      throw new NotFoundException('존재하지 않는 유저입니다.');
    }
  }

  async getRatingsByMember(
    memberId: number,
    query: RatingsQueryDto,
  ): Promise<RatingResponseDto[]> {
    const id = String(memberId);
    await this.requireMember(id);
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
