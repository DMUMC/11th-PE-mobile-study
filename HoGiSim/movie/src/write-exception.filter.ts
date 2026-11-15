import {
  Catch,
  HttpException,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import type { ArgumentsHost } from '@nestjs/common';
import { BaseExceptionFilter, HttpAdapterHost } from '@nestjs/core';
import type { Request } from 'express';
import { QueryFailedError } from 'typeorm';
import { uniqueConflict } from './write-errors.js';
import type { ApiResponse } from './dto/api-response.js';

@Catch()
export class WriteExceptionFilter extends BaseExceptionFilter {
  private readonly logger = new Logger(WriteExceptionFilter.name);

  constructor(private readonly adapterHost: HttpAdapterHost) {
    super(adapterHost.httpAdapter);
  }

  override catch(exception: unknown, host: ArgumentsHost): void {
    const context = host.switchToHttp();
    const { method } = context.getRequest<Request>();
    if (method !== 'POST' && method !== 'PATCH' && method !== 'DELETE') {
      super.catch(exception, host);
      return;
    }

    const error = this.toHttpException(exception);
    const status = error.getStatus();
    const detail = error.getResponse();
    const payload = typeof detail === 'string' ? { message: detail } : detail;
    const message = 'message' in payload ? payload.message : undefined;
    const code = 'code' in payload ? payload.code : undefined;
    const response: ApiResponse<null> = {
      isSuccess: false,
      code: typeof code === 'string' ? code : `COMMON${status}`,
      message:
        status >= 500
          ? '서버 오류가 발생했습니다.'
          : Array.isArray(message)
            ? message.join(' ')
            : typeof message === 'string'
              ? message
              : error.message,
      result: null,
    };
    this.adapterHost.httpAdapter.reply(context.getResponse(), response, status);
  }

  private toHttpException(exception: unknown): HttpException {
    if (exception instanceof HttpException) return exception;
    if (exception instanceof QueryFailedError) {
      const driverError: unknown = exception.driverError;
      if (
        driverError instanceof Error &&
        'code' in driverError &&
        driverError.code === 'ER_DUP_ENTRY'
      ) {
        return uniqueConflict(driverError.message);
      }
    }
    this.logger.error('쓰기 요청 처리 중 예기치 않은 오류가 발생했습니다.');
    return new InternalServerErrorException();
  }
}
