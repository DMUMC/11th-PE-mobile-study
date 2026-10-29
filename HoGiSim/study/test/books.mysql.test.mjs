import 'reflect-metadata';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdir, writeFile } from 'node:fs/promises';
import mysql from 'mysql2/promise';
import request from 'supertest';
import { NestFactory } from '@nestjs/core';
import { AppModule } from '../dist/app.module.js';
import { setupApp } from '../dist/setup-app.js';

test('실제 MySQL + ORM + Nest HTTP 통합 검증', async () => {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST ?? 'localhost',
    port: Number(process.env.DB_PORT ?? 3306),
    user: process.env.DB_USER ?? 'root',
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME ?? 'study',
  });
  const marker = '미션검증-' + Date.now();
  const evidence = {
    testedAt: new Date().toISOString(),
    database: 'MySQL',
    cases: [],
  };
  let app;
  let categoryId;
  async function record(name, operation, status) {
    const response = await operation;
    evidence.cases.push({
      name,
      status: response.status,
      response: response.body,
    });
    assert.equal(response.status, status, name);
    return response.body;
  }
  try {
    const [category] = await connection.execute(
      'INSERT INTO category (name) VALUES (?)',
      [marker],
    );
    categoryId = category.insertId;
    app = await NestFactory.create(AppModule, { logger: false });
    setupApp(app);
    await app.init();
    const api = request(app.getHttpServer());
    const title = marker + '-스프링';
    const book = await record(
      'POST 도서 등록',
      api
        .post('/books')
        .send({ categoryId, title, description: '실제 MySQL 검증' }),
      201,
    );
    assert.equal(book.categoryName, marker);
    assert.equal(book.isAvailable, true);
    assert.deepEqual(
      Object.keys(book).sort(),
      ['bookId', 'title', 'description', 'categoryName', 'isAvailable'].sort(),
    );
    const [saved] = await connection.execute(
      'SELECT title FROM book WHERE book_id = ?',
      [book.bookId],
    );
    assert.equal(saved[0].title, title);
    const second = await record(
      'POST 선택 설명 생략',
      api.post('/books').send({ categoryId, title: marker + '-NestJS' }),
      201,
    );
    assert.equal(second.description, null);
    await connection.execute(
      'UPDATE book SET is_available = FALSE WHERE book_id = ?',
      [book.bookId],
    );
    const list = await record('GET 전체 목록', api.get('/books'), 200);
    assert.deepEqual(
      list.map((item) => item.bookId),
      list.map((item) => item.bookId).toSorted((a, b) => b - a),
    );
    assert.equal(
      list.find((item) => item.bookId === book.bookId).isAvailable,
      false,
    );
    const search = await record(
      'GET 제목 부분 검색',
      api.get('/books').query({ keyword: title }),
      200,
    );
    assert.equal(search.length, 1);
    const missing = await record(
      'GET 검색 결과 없음',
      api.get('/books').query({ keyword: marker + '-없음' }),
      200,
    );
    assert.deepEqual(missing, []);
    await record(
      'POST 중복 제목',
      api.post('/books').send({ categoryId, title }),
      409,
    );
    const [[{ missingId }]] = await connection.query(
      'SELECT COALESCE(MAX(category_id), 0) + 1 AS missingId FROM category',
    );
    await record(
      'POST 없는 카테고리',
      api
        .post('/books')
        .send({
          categoryId: Number(missingId),
          title: marker + '-없는카테고리',
        }),
      404,
    );
    for (const badTitle of ['', '   ', '가'.repeat(101)]) {
      await record(
        'POST 잘못된 제목 (' + badTitle.length + '자)',
        api.post('/books').send({ categoryId, title: badTitle }),
        400,
      );
    }
    await record(
      'POST 잘못된 카테고리 자료형',
      api.post('/books').send({ categoryId: '1', title }),
      400,
    );
    const specialTitle = marker + '-100%_완료';
    await record(
      'POST 특수문자 제목',
      api.post('/books').send({ categoryId, title: specialTitle }),
      201,
    );
    const specialSearch = await record(
      'GET LIKE 특수문자 검색',
      api.get('/books').query({ keyword: specialTitle }),
      200,
    );
    assert.equal(specialSearch.length, 1);
    assert.equal(specialSearch[0].title, specialTitle);
    const concurrent = await Promise.all(
      [1, 2].map(() =>
        api.post('/books').send({ categoryId, title: marker + '-동시등록' }),
      ),
    );
    assert.deepEqual(
      concurrent.map((response) => response.status).sort(),
      [201, 409],
    );
    evidence.cases.push({
      name: '동시 중복 등록 방지',
      statuses: concurrent.map((response) => response.status).sort(),
    });
    // Service를 거치지 않는 INSERT도 DB UNIQUE 제약으로 차단되는지 확인합니다.
    await assert.rejects(
      connection.execute(
        'INSERT INTO book (category_id, title, is_available) VALUES (?, ?, TRUE)',
        [categoryId, title],
      ),
      (error) => error.code === 'ER_DUP_ENTRY',
    );
    evidence.cases.push({
      name: '직접 SQL 중복 INSERT 차단',
      code: 'ER_DUP_ENTRY',
    });
    evidence.result = 'PASS';
    await mkdir('docs/evidence', { recursive: true });
    await writeFile(
      'docs/evidence/mysql-api-results.json',
      JSON.stringify(evidence, null, 2) + '\n',
    );
    console.log(
      '실제 MySQL 검증 ' +
        evidence.cases.length +
        '개 통과. docs/evidence/mysql-api-results.json 저장',
    );
  } finally {
    // 이번 테스트가 생성한 전용 카테고리의 데이터만 정리합니다.
    try {
      if (categoryId) {
        await connection.execute('DELETE FROM book WHERE category_id = ?', [
          categoryId,
        ]);
        await connection.execute('DELETE FROM category WHERE category_id = ?', [
          categoryId,
        ]);
      }
    } finally {
      await app?.close();
      await connection.end();
    }
  }
});
