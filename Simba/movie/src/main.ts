import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // 경로 파라미터 DTO(닉네임 2~12자, 이메일 형식)를 검사하고, 실패하면 400으로 응답한다.
  app.useGlobalPipes(new ValidationPipe({ whitelist: true }));

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
