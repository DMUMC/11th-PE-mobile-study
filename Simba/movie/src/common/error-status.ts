import { HttpStatus } from '@nestjs/common';

export interface ErrorStatusValue {
  status: HttpStatus;
  code: string;
  message: string;
}

// 실패 응답에 쓰는 code/message를 한곳에서 관리한다.
// code 규칙: {도메인}{HTTP 상태}_{일련번호}  예) MEMBER409_1 = 회원 도메인 409의 1번
export const ErrorStatus = {
  // 공통
  BAD_REQUEST: {
    status: HttpStatus.BAD_REQUEST,
    code: 'COMMON400',
    message: '잘못된 요청입니다.',
  },
  NOT_FOUND: {
    status: HttpStatus.NOT_FOUND,
    code: 'COMMON404',
    message: '요청한 리소스를 찾을 수 없습니다.',
  },
  CONFLICT: {
    status: HttpStatus.CONFLICT,
    code: 'COMMON409',
    message: '이미 존재하는 데이터입니다.',
  },
  INTERNAL_SERVER_ERROR: {
    status: HttpStatus.INTERNAL_SERVER_ERROR,
    code: 'COMMON500',
    message: '서버 에러, 관리자에게 문의 바랍니다.',
  },

  // 인증
  // 이메일이 없을 때와 비밀번호가 틀렸을 때 같은 응답을 준다(가입된 이메일인지 알려주지 않기 위해).
  AUTH_LOGIN_FAILED: {
    status: HttpStatus.UNAUTHORIZED,
    code: 'AUTH401_1',
    message: '이메일 또는 비밀번호가 올바르지 않습니다.',
  },
  AUTH_TOKEN_MISSING: {
    status: HttpStatus.UNAUTHORIZED,
    code: 'AUTH401_2',
    message: '로그인이 필요합니다. Authorization: Bearer 토큰을 보내 주세요.',
  },
  AUTH_TOKEN_INVALID: {
    status: HttpStatus.UNAUTHORIZED,
    code: 'AUTH401_3',
    message: '유효하지 않은 토큰입니다.',
  },
  AUTH_TOKEN_EXPIRED: {
    status: HttpStatus.UNAUTHORIZED,
    code: 'AUTH401_4',
    message: '만료된 토큰입니다. 다시 로그인해 주세요.',
  },

  // 회원
  MEMBER_NOT_FOUND: {
    status: HttpStatus.NOT_FOUND,
    code: 'MEMBER404_1',
    message: '존재하지 않는 회원입니다.',
  },
  MEMBER_NICKNAME_DUPLICATED: {
    status: HttpStatus.CONFLICT,
    code: 'MEMBER409_1',
    message: '이미 사용 중인 닉네임입니다.',
  },
  MEMBER_EMAIL_DUPLICATED: {
    status: HttpStatus.CONFLICT,
    code: 'MEMBER409_2',
    message: '이미 가입된 이메일입니다.',
  },

  // 평점
  RATING_FORBIDDEN: {
    status: HttpStatus.FORBIDDEN,
    code: 'RATING403_1',
    message: '본인이 작성한 평점만 수정·삭제할 수 있습니다.',
  },
  RATING_NOT_FOUND: {
    status: HttpStatus.NOT_FOUND,
    code: 'RATING404_1',
    message: '존재하지 않는 평점입니다.',
  },
  RATING_DUPLICATED: {
    status: HttpStatus.CONFLICT,
    code: 'RATING409_1',
    message: '이미 이 영화에 평점을 남겼습니다.',
  },
} as const satisfies Record<string, ErrorStatusValue>;
