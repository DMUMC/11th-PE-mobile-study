import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';
import { BaseTimeEntity } from './base-time.entity';

@Entity('member')
export class Member extends BaseTimeEntity {
  @PrimaryGeneratedColumn({ name: 'member_id', type: 'bigint' })
  memberId: number;

  // RFC 5321 기준 이메일 최대 길이 254자
  @Column({ unique: true, length: 254 })
  email: string;

  // 6주차부터 bcrypt 해시(항상 60자)가 저장된다.
  @Column({ length: 60 })
  password: string;

  @Column({ unique: true, length: 50 })
  nickname: string;
}
