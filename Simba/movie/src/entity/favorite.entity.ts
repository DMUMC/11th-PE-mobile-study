import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { BaseTimeEntity } from './base-time.entity';
import { Member } from './member.entity';

// 8주차: 회원이 즐겨찾기한 영화. 테이블은 5주차 sql/schema.sql의 favorite을 그대로 쓴다(synchronize: false).
// 한 회원은 같은 영화를 한 번만 즐겨찾기할 수 있다.
// @Unique 이름을 schema.sql의 UNIQUE KEY 이름과 맞춰 두어, ER_DUP_ENTRY 메시지의 키 이름으로 에러 코드를 고른다.
@Entity('favorite')
@Unique('uk_favorite_member_movie', ['member', 'movieId'])
export class Favorite extends BaseTimeEntity {
  @PrimaryGeneratedColumn({ name: 'favorite_id', type: 'bigint' })
  favoriteId: number;

  @ManyToOne(() => Member, { nullable: false })
  @JoinColumn({ name: 'member_id' })
  member: Member;

  // TMDB 영화 id. 영화 테이블이 없으므로 FK가 아닌 일반 컬럼이다.
  @Column({ name: 'movie_id', type: 'bigint' })
  movieId: number;
}
