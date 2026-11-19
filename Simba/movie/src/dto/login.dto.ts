import { IsEmail, IsNotEmpty, IsString } from 'class-validator';

// POST /auth/login 요청 본문.
// 비밀번호 규칙(대소문자·숫자·특수문자)은 가입할 때만 검사한다.
// 로그인에서까지 검사하면 "규칙에 맞지 않는 비밀번호"라는 정보를 알려 주게 된다.
export class LoginRequestDto {
  @IsNotEmpty({ message: '이메일은 필수입니다.' })
  @IsEmail({}, { message: '올바른 이메일 형식이 아닙니다.' })
  email: string;

  @IsString({ message: '비밀번호는 문자열이어야 합니다.' })
  @IsNotEmpty({ message: '비밀번호는 필수입니다.' })
  password: string;
}

// POST /auth/login 응답
export class LoginResponseDto {
  nickname: string;
  accessToken: string;
}
