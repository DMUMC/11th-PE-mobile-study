import { BadRequestException, Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { hash } from 'bcrypt';
import { Repository } from 'typeorm';
import { toApiId } from '../dto/api-id.js';
import type { SignupDto, SignupResult } from '../dto/signup.dto.js';
import { writeConflict } from '../write-errors.js';
import { Member } from '../entity/member.entity.js';
import { AvailabilityResponseDto } from '../dto/availability-response.dto.js';

@Injectable()
export class MemberService {
  constructor(
    @InjectRepository(Member) private readonly members: Repository<Member>,
  ) {}

  async signup({
    email,
    nickname,
    password,
  }: SignupDto): Promise<SignupResult> {
    if (Buffer.byteLength(password, 'utf8') > 72) {
      throw new BadRequestException(
        '비밀번호는 UTF-8 기준 72바이트 이하여야 합니다.',
      );
    }
    if (await this.members.existsBy({ email })) throw writeConflict('email');
    if (await this.members.existsBy({ nickname }))
      throw writeConflict('nickname');

    const member = await this.members.save(
      this.members.create({
        email,
        nickname,
        password: await hash(password, 10),
      }),
    );
    return {
      memberId: toApiId(member.memberId),
      email: member.email,
      nickname: member.nickname,
    };
  }

  async checkNickname(nickname: string): Promise<AvailabilityResponseDto> {
    return new AvailabilityResponseDto(
      !(await this.members.existsBy({ nickname })),
    );
  }

  async checkEmail(email: string): Promise<AvailabilityResponseDto> {
    return new AvailabilityResponseDto(
      !(await this.members.existsBy({ email })),
    );
  }
}
