import mysql from 'mysql2/promise';

let connection;
try {
  if (process.env.DB_PASSWORD === 'your_local_mysql_password') {
    throw new Error('.env의 DB_PASSWORD를 실제 MySQL 비밀번호로 바꿔주세요.');
  }
  connection = await mysql.createConnection({
    host: process.env.DB_HOST ?? 'localhost',
    port: Number(process.env.DB_PORT ?? 3306),
    user: process.env.DB_USER ?? 'root',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME ?? 'study',
    connectTimeout: 5000,
  });
  for (const table of ['category', 'book']) {
    const [rows] = await connection.query('SHOW CREATE TABLE ??', [table]);
    console.log(rows[0]['Create Table']);
  }
  const [counts] = await connection.query(
    'SELECT (SELECT COUNT(*) FROM category) AS categoryCount, (SELECT COUNT(*) FROM book) AS bookCount',
  );
  console.log(counts[0]);
} catch (error) {
  // 접속 정보/비밀번호를 출력하지 않습니다.
  console.error('DB 확인 실패:', error.code ?? error.message);
  process.exitCode = 1;
} finally {
  await connection?.end();
}
