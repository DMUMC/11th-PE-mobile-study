import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { SignupDto } from '../dto/signup.dto.js';
import { success } from '../dto/api-response.js';
import { MemberService } from '../service/member.service.js';
import { EmailParamsDto, NicknameParamsDto } from '../dto/member-params.dto.js';
import type { AvailabilityResponseDto } from '../dto/availability-response.dto.js';

@Controller('members')
export class MemberController {
  constructor(private readonly memberService: MemberService) {}

  @Post()
  async signup(@Body() dto: SignupDto) {
    return success(
      201,
      '회원가입에 성공했습니다.',
      await this.memberService.signup(dto),
    );
  }

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
