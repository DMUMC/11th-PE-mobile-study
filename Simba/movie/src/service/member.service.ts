import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { Not, Repository } from 'typeorm';
import { ApiException } from '../exception/api.exception';
import { ErrorStatus } from '../common/error-status';
import { CheckResponseDto } from '../dto/check-response.dto';
import { CreateMemberDto } from '../dto/create-member.dto';
import { MemberResponseDto } from '../dto/member-response.dto';
import { UpdateMemberDto } from '../dto/update-member.dto';
import { Member } from '../entity/member.entity';

// bcrypt cost factor. 2^10번 반복하며, 해시 결과는 항상 60자다(member.password VARCHAR(60)).
const BCRYPT_SALT_ROUNDS = 10;

@Injectable()
export class MemberService {
  constructor(
    @InjectRepository(Member)
    private readonly memberRepository: Repository<Member>,
  ) {}

  async checkNickname(nickname: string): Promise<CheckResponseDto> {
    const exists = await this.memberRepository.exists({ where: { nickname } });
    return { available: !exists };
  }

  async checkEmail(email: string): Promise<CheckResponseDto> {
    const exists = await this.memberRepository.exists({ where: { email } });
    return { available: !exists };
  }

  async signUp(dto: CreateMemberDto): Promise<MemberResponseDto> {
    // 사전 중복 체크: 이메일/닉네임 중 무엇이 겹쳤는지 구분해서 알려준다.
    if (await this.memberRepository.exists({ where: { email: dto.email } })) {
      throw new ApiException(ErrorStatus.MEMBER_EMAIL_DUPLICATED);
    }
    if (
      await this.memberRepository.exists({ where: { nickname: dto.nickname } })
    ) {
      throw new ApiException(ErrorStatus.MEMBER_NICKNAME_DUPLICATED);
    }

    const hashedPassword = await bcrypt.hash(dto.password, BCRYPT_SALT_ROUNDS);

    // 동시 요청이 위 체크를 함께 통과하면 여기서 ER_DUP_ENTRY가 난다.
    // 그 에러는 HttpExceptionFilter가 MEMBER409_1/409_2로 바꾼다.
    const member = await this.memberRepository.save(
      this.memberRepository.create({
        email: dto.email,
        nickname: dto.nickname,
        password: hashedPassword,
      }),
    );

    return MemberResponseDto.from(member);
  }

  // GET /members/me — 토큰의 memberId로 내 정보를 조회한다.
  async getMyInfo(memberId: number): Promise<MemberResponseDto> {
    const member = await this.findMember(memberId);
    return MemberResponseDto.from(member);
  }

  // PATCH /members/me — 닉네임 변경
  async updateMyInfo(
    memberId: number,
    dto: UpdateMemberDto,
  ): Promise<MemberResponseDto> {
    const member = await this.findMember(memberId);

    // 나를 제외하고 같은 닉네임을 쓰는 회원이 있으면 409.
    // 지금 닉네임 그대로 보내는 것은 중복이 아니다.
    const duplicated = await this.memberRepository.exists({
      where: { nickname: dto.nickname, memberId: Not(memberId) },
    });
    if (duplicated) {
      throw new ApiException(ErrorStatus.MEMBER_NICKNAME_DUPLICATED);
    }

    member.nickname = dto.nickname;
    // 동시 요청으로 위 체크를 함께 통과하면 UNIQUE(nickname)가 막고, 필터가 MEMBER409_1로 바꾼다.
    const saved = await this.memberRepository.save(member);
    return MemberResponseDto.from(saved);
  }

  private async findMember(memberId: number): Promise<Member> {
    const member = await this.memberRepository.findOne({ where: { memberId } });
    if (!member) {
      throw new ApiException(ErrorStatus.MEMBER_NOT_FOUND);
    }
    return member;
  }
}
