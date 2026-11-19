import { NestFactory } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module.js';
import { setupApp } from './setup-app.js';
import type { CorsMode } from './setup-app.js';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  const config = app.get(ConfigService);
  const mode =
    process.argv.find((arg) => arg.startsWith('--cors='))?.slice(7) ??
    config.get<string>('CORS_MODE', 'restricted');
  if (!['restricted', 'disabled', 'wildcard'].includes(mode)) {
    throw new Error('CORS_MODE 설정을 확인하세요.');
  }
  const origins = config
    .get<string>('CORS_ORIGINS', 'http://localhost:5173')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  if (
    mode === 'restricted' &&
    (origins.length === 0 || origins.includes('*'))
  ) {
    throw new Error('restricted 모드에는 구체적인 허용 출처를 설정하세요.');
  }
  setupApp(app, { corsMode: mode as CorsMode, origins });
  const port =
    process.argv.find((arg) => arg.startsWith('--port='))?.slice(7) ??
    config.get<string>('PORT', '3001');
  await app.listen(Number(port), '127.0.0.1');
}
await bootstrap();
