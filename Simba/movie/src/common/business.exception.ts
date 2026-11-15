import { HttpException } from '@nestjs/common';
import { ErrorStatusValue } from './error-status';

// 서비스에서 throw new BusinessException(ErrorStatus.XXX) 형태로 사용한다.
// HttpExceptionFilter가 errorStatus의 code/message를 공통 실패 응답으로 바꾼다.
export class BusinessException extends HttpException {
  constructor(readonly errorStatus: ErrorStatusValue) {
    super(errorStatus.message, errorStatus.status);
  }
}
