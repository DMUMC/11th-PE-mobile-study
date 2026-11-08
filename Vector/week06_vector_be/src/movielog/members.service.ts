import { HttpStatus, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { apiError, isDuplicateKey } from './api-error';
import { SignupDto } from './dto';
import { Member } from './member.entity';
import { bcryptPassword } from './password';

@Injectable()
export class MembersService {
  constructor(
    @InjectRepository(Member) private readonly members: Repository<Member>,
  ) {}

  async available(field: 'email' | 'nickname', value: string) {
    return { available: !(await this.members.existsBy({ [field]: value })) };
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
