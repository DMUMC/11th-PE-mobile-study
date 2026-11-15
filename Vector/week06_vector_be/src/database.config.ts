import { existsSync } from 'node:fs';
import { resolve } from 'node:path';
import { loadEnvFile } from 'node:process';
import type { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { Book } from './book.entity';
import { Category } from './category.entity';

export function databaseOptions(): TypeOrmModuleOptions {
  const envPath = resolve(process.cwd(), '.env');
  if (existsSync(envPath)) loadEnvFile(envPath);
  const username = process.env.DB_USERNAME;
  const database = process.env.DB_DATABASE;
  if (!username || !database) {
    throw new Error('Set DB_USERNAME and DB_DATABASE in .env before starting.');
  }
  const port = Number(process.env.DB_PORT ?? 3306);
  if (!Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('DB_PORT must be an integer between 1 and 65535.');
  }
  return {
    type: 'mysql',
    host: process.env.DB_HOST ?? '127.0.0.1',
    port,
    username,
    password: process.env.DB_PASSWORD ?? '',
    database,
    ...(process.env.DB_SOCKET_PATH
      ? { extra: { socketPath: process.env.DB_SOCKET_PATH } }
      : {}),
    entities: [Book, Category],
    autoLoadEntities: true,
    synchronize: false,
    logging: false,
    retryAttempts: 1,
  };
}
