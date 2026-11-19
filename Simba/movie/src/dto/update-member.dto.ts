import { IsString, Length } from 'class-validator';

// PATCH /members/me 요청 본문
export class UpdateMemberDto {
  @IsString({ message: '닉네임은 문자열이어야 합니다.' })
  @Length(2, 12, { message: '닉네임은 2~12자여야 합니다.' })
  nickname: string;
}
