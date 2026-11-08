import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Response } from 'express';
import { QueryFailedError } from 'typeorm';
import { ApiResponse } from './api-response';
import { BusinessException } from './business.exception';
import { ErrorStatus, ErrorStatusValue } from './error-status';

// MySQL UNIQUE 인덱스 이름 → 실패 응답. 인덱스 이름은 sql/schema.sql 기준이다.
// (컬럼에 UNIQUE만 붙이면 MySQL이 컬럼 이름을 인덱스 이름으로 쓴다.)
const DUPLICATE_KEY_ERRORS: Record<string, ErrorStatusValue> = {
  email: ErrorStatus.MEMBER_EMAIL_DUPLICATED,
  nickname: ErrorStatus.MEMBER_NICKNAME_DUPLICATED,
  uk_rating_member_movie: ErrorStatus.RATING_DUPLICATED,
};

interface MysqlDriverError {
  code?: string;
  sqlMessage?: string;
}

interface Failure {
  status: number;
  body: ApiResponse<unknown>;
}

// 모든 예외를 { isSuccess: false, code, message, result } 형식으로 바꾼다.
@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    const { status, body } = this.toFailure(exception);
    response.status(status).json(body);
  }

  private toFailure(exception: unknown): Failure {
    // 1) 서비스에서 던진 비즈니스 예외
    if (exception instanceof BusinessException) {
      return this.from(exception.errorStatus);
    }

    // 2) DB 제약 위반: 사전 중복 체크를 통과한 동시 요청이 UNIQUE에 걸리는 경우
    if (exception instanceof QueryFailedError) {
      const driverError = exception.driverError as MysqlDriverError;
      if (driverError.code === 'ER_DUP_ENTRY') {
        return this.fromDuplicateEntry(driverError.sqlMessage ?? '');
      }
    }

    // 3) ValidationPipe, ParseIntPipe, 없는 경로 등 Nest 기본 HTTP 예외
    if (exception instanceof HttpException) {
      return this.fromHttpException(exception);
    }

    // 4) 잘못된 JSON 본문 (Express body-parser는 HttpException이 아닌 에러를 던진다)
    if (this.isBodyParseError(exception)) {
      return this.from(ErrorStatus.BAD_REQUEST, [
        'JSON 형식이 올바르지 않습니다.',
      ]);
    }

    // 5) 그 밖의 예상하지 못한 에러
    this.logger.error(exception);
    return this.from(ErrorStatus.INTERNAL_SERVER_ERROR);
  }

  // 예) "Duplicate entry 'a@b.com' for key 'member.email'" → 'email'
  private fromDuplicateEntry(sqlMessage: string): Failure {
    const keyName = /for key '(?:[^.']+\.)?([^']+)'/.exec(sqlMessage)?.[1];
    const errorStatus =
      (keyName && DUPLICATE_KEY_ERRORS[keyName]) || ErrorStatus.CONFLICT;
    this.logger.warn(
      `DB UNIQUE 제약 위반(${keyName ?? 'unknown'})을 ${errorStatus.code}로 변환했습니다.`,
    );
    return this.from(errorStatus);
  }

  private fromHttpException(exception: HttpException): Failure {
    const status = exception.getStatus();
    const body = exception.getResponse();
    // ValidationPipe는 { message: string[] } 형태로 어떤 필드가 왜 틀렸는지 알려준다.
    const detail: unknown =
      typeof body === 'object' && body !== null && 'message' in body
        ? body.message
        : body;

    if (status === Number(HttpStatus.BAD_REQUEST)) {
      return this.from(
        ErrorStatus.BAD_REQUEST,
        Array.isArray(detail) ? detail : [detail],
      );
    }
    if (status === Number(HttpStatus.NOT_FOUND)) {
      return this.from(ErrorStatus.NOT_FOUND);
    }
    return {
      status,
      body: ApiResponse.failure(`COMMON${status}`, String(detail)),
    };
  }

  private isBodyParseError(exception: unknown): boolean {
    return (
      typeof exception === 'object' &&
      exception !== null &&
      (exception as { type?: string }).type === 'entity.parse.failed'
    );
  }

  private from(errorStatus: ErrorStatusValue, result: unknown = null): Failure {
    return {
      status: errorStatus.status,
      body: ApiResponse.failure(errorStatus.code, errorStatus.message, result),
    };
  }
}
