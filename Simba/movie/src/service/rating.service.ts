import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BusinessException } from '../common/business.exception';
import { ErrorStatus } from '../common/error-status';
import { CreateRatingDto, UpdateRatingDto } from '../dto/rating-request.dto';
import { RatingResponseDto } from '../dto/rating-response.dto';
import { Member } from '../entity/member.entity';
import { Rating } from '../entity/rating.entity';

@Injectable()
export class RatingService {
  constructor(
    @InjectRepository(Rating)
    private readonly ratingRepository: Repository<Rating>,
    @InjectRepository(Member)
    private readonly memberRepository: Repository<Member>,
  ) {}

  async getRatingsByMember(memberId: number): Promise<RatingResponseDto[]> {
    // 평점이 0개인 회원(빈 배열)과 존재하지 않는 회원(404)을 구분한다.
    await this.ensureMemberExists(memberId);

    const ratings = await this.ratingRepository.find({
      where: { member: { memberId } },
      order: { ratingId: 'DESC' }, // 최신순
    });

    return ratings.map((rating) => RatingResponseDto.from(rating));
  }

  async createRating(
    memberId: number,
    dto: CreateRatingDto,
  ): Promise<RatingResponseDto> {
    await this.ensureMemberExists(memberId);

    // 같은 회원이 같은 영화에 두 번 남길 수 없다 (DB: uk_rating_member_movie).
    const duplicated = await this.ratingRepository.exists({
      where: { member: { memberId }, movieId: dto.movieId },
    });
    if (duplicated) {
      throw new BusinessException(ErrorStatus.RATING_DUPLICATED);
    }

    const rating = await this.ratingRepository.save(
      this.ratingRepository.create({
        member: { memberId },
        movieId: dto.movieId,
        score: dto.score,
        comment: dto.comment ?? null,
      }),
    );

    return RatingResponseDto.from(rating);
  }

  async updateRating(
    memberId: number,
    ratingId: number,
    dto: UpdateRatingDto,
  ): Promise<RatingResponseDto> {
    const rating = await this.findOwnedRating(memberId, ratingId);

    if (dto.score !== undefined) {
      rating.score = dto.score;
    }
    if (dto.comment !== undefined) {
      rating.comment = dto.comment;
    }

    const saved = await this.ratingRepository.save(rating);
    return RatingResponseDto.from(saved);
  }

  async deleteRating(memberId: number, ratingId: number): Promise<void> {
    const rating = await this.findOwnedRating(memberId, ratingId);
    await this.ratingRepository.remove(rating);
  }

  private async ensureMemberExists(memberId: number): Promise<void> {
    const exists = await this.memberRepository.exists({ where: { memberId } });
    if (!exists) {
      throw new BusinessException(ErrorStatus.MEMBER_NOT_FOUND);
    }
  }

  // 평점이 없으면 404, 있지만 다른 회원의 평점이면 403.
  private async findOwnedRating(
    memberId: number,
    ratingId: number,
  ): Promise<Rating> {
    const rating = await this.ratingRepository.findOne({
      where: { ratingId },
      relations: { member: true },
    });
    if (!rating) {
      throw new BusinessException(ErrorStatus.RATING_NOT_FOUND);
    }
    if (Number(rating.member.memberId) !== memberId) {
      throw new BusinessException(ErrorStatus.RATING_FORBIDDEN);
    }
    return rating;
  }
}
