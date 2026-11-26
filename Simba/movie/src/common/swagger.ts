import { applyDecorators } from '@nestjs/common';
import { ApiBearerAuth, ApiResponse } from '@nestjs/swagger';
import { ErrorStatus, ErrorStatusValue } from './error-status';

// (선택 미션) Swagger 문서에 공통 응답 { isSuccess, code, message, result } 예시를 붙이는 헬퍼.

export const BEARER_AUTH = 'access-token';

// 성공 응답 예시. status 201이면 COMMON201, 나머지는 COMMON200.
export function ApiSuccess(status: 200 | 201, result: unknown) {
  const created = status === 201;
  return ApiResponse({
    status,
    description: created ? 'COMMON201' : 'COMMON200',
    content: {
      'application/json': {
        example: {
          isSuccess: true,
          code: created ? 'COMMON201' : 'COMMON200',
          message: created ? '생성되었습니다.' : '성공입니다.',
          result,
        },
      },
    },
  });
}

// 실패 응답 예시. 같은 HTTP 상태의 code가 여러 개면 하나의 응답 아래 examples로 나열한다.
// 예) 409 → FAVORITE409_1, RATING409_1
export function ApiFailure(...errors: ErrorStatusValue[]) {
  const byStatus = new Map<number, ErrorStatusValue[]>();
  for (const error of errors) {
    byStatus.set(error.status, [...(byStatus.get(error.status) ?? []), error]);
  }
  return applyDecorators(
    ...[...byStatus].map(([status, list]) =>
      ApiResponse({
        status,
        description: list.map((error) => error.code).join(', '),
        content: {
          'application/json': {
            examples: Object.fromEntries(
              list.map((error) => [
                error.code,
                {
                  summary: error.message,
                  value: {
                    isSuccess: false,
                    code: error.code,
                    message: error.message,
                    result: null,
                  },
                },
              ]),
            ),
          },
        },
      }),
    ),
  );
}

// ValidationPipe가 보내는 400 예시. result에 어떤 필드가 왜 틀렸는지 담긴다.
export function ApiValidationFailure(...messages: string[]) {
  return ApiResponse({
    status: 400,
    description: 'COMMON400',
    content: {
      'application/json': {
        example: {
          isSuccess: false,
          code: ErrorStatus.BAD_REQUEST.code,
          message: ErrorStatus.BAD_REQUEST.message,
          result: messages,
        },
      },
    },
  });
}

// 인증이 필요한 API: Swagger UI의 자물쇠 표시 + 401 예시 3종.
export function ApiAuth() {
  return applyDecorators(
    ApiBearerAuth(BEARER_AUTH),
    ApiFailure(
      ErrorStatus.AUTH_TOKEN_MISSING,
      ErrorStatus.AUTH_TOKEN_INVALID,
      ErrorStatus.AUTH_TOKEN_EXPIRED,
    ),
  );
}
