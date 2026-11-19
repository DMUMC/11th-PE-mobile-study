import { HttpException } from '@nestjs/common';
import { ErrorStatusValue } from '../common/error-status';

// 서비스·가드에서 throw new ApiException(ErrorStatus.XXX) 형태로 사용한다.
// HttpException을 상속하므로 HTTP 상태는 getStatus()로, 응답 code는 this.code로 꺼낸다.
// HttpExceptionFilter가 이 code/message를 공통 실패 응답 { isSuccess: false, code, message, result }로 바꾼다.
export class ApiException extends HttpException {
  readonly code: string;

  constructor(errorStatus: ErrorStatusValue) {
    super(errorStatus.message, errorStatus.status);
    this.code = errorStatus.code;
  }
}
