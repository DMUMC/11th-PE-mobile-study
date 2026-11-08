import { IsEmail, IsNotEmpty, IsString, Length, Matches } from 'class-validator';

// POST /members 요청 본문
export class CreateMemberDto {
  @IsNotEmpty({ message: '이메일은 필수입니다.' })
  @IsEmail({}, { message: '올바른 이메일 형식이 아닙니다.' })
  email: string;

  @IsString({ message: '닉네임은 문자열이어야 합니다.' })
  @Length(2, 12, { message: '닉네임은 2~12자여야 합니다.' })
  nickname: string;

  // 대문자·소문자·숫자·특수문자를 각각 1개 이상 포함한 8자 이상.
  // bcrypt는 72바이트까지만 해시에 반영하므로 최대 길이도 제한한다.
  @IsString({ message: '비밀번호는 문자열이어야 합니다.' })
  @Length(8, 64, { message: '비밀번호는 8~64자여야 합니다.' })
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9\s]).+$/, {
    message: '비밀번호는 대문자, 소문자, 숫자, 특수문자를 모두 포함해야 합니다.',
  })
  password: string;
}
