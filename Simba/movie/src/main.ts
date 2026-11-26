import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/http-exception.filter';
import { ResponseInterceptor } from './common/response.interceptor';
import { BEARER_AUTH } from './common/swagger';

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
    // 7주차: 브라우저가 Authorization 헤더를 보내려면 preflight에서 이 헤더를 허용해야 한다.
    allowedHeaders: ['Content-Type', 'Authorization'],
  });

  // (선택 미션) Swagger 문서: http://localhost:3000/api-docs
  // Authorize 버튼에 로그인으로 받은 accessToken을 넣으면 자물쇠가 붙은 API를 바로 호출할 수 있다.
  const swaggerConfig = new DocumentBuilder()
    .setTitle('MovieLog API (Simba)')
    .setDescription(
      '모든 응답은 { isSuccess, code, message, result } 형식입니다. 8주차: 즐겨찾기, 영화 기록(트랜잭션).',
    )
    .setVersion('8')
    .addBearerAuth(
      { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' },
      BEARER_AUTH,
    )
    .build();
  SwaggerModule.setup(
    'api-docs',
    app,
    SwaggerModule.createDocument(app, swaggerConfig),
  );

  await app.listen(process.env.PORT ?? 3000);
}
void bootstrap();
