import { CanActivate, ExecutionContext, Injectable } from '@nestjs/common';
import { JwtService, TokenExpiredError } from '@nestjs/jwt';
import { Request } from 'express';
import { ErrorStatus } from '../common/error-status';
import { ApiException } from '../exception/api.exception';

// 로그인할 때 발급한 Access Token의 payload. sub(subject)에 회원 id를 문자열로 담는다.
export interface AccessTokenPayload {
  sub: string;
}

// AuthGuard를 통과한 요청에는 토큰에서 꺼낸 memberId가 담겨 있다.
export interface AuthenticatedRequest extends Request {
  memberId: number;
}

// @UseGuards(AuthGuard)를 붙인 API는 컨트롤러에 들어가기 전에 이 가드를 거친다.
// 토큰이 없으면 AUTH401_2, 위조·손상된 토큰이면 AUTH401_3, 만료됐으면 AUTH401_4로 막는다.
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const token = this.extractBearerToken(request);
    if (!token) {
      throw new ApiException(ErrorStatus.AUTH_TOKEN_MISSING);
    }

    let payload: AccessTokenPayload;
    try {
      // 서명(JWT_SECRET)과 만료 시간(exp)을 함께 검증한다.
      payload = await this.jwtService.verifyAsync<AccessTokenPayload>(token);
    } catch (error) {
      // TokenExpiredError는 JsonWebTokenError의 하위 클래스라 먼저 확인해야 한다.
      if (error instanceof TokenExpiredError) {
        throw new ApiException(ErrorStatus.AUTH_TOKEN_EXPIRED);
      }
      throw new ApiException(ErrorStatus.AUTH_TOKEN_INVALID);
    }

    const memberId = Number(payload.sub);
    if (!Number.isSafeInteger(memberId) || memberId <= 0) {
      throw new ApiException(ErrorStatus.AUTH_TOKEN_INVALID);
    }

    request['memberId'] = memberId;
    return true;
  }

  // "Authorization: Bearer <token>" 형식일 때만 토큰을 꺼낸다.
  private extractBearerToken(request: Request): string | undefined {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' && token ? token : undefined;
  }
}
