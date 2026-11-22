import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ErrorStatus } from '../common/error-status';
import { CreateFavoriteDto } from '../dto/favorite-request.dto';
import {
  FavoriteResponseDto,
  FavoriteStatusResponseDto,
} from '../dto/favorite-response.dto';
import { Favorite } from '../entity/favorite.entity';
import { Member } from '../entity/member.entity';
import { ApiException } from '../exception/api.exception';

@Injectable()
export class FavoriteService {
  constructor(
    @InjectRepository(Favorite)
    private readonly favoriteRepository: Repository<Favorite>,
    @InjectRepository(Member)
    private readonly memberRepository: Repository<Member>,
  ) {}

  async addFavorite(
    memberId: number,
    dto: CreateFavoriteDto,
  ): Promise<FavoriteResponseDto> {
    // 토큰은 유효하지만 그 사이 회원이 삭제됐을 수 있다.
    if (!(await this.memberRepository.exists({ where: { memberId } }))) {
      throw new ApiException(ErrorStatus.MEMBER_NOT_FOUND);
    }

    // 사전 중복 체크. 동시에 같은 요청이 들어와 둘 다 이 검사를 통과하면
    // DB의 uk_favorite_member_movie가 막고, 전역 필터가 ER_DUP_ENTRY를 FAVORITE409_1로 바꾼다.
    const duplicated = await this.favoriteRepository.exists({
      where: { member: { memberId }, movieId: dto.movieId },
    });
    if (duplicated) {
      throw new ApiException(ErrorStatus.FAVORITE_DUPLICATED);
    }

    const favorite = await this.favoriteRepository.save(
      this.favoriteRepository.create({
        member: { memberId },
        movieId: dto.movieId,
      }),
    );
    return FavoriteResponseDto.from(favorite);
  }

  async getMyFavorites(memberId: number): Promise<FavoriteResponseDto[]> {
    const favorites = await this.favoriteRepository.find({
      where: { member: { memberId } },
      order: { favoriteId: 'DESC' }, // 최근에 추가한 순
    });
    return favorites.map((favorite) => FavoriteResponseDto.from(favorite));
  }

  async getFavoriteStatus(
    memberId: number,
    movieId: number,
  ): Promise<FavoriteStatusResponseDto> {
    const isFavorite = await this.favoriteRepository.exists({
      where: { member: { memberId }, movieId },
    });
    return { isFavorite };
  }

  async removeFavorite(memberId: number, movieId: number): Promise<void> {
    // 조건에 내 memberId가 들어가므로 다른 회원의 즐겨찾기는 지울 수 없다.
    const result = await this.favoriteRepository.delete({
      member: { memberId },
      movieId,
    });
    if (!result.affected) {
      throw new ApiException(ErrorStatus.FAVORITE_NOT_FOUND);
    }
  }
}
