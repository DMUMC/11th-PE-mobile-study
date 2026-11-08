import {
  Column,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { Member } from './member.entity';

@Entity('ratings')
@Unique('uq_ratings_member_movie', ['memberId', 'movieId'])
export class Rating {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ name: 'member_id', type: 'int' })
  memberId: number;

  @ManyToOne(() => Member, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'member_id' })
  member: Member;

  @Column({ name: 'movie_id', type: 'int' })
  movieId: number;

  @Column({ type: 'tinyint' })
  score: number;
}
