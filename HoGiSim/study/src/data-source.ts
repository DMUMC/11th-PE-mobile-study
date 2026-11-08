import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { Book } from './entities/book.entity.js';
import { Category } from './entities/category.entity.js';
import { UniqueBookTitle1793232000000 } from './migrations/1793232000000-unique-book-title.js';

// CLI 실행 시 node --env-file=.env로 접속 정보를 읽습니다.
export default new DataSource({
  type: 'mysql',
  host: process.env.DB_HOST ?? 'localhost',
  port: Number(process.env.DB_PORT ?? 3306),
  username: process.env.DB_USER ?? 'root',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME ?? 'study',
  entities: [Book, Category],
  migrations: [UniqueBookTitle1793232000000],
  synchronize: false,
});
