import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { Repository } from 'typeorm';
import { BusinessException } from '../common/business.exception';
import { ErrorStatus } from '../common/error-status';
import { CheckResponseDto } from '../dto/check-response.dto';
import { CreateMemberDto } from '../dto/create-member.dto';
import { MemberResponseDto } from '../dto/member-response.dto';
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
      throw new BusinessException(ErrorStatus.MEMBER_EMAIL_DUPLICATED);
    }
    if (
      await this.memberRepository.exists({ where: { nickname: dto.nickname } })
    ) {
      throw new BusinessException(ErrorStatus.MEMBER_NICKNAME_DUPLICATED);
    }

    const hashedPassword = await bcrypt.hash(dto.password, BCRYPT_SALT_ROUNDS);

    // 동시 요청이 위 체크를 함께 통과하면 여기서 ER_DUP_ENTRY가 난다.
    // 그 에러는 HttpExceptionFilter가 MEMBER4091/4092 409로 바꾼다.
    const member = await this.memberRepository.save(
      this.memberRepository.create({
        email: dto.email,
        nickname: dto.nickname,
        password: hashedPassword,
      }),
    );

    return MemberResponseDto.from(member);
  }
}
