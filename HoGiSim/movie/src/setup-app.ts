import { ValidationPipe } from '@nestjs/common';
import type { INestApplication } from '@nestjs/common';
import { HttpAdapterHost } from '@nestjs/core';
import { WriteExceptionFilter } from './write-exception.filter.js';

export type CorsMode = 'restricted' | 'disabled' | 'wildcard';

export function setupApp(
  app: INestApplication,
  options: { corsMode?: CorsMode; origins?: string[] } = {},
): void {
  app.useGlobalFilters(new WriteExceptionFilter(app.get(HttpAdapterHost)));
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
    }),
  );

  const mode = options.corsMode ?? 'restricted';
  if (mode !== 'disabled') {
    app.enableCors({
      origin:
        mode === 'wildcard'
          ? '*'
          : (options.origins ?? ['http://localhost:5173']),
      methods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
      credentials: false,
    });
  }
}
