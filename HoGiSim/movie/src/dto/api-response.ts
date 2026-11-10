export interface ApiResponse<T> {
  isSuccess: boolean;
  code: string;
  message: string;
  result: T;
}

export function success<T>(
  status: 200 | 201,
  message: string,
  result: T,
): ApiResponse<T> {
  return { isSuccess: true, code: `COMMON${status}`, message, result };
}
