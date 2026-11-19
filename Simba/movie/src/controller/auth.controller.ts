import { Body, Controller, HttpCode, Post } from '@nestjs/common';
import { LoginRequestDto, LoginResponseDto } from '../dto/login.dto';
import { AuthService } from '../service/auth.service';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  // POST /auth/login — 새 리소스를 만들지 않으므로 201이 아니라 200
  @Post('login')
  @HttpCode(200)
  login(@Body() dto: LoginRequestDto): Promise<LoginResponseDto> {
    return this.authService.login(dto);
  }
}
