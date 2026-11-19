import { ConflictException } from '@nestjs/common';

const conflicts = {
  email: {
    code: 'MEMBER4091',
    message: '이미 사용 중인 이메일입니다.',
  },
  nickname: {
    code: 'MEMBER4092',
    message: '이미 사용 중인 닉네임입니다.',
  },
  uk_rating_member_movie: {
    code: 'RATING4091',
    message: '이미 이 영화에 평점을 등록했습니다.',
  },
} as const;

export function writeConflict(key: keyof typeof conflicts): ConflictException {
  return new ConflictException(conflicts[key]);
}

export function uniqueConflict(message: string): ConflictException {
  // MySQL can return either 'email' or a qualified key such as 'member.email'.
  const key = /for key ['`](?:[^'`]+\.)?([^.'`]+)['`]$/i.exec(message)?.[1];
  switch (key) {
    case 'email':
    case 'nickname':
    case 'uk_rating_member_movie':
      return writeConflict(key);
    default:
      return new ConflictException('이미 존재하는 데이터입니다.');
  }
}
