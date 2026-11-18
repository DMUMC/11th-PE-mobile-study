import { HttpStatus, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { apiError, isDuplicateKey } from './api-error';
import { CreateRatingDto } from './dto';
import { Member } from './member.entity';
import { Rating } from './rating.entity';

@Injectable()
export class RatingsService {
  constructor(
    @InjectRepository(Rating) private readonly ratings: Repository<Rating>,
    @InjectRepository(Member) private readonly members: Repository<Member>,
  ) {}

  list(memberId: number) {
    return this.ratings.findBy({ memberId });
  }

  async create(memberId: number, dto: CreateRatingDto) {
    if (!(await this.members.existsBy({ id: memberId }))) {
      throw apiError(
        HttpStatus.NOT_FOUND,
        'MEMBER_NOT_FOUND',
        '회원을 찾을 수 없습니다.',
      );
    }
    try {
      return await this.ratings.save({
        memberId,
        movieId: dto.movieId,
        score: dto.score,
      });
    } catch (error) {
      if (isDuplicateKey(error)) {
        throw apiError(
          HttpStatus.CONFLICT,
          'DUPLICATE_RATING',
          '이미 평점을 등록한 영화입니다.',
        );
      }
      throw error;
    }
  }

  async update(id: number, memberId: number, score: number) {
    const rating = await this.findOwned(id, memberId);
    if (rating.score !== score) {
      const { affected } = await this.ratings.update(
        { id, memberId },
        { score },
      );
      if (!affected) throw this.notFound();
    }
    return { id, memberId, movieId: rating.movieId, score };
  }

  async remove(id: number, memberId: number) {
    await this.findOwned(id, memberId);
    const { affected } = await this.ratings.delete({ id, memberId });
    if (!affected) throw this.notFound();
  }

  private async findOwned(id: number, memberId: number) {
    const rating = await this.ratings.findOneBy({ id });
    if (!rating) throw this.notFound();
    if (rating.memberId !== memberId) {
      throw apiError(
        HttpStatus.FORBIDDEN,
        'RATING_FORBIDDEN',
        '본인이 등록한 평점만 변경할 수 있습니다.',
      );
    }
    return rating;
  }

  private notFound() {
    return apiError(
      HttpStatus.NOT_FOUND,
      'RATING_NOT_FOUND',
      '평점을 찾을 수 없습니다.',
    );
  }
}
