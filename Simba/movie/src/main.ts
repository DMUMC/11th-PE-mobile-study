import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/http-exception.filter';
import { ResponseInterceptor } from './common/response.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // DTO에 없는 필드는 조용히 지우지 않고 400으로 거절한다(whitelist + forbidNonWhitelisted).
  // 예) PATCH 본문에 movieId를 넣으면 "property movieId should not exist"
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true }),
  );

  // 성공 응답은 Interceptor, 실패 응답은 Filter가 { isSuccess, code, message, result }로 만든다.
  app.useGlobalInterceptors(new ResponseInterceptor());
  app.useGlobalFilters(new HttpExceptionFilter());

  // 브라우저(웹 화면)에서 호출할 때 필요한 CORS 설정. 허용할 출처만 명시한다.
  // Flutter 네이티브 앱은 브라우저가 아니라서 이 설정과 관계없이 호출된다.
  const allowedOrigins = (process.env.CORS_ORIGINS ?? 'http://localhost:5173')
    .split(',')
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);

  app.enableCors({
    origin: allowedOrigins,
    methods: ['GET', 'POST', 'PATCH', 'DELETE'],
  });

  await app.listen(process.env.PORT ?? 3000);
}
void bootstrap();
