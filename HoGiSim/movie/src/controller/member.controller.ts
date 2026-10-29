import { Controller, Get, Param } from '@nestjs/common';
import { MemberService } from '../service/member.service.js';
import { EmailParamsDto, NicknameParamsDto } from '../dto/member-params.dto.js';
import type { AvailabilityResponseDto } from '../dto/availability-response.dto.js';

@Controller('members')
export class MemberController {
  constructor(private readonly memberService: MemberService) {}

  @Get('nickname/:nickname')
  checkNickname(
    @Param() params: NicknameParamsDto,
  ): Promise<AvailabilityResponseDto> {
    return this.memberService.checkNickname(params.nickname);
  }

  @Get('email/:email')
  checkEmail(
    @Param() params: EmailParamsDto,
  ): Promise<AvailabilityResponseDto> {
    return this.memberService.checkEmail(params.email);
  }
}
