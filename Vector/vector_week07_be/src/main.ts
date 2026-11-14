import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors({
    origin: (
      process.env.CORS_ORIGINS ?? 'http://127.0.0.1:8080,http://localhost:8080'
    )
      .split(',')
      .map((origin) => origin.trim()),
    methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
  });
  await app.listen(process.env.PORT ?? 3000, '127.0.0.1');
}
void bootstrap();
