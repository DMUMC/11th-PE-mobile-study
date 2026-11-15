import { Controller, Get, Param } from '@nestjs/common';
import { EmailParamDto, NicknameParamDto } from '../dto/check-param.dto';
import { CheckResponseDto } from '../dto/check-response.dto';
import { MemberService } from '../service/member.service';

@Controller('members')
export class MemberController {
  constructor(private readonly memberService: MemberService) {}

  // GET /members/nickname/{nickname}
  @Get('nickname/:nickname')
  checkNickname(@Param() params: NicknameParamDto): Promise<CheckResponseDto> {
    return this.memberService.checkNickname(params.nickname);
  }

  // GET /members/email/{email}
  @Get('email/:email')
  checkEmail(@Param() params: EmailParamDto): Promise<CheckResponseDto> {
    return this.memberService.checkEmail(params.email);
  }
}
