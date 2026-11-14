import {
  CanActivate,
  createParamDecorator,
  ExecutionContext,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { createHmac, timingSafeEqual } from 'node:crypto';
import type { Request } from 'express';
import { apiError } from './api-error';

const header = Buffer.from(
  JSON.stringify({ alg: 'HS256', typ: 'JWT' }),
).toString('base64url');
type AuthenticatedRequest = Request & { memberId: number };

export function unauthorized() {
  return apiError(
    HttpStatus.UNAUTHORIZED,
    'UNAUTHORIZED',
    '인증이 필요합니다.',
  );
}

@Injectable()
export class AccessTokens {
  private signature(data: string) {
    const secret = process.env.JWT_SECRET;
    if (!secret || Buffer.byteLength(secret) < 32) {
      throw new Error('Set JWT_SECRET to at least 32 bytes.');
    }
    return createHmac('sha256', secret).update(data).digest('base64url');
  }

  issue(memberId: number) {
    const iat = Math.floor(Date.now() / 1000);
    const payload = Buffer.from(
      JSON.stringify({ sub: String(memberId), iat, exp: iat + 3600 }),
    ).toString('base64url');
    const data = header + '.' + payload;
    return data + '.' + this.signature(data);
  }

  verify(authorization?: string) {
    const match = /^Bearer ([\w-]+)\.([\w-]+)\.([\w-]{43})$/i.exec(
      authorization ?? '',
    );
    if (!match || match[1] !== header) throw unauthorized();
    const signature = this.signature(match[1] + '.' + match[2]);
    if (!timingSafeEqual(Buffer.from(match[3]), Buffer.from(signature))) {
      throw unauthorized();
    }
    let claims: { sub: string; exp: number };
    try {
      claims = JSON.parse(Buffer.from(match[2], 'base64url').toString('utf8'));
    } catch {
      throw unauthorized();
    }
    if (
      typeof claims?.sub !== 'string' ||
      !/^[1-9]\d*$/.test(claims.sub) ||
      Number(claims.sub) > 2147483647 ||
      !Number.isSafeInteger(claims.exp) ||
      claims.exp <= Math.floor(Date.now() / 1000)
    ) {
      throw unauthorized();
    }
    return Number(claims.sub);
  }
}

@Injectable()
export class JwtGuard implements CanActivate {
  constructor(private readonly tokens: AccessTokens) {}

  canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    request.memberId = this.tokens.verify(request.headers.authorization);
    return true;
  }
}

export const CurrentMember = createParamDecorator(
  (_data: unknown, context: ExecutionContext) =>
    context.switchToHttp().getRequest<AuthenticatedRequest>().memberId,
);
