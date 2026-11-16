import { IsEmail, IsString, Length } from 'class-validator';

// (선택 미션) 형식이 맞지 않으면 중복 여부를 확인하기 전에 400으로 응답한다.
export class NicknameParamDto {
  @IsString()
  @Length(2, 12, { message: '닉네임은 2~12자여야 합니다.' })
  nickname: string;
}

export class EmailParamDto {
  @IsEmail({}, { message: '올바른 이메일 형식이 아닙니다.' })
  email: string;
}
