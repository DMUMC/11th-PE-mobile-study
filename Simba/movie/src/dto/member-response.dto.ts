import { Member } from '../entity/member.entity';

// 회원가입 응답. password(해시 포함)는 절대 내보내지 않는다.
export class MemberResponseDto {
  memberId: number;
  email: string;
  nickname: string;
  createdAt: Date;

  static from(member: Member): MemberResponseDto {
    return {
      memberId: Number(member.memberId),
      email: member.email,
      nickname: member.nickname,
      createdAt: member.createdAt,
    };
  }
}
