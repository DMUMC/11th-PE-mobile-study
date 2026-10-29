import 'reflect-metadata';
import assert from 'node:assert/strict';
import { before, after, test } from 'node:test';
import { Test } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import request from 'supertest';
import { Member } from '../dist/entity/member.entity.js';
import { Rating } from '../dist/entity/rating.entity.js';
import { MemberController } from '../dist/controller/member.controller.js';
import { RatingController } from '../dist/controller/rating.controller.js';
import { MemberService } from '../dist/service/member.service.js';
import { RatingService } from '../dist/service/rating.service.js';
import { setupApp } from '../dist/setup-app.js';

const members = [
  {
    memberId: '1',
    nickname: '수현',
    email: 'noco@umc.com',
    password: 'never-return-password',
  },
  { memberId: '2', nickname: '민서', email: 'minseo@umc.com' },
  { memberId: '3', nickname: '영화새내기', email: 'empty@umc.com' },
];
const date = new Date('2026-10-29T01:00:00Z');
const ratings = [
  {
    ratingId: '1',
    member: members[0],
    movieId: '550',
    score: 5,
    comment: '최고의 영화!',
    createdAt: date,
    updatedAt: date,
  },
  {
    ratingId: '2',
    member: members[0],
    movieId: '155',
    score: 4,
    comment: null,
    createdAt: date,
    updatedAt: date,
  },
  {
    ratingId: '3',
    member: members[1],
    movieId: '550',
    score: 3,
    comment: '감상',
    createdAt: date,
    updatedAt: date,
  },
];
let lastFind;
async function createApp(corsMode = 'restricted') {
  const module = await Test.createTestingModule({
    controllers: [MemberController, RatingController],
    providers: [
      MemberService,
      RatingService,
      {
        provide: getRepositoryToken(Member),
        useValue: {
          existsBy: async (where) =>
            members.some((member) =>
              Object.entries(where).every(
                ([key, value]) => member[key] === value,
              ),
            ),
        },
      },
      {
        provide: getRepositoryToken(Rating),
        useValue: {
          find: async (options) => {
            lastFind = options;
            const rows = ratings
              .filter(
                (rating) =>
                  rating.member.memberId === options.where.member.memberId,
              )
              .toSorted((a, b) => Number(b.ratingId) - Number(a.ratingId));
            return options.take === undefined
              ? rows
              : rows.slice(options.skip, options.skip + options.take);
          },
        },
      },
    ],
  }).compile();
  const app = module.createNestApplication({ logger: false });
  setupApp(app, { corsMode });
  await app.init();
  return app;
}
let app;
let api;
before(async () => {
  app = await createApp();
  api = request(app.getHttpServer());
});
after(async () => {
  await app?.close();
});

void test('중복 닉네임과 신규 닉네임은 각각 available false/true', async () => {
  assert.deepEqual(
    (
      await api
        .get('/members/nickname/' + encodeURIComponent('수현'))
        .expect(200)
    ).body,
    { available: false },
  );
  assert.deepEqual(
    (
      await api
        .get('/members/nickname/' + encodeURIComponent('새로운닉네임'))
        .expect(200)
    ).body,
    { available: true },
  );
});
void test('중복 이메일과 신규 이메일은 각각 available false/true', async () => {
  assert.deepEqual(
    (await api.get('/members/email/noco%40umc.com').expect(200)).body,
    { available: false },
  );
  assert.deepEqual(
    (await api.get('/members/email/new%40example.com').expect(200)).body,
    { available: true },
  );
});
for (const nickname of ['가', '가'.repeat(13), '  ']) {
  void test('잘못된 닉네임은 400: ' + JSON.stringify(nickname), async () => {
    await api
      .get('/members/nickname/' + encodeURIComponent(nickname))
      .expect(400);
  });
}
for (const email of [
  'invalid',
  '@example.com',
  'a'.repeat(250) + '@example.com',
]) {
  void test('잘못된 이메일은 400: ' + email.length + '자', async () => {
    await api.get('/members/email/' + encodeURIComponent(email)).expect(400);
  });
}
void test('회원 1 평점 최신순, 숫자 ID, DTO 필드만 반환', async () => {
  const { body } = await api.get('/members/1/ratings').expect(200);
  assert.deepEqual(
    body.map((row) => row.ratingId),
    [2, 1],
  );
  assert.deepEqual(
    Object.keys(body[0]).sort(),
    [
      'ratingId',
      'movieId',
      'score',
      'comment',
      'createdAt',
      'updatedAt',
    ].sort(),
  );
  assert.equal(body[0].movieId, 155);
  assert.equal(body[0].comment, null);
  assert.equal(body[0].createdAt, '2026-10-29T01:00:00.000Z');
  assert.equal(JSON.stringify(body).includes('never-return-password'), false);
  assert.deepEqual(lastFind.order, { ratingId: 'DESC' });
});
void test('평점이 없는 회원은 빈 배열, 없는 회원은 404', async () => {
  assert.deepEqual((await api.get('/members/3/ratings').expect(200)).body, []);
  const { body } = await api.get('/members/999/ratings').expect(404);
  assert.match(body.message, /존재하지 않는/);
});
void test('회원별 평점을 섞지 않는다', async () => {
  const { body } = await api.get('/members/2/ratings').expect(200);
  assert.deepEqual(
    body.map((row) => row.ratingId),
    [3],
  );
});
for (const id of [
  '0',
  '-1',
  '1.2',
  'abc',
  '1e0',
  '0x1',
  '001',
  '9007199254740992',
]) {
  void test('잘못된 회원 ID는 400: ' + id, async () => {
    await api.get('/members/' + id + '/ratings').expect(400);
  });
}
void test('페이지 0/1은 겹치지 않으며 마지막 다음은 빈 배열', async () => {
  assert.equal(
    (await api.get('/members/1/ratings?page=0&size=1').expect(200)).body[0]
      .ratingId,
    2,
  );
  assert.equal(
    (await api.get('/members/1/ratings?page=1&size=1').expect(200)).body[0]
      .ratingId,
    1,
  );
  assert.deepEqual(
    (await api.get('/members/1/ratings?page=2&size=1').expect(200)).body,
    [],
  );
});
for (const query of [
  'page=-1',
  'page=1.2',
  'page=no',
  'size=0',
  'size=101',
  'size=1.2',
  'page=100001',
  'page=0&page=1',
  'sort=unknown',
]) {
  void test('잘못된 페이지 query는 400: ' + query, async () => {
    await api.get('/members/1/ratings?' + query).expect(400);
  });
}
void test('페이지 일부 생략 시 명세의 기본값 사용', async () => {
  assert.equal(
    (await api.get('/members/1/ratings?size=1').expect(200)).body.length,
    1,
  );
  assert.deepEqual(
    (await api.get('/members/1/ratings?page=1').expect(200)).body,
    [],
  );
});
void test('허용 출처는 정확한 ACAO, 불허 출처는 ACAO 없음', async () => {
  const allowed = await api
    .get('/members/1/ratings')
    .set('Origin', 'http://localhost:5173')
    .expect(200);
  assert.equal(
    allowed.headers['access-control-allow-origin'],
    'http://localhost:5173',
  );
  const denied = await api
    .get('/members/1/ratings')
    .set('Origin', 'http://localhost:5174')
    .expect(200);
  assert.equal(denied.headers['access-control-allow-origin'], undefined);
});
void test('preflight는 허용 출처와 메서드 응답', async () => {
  const response = await api
    .options('/members/1/ratings')
    .set('Origin', 'http://localhost:5173')
    .set('Access-Control-Request-Method', 'GET')
    .set('Access-Control-Request-Headers', 'X-Workbook')
    .expect(204);
  assert.match(response.headers['access-control-allow-methods'], /GET/);
  assert.equal(
    response.headers['access-control-allow-origin'],
    'http://localhost:5173',
  );
});
void test('CORS 미설정/전체 허용의 헤더 차이를 확인', async () => {
  for (const [mode, expected] of [
    ['disabled', undefined],
    ['wildcard', '*'],
  ]) {
    const other = await createApp(mode);
    try {
      const response = await request(other.getHttpServer())
        .get('/members/1/ratings')
        .set('Origin', 'http://localhost:5174')
        .expect(200);
      assert.equal(response.headers['access-control-allow-origin'], expected);
    } finally {
      await other.close();
    }
  }
});
