import {
  Body,
  Controller,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { LoginMember } from '../decorator/login-member.decorator';
import { EmailParamDto, NicknameParamDto } from '../dto/check-param.dto';
import { CheckResponseDto } from '../dto/check-response.dto';
import { CreateMemberDto } from '../dto/create-member.dto';
import { MemberResponseDto } from '../dto/member-response.dto';
import { UpdateMemberDto } from '../dto/update-member.dto';
import { AuthGuard } from '../guard/auth.guard';
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

  // GET /members/me — 내 정보 조회 (로그인 필요)
  @Get('me')
  @UseGuards(AuthGuard)
  getMyInfo(@LoginMember() memberId: number): Promise<MemberResponseDto> {
    return this.memberService.getMyInfo(memberId);
  }

  // PATCH /members/me — 닉네임 변경 (로그인 필요)
  @Patch('me')
  @UseGuards(AuthGuard)
  updateMyInfo(
    @LoginMember() memberId: number,
    @Body() dto: UpdateMemberDto,
  ): Promise<MemberResponseDto> {
    return this.memberService.updateMyInfo(memberId, dto);
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
