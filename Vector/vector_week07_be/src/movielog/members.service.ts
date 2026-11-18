import { HttpStatus, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { apiError, isDuplicateKey } from './api-error';
import { LoginDto, SignupDto } from './dto';
import { Member } from './member.entity';
import { bcryptPassword, verifyPassword } from './password';

import { AccessTokens, unauthorized } from './auth';

@Injectable()
export class MembersService {
  constructor(
    @InjectRepository(Member) private readonly members: Repository<Member>,
    private readonly tokens: AccessTokens,
  ) {}

  async available(field: 'email' | 'nickname', value: string) {
    return { available: !(await this.members.existsBy({ [field]: value })) };
  }

  async login(dto: LoginDto) {
    const member = await this.members.findOne({
      where: { email: dto.email },
      select: { id: true, passwordHash: true },
    });
    if (!member || !(await verifyPassword(dto.password, member.passwordHash))) {
      throw unauthorized();
    }
    return { accessToken: this.tokens.issue(member.id) };
  }

  async me(id: number) {
    const member = await this.members.findOneBy({ id });
    if (!member) throw unauthorized();
    return { id: member.id, email: member.email, nickname: member.nickname };
  }

  async signup(dto: SignupDto) {
    const { email, nickname } = dto;
    const passwordHash = await bcryptPassword(dto.password);
    try {
      const { id } = await this.members.save({ email, nickname, passwordHash });
      return { id, email, nickname };
    } catch (error) {
      if (isDuplicateKey(error)) {
        throw apiError(
          HttpStatus.CONFLICT,
          'DUPLICATE_MEMBER',
          '이미 사용 중인 이메일 또는 닉네임입니다.',
        );
      }
      throw error;
    }
  }
}
