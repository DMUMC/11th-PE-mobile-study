import 'reflect-metadata';
import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { mkdir, writeFile } from 'node:fs/promises';
import { test } from 'node:test';
import { NestFactory } from '@nestjs/core';
import { getRepositoryToken } from '@nestjs/typeorm';
import { compare } from 'bcrypt';
import mysql from 'mysql2/promise';
import request from 'supertest';
import { AppModule } from '../dist/app.module.js';
import { Member } from '../dist/entity/member.entity.js';
import { Rating } from '../dist/entity/rating.entity.js';
import { setupApp } from '../dist/setup-app.js';

void test('6주차 실제 HTTP·MySQL 쓰기 검증', { timeout: 30000 }, async () => {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
  });
  const nonce = randomBytes(4).toString('hex');
  const testEmail = (label) => `week06-${nonce}-${label}@example.com`;
  const signup = (label) => ({
    email: testEmail(label),
    nickname: `${label}${nonce}`,
    password: 'Movie!2026',
  });
  const memberA = signup('a');
  const memberB = signup('b');
  const evidence = { database: 'MySQL', cases: [], races: [] };
  let app;
  try {
    app = await NestFactory.create(AppModule, {
      logger: false,
      abortOnError: false,
    });
    setupApp(app);
    await app.init();
    const api = request(app.getHttpServer());
    async function send(name, method, path, status, body, code) {
      const req = api[method.toLowerCase()](path);
      const response = await (body === undefined ? req : req.send(body));
      const input = body?.password ? { ...body, password: '***' } : body;
      evidence.cases.push({
        name,
        method,
        path,
        input,
        status: response.status,
        response: response.status === 204 ? null : response.body,
      });
      assert.equal(response.status, status, name);
      if (code) {
        assert.deepEqual(Object.keys(response.body).sort(), [
          'code',
          'isSuccess',
          'message',
          'result',
        ]);
        assert.equal(response.body.code, code, name);
        assert.equal(response.body.isSuccess, status < 400);
        assert.equal(typeof response.body.message, 'string');
        if (status >= 400) assert.equal(response.body.result, null);
      }
      return response;
    }

    await send(
      '회원가입 DTO 오류',
      'POST',
      '/members',
      400,
      {
        email: 'invalid',
        nickname: 'a',
        password: 'weak',
      },
      'COMMON400',
    );
    await send(
      'bcrypt UTF-8 제한',
      'POST',
      '/members',
      400,
      {
        ...memberA,
        password: 'Aa1!' + '가'.repeat(24),
      },
      'COMMON400',
    );
    const registered = await send(
      '회원가입',
      'POST',
      '/members',
      201,
      memberA,
      'COMMON201',
    );
    const memberId = registered.body.result.memberId;
    assert.deepEqual(registered.body.result, {
      memberId,
      email: memberA.email,
      nickname: memberA.nickname,
    });
    const [[stored]] = await connection.execute(
      'SELECT password FROM member WHERE member_id = ?',
      [memberId],
    );
    assert.equal(stored.password.length, 60);
    assert.notEqual(stored.password, memberA.password);
    assert.equal(await compare(memberA.password, stored.password), true);
    evidence.passwordHash = { algorithm: 'bcrypt', length: 60, matches: true };
    const second = await send(
      '다른 회원 가입',
      'POST',
      '/members',
      201,
      memberB,
      'COMMON201',
    );
    const otherId = second.body.result.memberId;
    await send(
      '이메일 중복',
      'POST',
      '/members',
      409,
      {
        ...signup('dup'),
        email: memberA.email,
      },
      'MEMBER4091',
    );
    await send(
      '닉네임 중복',
      'POST',
      '/members',
      409,
      {
        ...signup('dup'),
        nickname: memberA.nickname,
      },
      'MEMBER4092',
    );

    const ratings = `/members/${memberId}/ratings`;
    const review = {
      movieId: 550,
      score: 5,
      comment: '두 번째로 봐도 좋았어요.',
    };
    await send(
      '잘못된 별점',
      'POST',
      ratings,
      400,
      { ...review, score: 6 },
      'COMMON400',
    );
    await send(
      '영화 ID 문자열',
      'POST',
      ratings,
      400,
      { ...review, movieId: '550' },
      'COMMON400',
    );
    await send(
      '후기 500자 초과',
      'POST',
      ratings,
      400,
      {
        ...review,
        comment: '가'.repeat(501),
      },
      'COMMON400',
    );
    await send(
      '없는 회원 평점 등록',
      'POST',
      '/members/9007199254740991/ratings',
      404,
      review,
      'COMMON404',
    );
    const created = await send(
      '평점 등록',
      'POST',
      ratings,
      201,
      review,
      'COMMON201',
    );
    const ratingId = created.body.result;
    const item = `${ratings}/${ratingId}`;
    const otherItem = `/members/${otherId}/ratings/${ratingId}`;
    await send('중복 평점', 'POST', ratings, 409, review, 'RATING4091');
    await send(
      '다른 회원 평점 수정',
      'PATCH',
      otherItem,
      403,
      { score: 4 },
      'COMMON403',
    );
    await send(
      '다른 회원 평점 삭제',
      'DELETE',
      otherItem,
      403,
      undefined,
      'COMMON403',
    );
    await send(
      '잘못된 평점 ID',
      'DELETE',
      `${ratings}/0`,
      400,
      undefined,
      'COMMON400',
    );
    await send(
      '평점 수정',
      'PATCH',
      item,
      200,
      { score: 4, comment: null },
      'COMMON200',
    );
    const list = await send('수정한 평점 조회', 'GET', ratings, 200);
    assert.equal(list.body[0].score, 4);
    assert.equal(list.body[0].comment, null);
    const deleted = await send('평점 삭제', 'DELETE', item, 204);
    assert.equal(deleted.text, '');
    await send(
      '삭제한 평점 수정',
      'PATCH',
      item,
      404,
      { score: 3 },
      'COMMON404',
    );
    await send(
      '삭제한 평점 재삭제',
      'DELETE',
      item,
      404,
      undefined,
      'COMMON404',
    );

    const membersRepo = app.get(getRepositoryToken(Member));
    const ratingsRepo = app.get(getRepositoryToken(Rating));
    for (const [name, repo, path, inputs, code] of [
      [
        '이메일',
        membersRepo,
        '/members',
        [signup('e'), { ...signup('f'), email: testEmail('e') }],
        'MEMBER4091',
      ],
      [
        '닉네임',
        membersRepo,
        '/members',
        [signup('n'), { ...signup('m'), nickname: signup('n').nickname }],
        'MEMBER4092',
      ],
      [
        '평점',
        ratingsRepo,
        ratings,
        [
          { movieId: 680, score: 4 },
          { movieId: 680, score: 5 },
        ],
        'RATING4091',
      ],
    ]) {
      const outcomes = await runRace(
        repo,
        inputs.map((input) => () => api.post(path).send(input)),
      );
      const responses = outcomes.responses.toSorted(
        (a, b) => a.status - b.status,
      );
      assert.deepEqual(
        responses.map((res) => res.status),
        [201, 409],
      );
      assert.equal(outcomes.arrivals, 2);
      assert.deepEqual(outcomes.driverCodes, ['ER_DUP_ENTRY']);
      assert.equal(responses[1].body.code, code);
      assert.equal(responses[1].body.result, null);
      evidence.races.push({
        name,
        method: 'POST',
        path,
        inputs: inputs.map((input) =>
          input.password ? { ...input, password: '***' } : input,
        ),
        bothReachedSave: outcomes.arrivals === 2,
        driverCodes: outcomes.driverCodes,
        responses: responses.map((res) => ({
          status: res.status,
          body: res.body,
        })),
      });
    }

    const [[count]] = await connection.execute(
      'SELECT COUNT(*) AS total FROM rating WHERE member_id = ? AND movie_id = 680',
      [memberId],
    );
    assert.equal(count.total, 1);
    evidence.duplicateRatingRows = count.total;
    if (process.env.WEEK06_EVIDENCE === '1') {
      await mkdir('docs/evidence/week06', { recursive: true });
      await writeFile(
        'docs/evidence/week06/mysql-http.json',
        JSON.stringify(evidence, null, 2) + '\n',
      );
    }
  } finally {
    try {
      const like = `week06-${nonce}-%@example.com`;
      await connection.execute(
        'DELETE rating FROM rating JOIN member USING (member_id) WHERE member.email LIKE ?',
        [like],
      );
      await connection.execute('DELETE FROM member WHERE email LIKE ?', [like]);
    } finally {
      await app?.close();
      await connection.end();
    }
  }
});

async function runRace(repository, operations) {
  const save = repository.save;
  const gate = Promise.withResolvers();
  const driverCodes = [];
  let arrivals = 0;
  const timer = setTimeout(() => gate.resolve(), 2000);
  // Hold both requests after their service checks and release them into MySQL together.
  repository.save = async function (...args) {
    arrivals += 1;
    if (arrivals === operations.length) gate.resolve();
    await gate.promise;
    try {
      return await save.apply(this, args);
    } catch (error) {
      driverCodes.push(error.driverError?.code);
      throw error;
    }
  };
  try {
    const responses = await Promise.all(
      operations.map((operation) => operation()),
    );
    return { responses, arrivals, driverCodes };
  } finally {
    clearTimeout(timer);
    repository.save = save;
  }
}
