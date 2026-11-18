import { Column, Entity, PrimaryGeneratedColumn, Unique } from 'typeorm';

@Entity('members')
@Unique('uq_members_email', ['email'])
@Unique('uq_members_nickname', ['nickname'])
export class Member {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ length: 254 })
  email: string;

  @Column({ length: 24 })
  nickname: string;

  @Column({ name: 'password_hash', length: 60, select: false })
  passwordHash: string;
}
