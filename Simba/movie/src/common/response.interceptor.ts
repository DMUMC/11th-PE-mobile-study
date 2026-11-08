import {
  CallHandler,
  ExecutionContext,
  HttpStatus,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Response } from 'express';
import { Observable, map } from 'rxjs';
import { ApiResponse } from './api-response';

// 컨트롤러가 돌려준 값을 성공 응답 { isSuccess: true, code, message, result }로 감싼다.
@Injectable()
export class ResponseInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const response = context.switchToHttp().getResponse<Response>();

    return next.handle().pipe(
      map((data: unknown) => {
        // 204 No Content는 본문을 보내지 않는다.
        if (response.statusCode === Number(HttpStatus.NO_CONTENT)) {
          return undefined;
        }
        if (data instanceof ApiResponse) {
          return data;
        }
        const isCreated = response.statusCode === Number(HttpStatus.CREATED);
        return ApiResponse.success(
          data ?? null,
          isCreated ? 'COMMON201' : 'COMMON200',
          isCreated ? '생성되었습니다.' : '성공입니다.',
        );
      }),
    );
  }
}
