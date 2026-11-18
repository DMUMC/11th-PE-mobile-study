import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import * as bcrypt from 'bcrypt';
import { Repository } from 'typeorm';
import { ErrorStatus } from '../common/error-status';
import { LoginRequestDto, LoginResponseDto } from '../dto/login.dto';
import { Member } from '../entity/member.entity';
import { ApiException } from '../exception/api.exception';
import { AccessTokenPayload } from '../guard/auth.guard';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(Member)
    private readonly memberRepository: Repository<Member>,
    private readonly jwtService: JwtService,
  ) {}

  async login(dto: LoginRequestDto): Promise<LoginResponseDto> {
    const member = await this.memberRepository.findOne({
      where: { email: dto.email },
    });

    // 이메일이 없을 때와 비밀번호가 틀렸을 때 같은 AUTH401_1을 준다.
    // bcrypt.compare는 평문을 저장된 해시의 salt로 다시 해시해 비교한다(복호화가 아니다).
    if (!member || !(await bcrypt.compare(dto.password, member.password))) {
      throw new ApiException(ErrorStatus.AUTH_LOGIN_FAILED);
    }

    // 만료 시간(expiresIn)은 JwtModule 설정(JWT_ACCESS_EXPIRATION)을 따른다.
    const payload: AccessTokenPayload = { sub: String(member.memberId) };
    const accessToken = await this.jwtService.signAsync(payload);

    return { nickname: member.nickname, accessToken };
  }
}
