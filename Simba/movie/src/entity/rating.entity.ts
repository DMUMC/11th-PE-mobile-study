import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { BaseTimeEntity } from './base-time.entity';
import { Member } from './member.entity';

// 한 회원은 같은 영화에 평점을 하나만 남길 수 있다.
// 이 규칙은 sql/schema.sql의 UNIQUE KEY uk_rating_member_movie (member_id, movie_id)가 DB에서 보장한다.
@Entity('rating')
export class Rating extends BaseTimeEntity {
  @PrimaryGeneratedColumn({ name: 'rating_id', type: 'bigint' })
  ratingId: number;

  @ManyToOne(() => Member, { nullable: false })
  @JoinColumn({ name: 'member_id' })
  member: Member;

  // TMDB 영화 id. 영화 테이블이 없으므로 FK가 아닌 일반 컬럼이다.
  @Column({ name: 'movie_id', type: 'bigint' })
  movieId: number;

  @Column({ type: 'tinyint' })
  score: number;

  @Column({ type: 'text', nullable: true })
  comment: string | null;
}
