import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { ErrorStatus } from '../common/error-status';
import { FavoriteResponseDto } from '../dto/favorite-response.dto';
import { CreateMovieRecordDto } from '../dto/movie-record-request.dto';
import { MovieRecordResponseDto } from '../dto/movie-record-response.dto';
import { RatingResponseDto } from '../dto/rating-response.dto';
import { Favorite } from '../entity/favorite.entity';
import { Member } from '../entity/member.entity';
import { Rating } from '../entity/rating.entity';
import { ApiException } from '../exception/api.exception';

@Injectable()
export class MovieRecordService {
  constructor(private readonly dataSource: DataSource) {}

  // 평점 저장과 즐겨찾기 저장을 하나의 트랜잭션으로 묶는다.
  // 콜백 안에서 예외가 나면(ApiException이든 DB 에러든) TypeORM이 ROLLBACK 하므로
  // 평점만 저장되고 즐겨찾기는 실패한 반쪽짜리 기록이 남지 않는다.
  // 콜백 안에서는 manager.getRepository()로 얻은 Repository만 써야 같은 트랜잭션(같은 커넥션)에 묶인다.
  // 생성자로 주입받은 Repository를 쓰면 트랜잭션 밖의 다른 커넥션에서 실행돼 롤백되지 않는다.
  createMovieRecord(
    memberId: number,
    dto: CreateMovieRecordDto,
  ): Promise<MovieRecordResponseDto> {
    return this.dataSource.transaction(async (manager) => {
      const memberRepository = manager.getRepository(Member);
      const ratingRepository = manager.getRepository(Rating);
      const favoriteRepository = manager.getRepository(Favorite);

      if (!(await memberRepository.exists({ where: { memberId } }))) {
        throw new ApiException(ErrorStatus.MEMBER_NOT_FOUND);
      }

      const ratingDuplicated = await ratingRepository.exists({
        where: { member: { memberId }, movieId: dto.movieId },
      });
      if (ratingDuplicated) {
        throw new ApiException(ErrorStatus.RATING_DUPLICATED);
      }

      // 1) 평점 저장 (INSERT는 실행되지만 아직 COMMIT 전)
      const rating = await ratingRepository.save(
        ratingRepository.create({
          member: { memberId },
          movieId: dto.movieId,
          score: dto.score,
          comment: dto.comment ?? null,
        }),
      );

      // 2) 즐겨찾기 저장. 이미 즐겨찾기한 영화면 예외 → 1)의 평점 INSERT까지 ROLLBACK 된다.
      let favorite: Favorite | null = null;
      if (dto.addToFavorites) {
        const favoriteDuplicated = await favoriteRepository.exists({
          where: { member: { memberId }, movieId: dto.movieId },
        });
        if (favoriteDuplicated) {
          throw new ApiException(ErrorStatus.FAVORITE_DUPLICATED);
        }
        favorite = await favoriteRepository.save(
          favoriteRepository.create({
            member: { memberId },
            movieId: dto.movieId,
          }),
        );
      }

      return {
        rating: RatingResponseDto.from(rating),
        favorite: favorite ? FavoriteResponseDto.from(favorite) : null,
      };
    });
  }
}
