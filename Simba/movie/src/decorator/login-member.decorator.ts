import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { AuthenticatedRequest } from '../guard/auth.guard';

// (선택 미션) AuthGuard가 request에 담아 둔 memberId를 컨트롤러 파라미터로 꺼낸다.
// 사용: @UseGuards(AuthGuard) + @LoginMember() memberId: number
// 컨트롤러가 'memberId'라는 문자열 키나 request 객체를 직접 다루지 않게 해 준다.
export const LoginMember = createParamDecorator(
  (_data: unknown, context: ExecutionContext): number =>
    context.switchToHttp().getRequest<AuthenticatedRequest>().memberId,
);
