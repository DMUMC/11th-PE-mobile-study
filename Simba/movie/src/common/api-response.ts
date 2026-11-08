// 성공·실패 모두 같은 모양으로 응답한다: { isSuccess, code, message, result }
export class ApiResponse<T> {
  constructor(
    readonly isSuccess: boolean,
    readonly code: string,
    readonly message: string,
    readonly result: T | null,
  ) {}

  static success<T>(
    result: T,
    code = 'COMMON200',
    message = '성공입니다.',
  ): ApiResponse<T> {
    return new ApiResponse(true, code, message, result);
  }

  static failure<T = null>(
    code: string,
    message: string,
    result: T | null = null,
  ): ApiResponse<T> {
    return new ApiResponse(false, code, message, result);
  }
}
