import 'reflect-metadata';
import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdir, writeFile } from 'node:fs/promises';
import { NestFactory } from '@nestjs/core';
import request from 'supertest';
import mysql from 'mysql2/promise';
import { AppModule } from '../dist/app.module.js';
import { setupApp } from '../dist/setup-app.js';

void test('실제 MySQL 회원·평점 API와 DB 제약 검증', async () => {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });
  let app;
  const evidence = {
    testedAt: new Date().toISOString(),
    database: 'MySQL',
    cases: [],
  };
  try {
    app = await NestFactory.create(AppModule, { logger: false });
    setupApp(app);
    await app.init();
    const api = request(app.getHttpServer());
    async function record(name, operation, expected) {
      const response = await operation;
      evidence.cases.push({
        name,
        status: response.status,
        response: response.body,
      });
      assert.equal(response.status, expected, name);
      return response.body;
    }
    const [[member]] = await connection.execute(
      'SELECT member_id FROM member WHERE email = ?',
      ['noco@umc.com'],
    );
    const [[empty]] = await connection.execute(
      'SELECT member_id FROM member WHERE email = ?',
      ['empty@umc.com'],
    );
    const id = Number(member.member_id);
    assert.equal(
      (
        await record(
          '닉네임 중복',
          api.get('/members/nickname/' + encodeURIComponent('수현')),
          200,
        )
      ).available,
      false,
    );
    assert.equal(
      (
        await record(
          '닉네임 사용 가능',
          api.get('/members/nickname/' + encodeURIComponent('신규영화팬')),
          200,
        )
      ).available,
      true,
    );
    assert.equal(
      (
        await record(
          '이메일 중복',
          api.get('/members/email/noco%40umc.com'),
          200,
        )
      ).available,
      false,
    );
    assert.equal(
      (
        await record(
          '이메일 사용 가능',
          api.get('/members/email/new%40example.com'),
          200,
        )
      ).available,
      true,
    );
    const rows = await record(
      '회원 평점 최신순',
      api.get('/members/' + id + '/ratings'),
      200,
    );
    assert.deepEqual(
      rows.map((row) => row.movieId),
      [155, 550],
    );
    assert.equal(typeof rows[0].ratingId, 'number');
    assert.deepEqual(
      Object.keys(rows[0]).sort(),
      [
        'ratingId',
        'movieId',
        'score',
        'comment',
        'createdAt',
        'updatedAt',
      ].sort(),
    );
    assert.deepEqual(
      await record(
        '평점 없는 회원',
        api.get('/members/' + empty.member_id + '/ratings'),
        200,
      ),
      [],
    );
    await record('없는 회원', api.get('/members/999999/ratings'), 404);
    await record(
      '닉네임 길이 오류',
      api.get('/members/nickname/' + encodeURIComponent('가')),
      400,
    );
    await record('이메일 형식 오류', api.get('/members/email/invalid'), 400);
    await record('회원 ID 오류', api.get('/members/abc/ratings'), 400);
    const first = await record(
      '페이지 0',
      api.get('/members/' + id + '/ratings?page=0&size=1'),
      200,
    );
    const second = await record(
      '페이지 1',
      api.get('/members/' + id + '/ratings?page=1&size=1'),
      200,
    );
    assert.notEqual(first[0].ratingId, second[0].ratingId);
    assert.deepEqual(
      await record(
        '페이지 끝',
        api.get('/members/' + id + '/ratings?page=2&size=1'),
        200,
      ),
      [],
    );
    await record(
      '잘못된 페이지 크기',
      api.get('/members/' + id + '/ratings?size=0'),
      400,
    );
    const allowed = await api
      .get('/members/' + id + '/ratings')
      .set('Origin', 'http://localhost:5173');
    assert.equal(
      allowed.headers['access-control-allow-origin'],
      'http://localhost:5173',
    );
    const denied = await api
      .get('/members/' + id + '/ratings')
      .set('Origin', 'http://localhost:5174');
    assert.equal(denied.headers['access-control-allow-origin'], undefined);
    evidence.cases.push({
      name: 'CORS 허용·불허 헤더',
      allowedOrigin: allowed.headers['access-control-allow-origin'],
      deniedOriginHeaderPresent: false,
    });
    // 검증용 변경은 트랜잭션 종료 시 모두 되돌립니다.
    await connection.beginTransaction();
    await assert.rejects(
      connection.execute(
        'INSERT INTO rating (member_id, movie_id, score) VALUES (?, 550, 5)',
        [id],
      ),
      (error) => error.code === 'ER_DUP_ENTRY',
    );
    await assert.rejects(
      connection.execute(
        'INSERT INTO member (email, password, nickname) VALUES (?, ?, ?)',
        ['noco@umc.com', 'dummy-only', '중복실험'],
      ),
      (error) => error.code === 'ER_DUP_ENTRY',
    );
    await assert.rejects(
      connection.execute(
        'INSERT INTO rating (member_id, movie_id, score) VALUES (?, 99999999, 6)',
        [id],
      ),
      (error) => error.code === 'ER_CHECK_CONSTRAINT_VIOLATED',
    );
    await connection.execute(
      'INSERT INTO favorite (member_id, movie_id) VALUES (?, 550)',
      [id],
    );
    await assert.rejects(
      connection.execute(
        'INSERT INTO favorite (member_id, movie_id) VALUES (?, 550)',
        [id],
      ),
      (error) => error.code === 'ER_DUP_ENTRY',
    );
    evidence.cases.push({
      name: 'DB UNIQUE 및 평점 범위 제약',
      verified: [
        'member.email',
        'rating(member_id,movie_id)',
        'favorite(member_id,movie_id)',
        'score 1~5',
      ],
    });
    await connection.rollback();
    evidence.result = 'PASS';
    await mkdir('docs/evidence', { recursive: true });
    await writeFile(
      'docs/evidence/mysql-api-results.json',
      JSON.stringify(evidence, null, 2) + '\n',
    );
    console.log('실제 MySQL 검증 ' + evidence.cases.length + '개 통과');
  } finally {
    try {
      await connection.rollback();
    } finally {
      await connection.end();
      await app?.close();
    }
  }
});
