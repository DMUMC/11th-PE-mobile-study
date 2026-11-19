import mysql from 'mysql2/promise';
import { readFile } from 'node:fs/promises';

let connection;
try {
  if (
    !process.env.DB_PASSWORD ||
    process.env.DB_PASSWORD === 'your_mysql_password'
  ) {
    throw new Error('.env에 실제 MySQL 접속 정보를 입력하세요.');
  }
  const database = process.env.DB_NAME ?? 'umc_movie';
  if (!/^[A-Za-z0-9_]+$/.test(database))
    throw new Error('DB_NAME 설정을 확인하세요.');
  connection = await mysql.createConnection({
    host: process.env.DB_HOST ?? '127.0.0.1',
    port: Number(process.env.DB_PORT ?? 3307),
    user: process.env.DB_USER ?? 'root',
    password: process.env.DB_PASSWORD,
    multipleStatements: true,
  });
  await connection.query(
    'CREATE DATABASE IF NOT EXISTS ?? CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci',
    [database],
  );
  await connection.changeUser({ database });
  await connection.query("SET time_zone = '+00:00'");
  await connection.query(await readFile('sql/schema.sql', 'utf8'));
  await connection.query(await readFile('sql/seed.sql', 'utf8'));
  const [members] = await connection.query(
    'SELECT member_id AS memberId, nickname FROM member ORDER BY member_id',
  );
  const [ratings] = await connection.query(
    'SELECT COUNT(*) AS count FROM rating',
  );
  console.log({ members, ratingCount: ratings[0].count });
} catch (error) {
  console.error('DB 준비 실패:', error.code ?? error.message);
  process.exitCode = 1;
} finally {
  await connection?.end();
}
