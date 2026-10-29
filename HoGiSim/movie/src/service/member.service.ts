import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Member } from '../entity/member.entity.js';
import { AvailabilityResponseDto } from '../dto/availability-response.dto.js';

@Injectable()
export class MemberService {
  constructor(
    @InjectRepository(Member) private readonly members: Repository<Member>,
  ) {}

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
