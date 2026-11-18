import { HttpException, HttpStatus } from '@nestjs/common';

export function apiError(status: HttpStatus, code: string, message: string) {
  return new HttpException({ statusCode: status, code, message }, status);
}

export function isDuplicateKey(error: unknown): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    'driverError' in error &&
    typeof error.driverError === 'object' &&
    error.driverError !== null &&
    'code' in error.driverError &&
    error.driverError.code === 'ER_DUP_ENTRY'
  );
}
