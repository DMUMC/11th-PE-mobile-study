import { Body, Controller, Get, HttpCode, Param, Post } from '@nestjs/common';
import { EmailParamDto, NicknameParamDto } from '../dto/check-param.dto';
import { CheckResponseDto } from '../dto/check-response.dto';
import { CreateMemberDto } from '../dto/create-member.dto';
import { MemberResponseDto } from '../dto/member-response.dto';
import { MemberService } from '../service/member.service';

@Controller('members')
export class MemberController {
  constructor(private readonly memberService: MemberService) {}

  // POST /members — 회원가입
  @Post()
  @HttpCode(201)
  signUp(@Body() dto: CreateMemberDto): Promise<MemberResponseDto> {
    return this.memberService.signUp(dto);
  }

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
