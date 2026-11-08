import mysql from 'mysql2/promise';
if (process.env.DB_HOST !== '127.0.0.1' || process.env.DB_PORT !== '3307') {
  throw new Error('전용 실습 MySQL(127.0.0.1:3307)에서만 종료할 수 있습니다.');
}
const connection = await mysql.createConnection({
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});
try {
  await connection.query('SHUTDOWN');
} finally {
  await connection.end();
}
console.log('실습 MySQL을 종료했습니다.');
