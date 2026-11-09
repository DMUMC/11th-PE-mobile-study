import { ValidationPipe } from '@nestjs/common';
import type { INestApplication } from '@nestjs/common';

export type CorsMode = 'restricted' | 'disabled' | 'wildcard';

export function setupApp(
  app: INestApplication,
  options: { corsMode?: CorsMode; origins?: string[] } = {},
): void {
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
