import { HttpStatus } from '@nestjs/common';

export interface ErrorStatusValue {
  status: HttpStatus;
  code: string;
  message: string;
}

// 실패 응답에 쓰는 code/message를 한곳에서 관리한다.
// code 규칙: {도메인}{HTTP 상태}{일련번호}  예) MEMBER4091 = 회원 도메인 409의 1번
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

  // 회원
  MEMBER_NOT_FOUND: {
    status: HttpStatus.NOT_FOUND,
    code: 'MEMBER4041',
    message: '존재하지 않는 회원입니다.',
  },
  MEMBER_EMAIL_DUPLICATED: {
    status: HttpStatus.CONFLICT,
    code: 'MEMBER4091',
    message: '이미 가입된 이메일입니다.',
  },
  MEMBER_NICKNAME_DUPLICATED: {
    status: HttpStatus.CONFLICT,
    code: 'MEMBER4092',
    message: '이미 사용 중인 닉네임입니다.',
  },

  // 평점
  RATING_FORBIDDEN: {
    status: HttpStatus.FORBIDDEN,
    code: 'RATING4031',
    message: '본인이 작성한 평점만 수정·삭제할 수 있습니다.',
  },
  RATING_NOT_FOUND: {
    status: HttpStatus.NOT_FOUND,
    code: 'RATING4041',
    message: '존재하지 않는 평점입니다.',
  },
  RATING_DUPLICATED: {
    status: HttpStatus.CONFLICT,
    code: 'RATING4091',
    message: '이미 이 영화에 평점을 남겼습니다.',
  },
} as const satisfies Record<string, ErrorStatusValue>;
