import { IsEmail, IsString, Length, Matches, MaxLength } from 'class-validator';

export class SignupDto {
  @IsEmail({}, { message: '올바른 이메일 형식이 아닙니다.' })
  @MaxLength(254, { message: '이메일은 254자 이하여야 합니다.' })
  email: string;

  @IsString()
  @Length(2, 12, { message: '닉네임은 2~12자여야 합니다.' })
  @Matches(/\S/u, { message: '닉네임은 공백만 입력할 수 없습니다.' })
  nickname: string;

  @IsString()
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\p{L}\p{N}\s]).{8,}$/u, {
    message:
      '비밀번호는 대문자, 소문자, 숫자, 특수문자를 포함한 8자 이상이어야 합니다.',
  })
  password: string;
}

export interface SignupResult {
  memberId: number;
  email: string;
  nickname: string;
}
