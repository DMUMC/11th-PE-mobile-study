import { IsEmail, IsString, Length, Matches, MaxLength } from 'class-validator';

export class NicknameParamsDto {
  @IsString()
  @Length(2, 12, { message: '닉네임은 2~12자여야 합니다.' })
  @Matches(/\S/u, { message: '닉네임은 공백만 입력할 수 없습니다.' })
  nickname: string;
}

export class EmailParamsDto {
  @IsEmail({}, { message: '올바른 이메일 형식이 아닙니다.' })
  @MaxLength(254)
  email: string;
}
