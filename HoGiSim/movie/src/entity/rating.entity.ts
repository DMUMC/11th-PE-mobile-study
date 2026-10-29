import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import type { Relation } from 'typeorm';
import { BaseTimeEntity } from './base-time.entity.js';
import { Member } from './member.entity.js';

@Entity('rating')
@Index('uk_rating_member_movie', ['member', 'movieId'], { unique: true })
export class Rating extends BaseTimeEntity {
  @PrimaryGeneratedColumn({ name: 'rating_id', type: 'bigint' })
  ratingId: string;

  @ManyToOne(() => Member, { nullable: false })
  @JoinColumn({ name: 'member_id' })
  member: Relation<Member>;

  @Column({ name: 'movie_id', type: 'bigint' })
  movieId: string;

  @Column({ type: 'tinyint' })
  score: number;

  @Column({ type: 'text', nullable: true })
  comment: string | null;
}
