import 'reflect-metadata';
import assert from 'node:assert/strict';
import { after, before, test } from 'node:test';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { QueryFailedError } from 'typeorm';
import { BookController } from '../dist/book.controller.js';
import { BookService } from '../dist/book.service.js';
import { BookRepository } from '../dist/book.repository.js';
import { setupApp } from '../dist/setup-app.js';

// DB가 없는 환경에서도 실제 Nest HTTP/DTO/Service 경로를 확인합니다.
// Repository만 대역으로 교체하며 실제 MySQL 검증은 별도로 수행합니다.
const category = { categoryId: 1, name: '프로그래밍' };
let rows = [];
let app;
let api;
const repository = {
  async findAll(keyword) {
    return rows
      .filter((book) => !keyword || book.title.includes(keyword))
      .toSorted((a, b) => b.bookId - a.bookId);
  },
  async findCategory(id) {
    return id === 1 ? category : null;
  },
  async create(category, title, description) {
    if (title === 'DB 연결 오류') throw new Error('database unavailable');
    if (rows.some((book) => book.title === title)) {
      throw new QueryFailedError(
        'INSERT',
        [],
        Object.assign(new Error('duplicate'), { code: 'ER_DUP_ENTRY' }),
      );
    }
    const book = {
      bookId: rows.length + 1,
      category,
      title,
      description: description ?? null,
      isAvailable: true,
    };
    rows.push(book);
    return book;
  },
};

before(async () => {
  const module = await Test.createTestingModule({
    controllers: [BookController],
    providers: [BookService, { provide: BookRepository, useValue: repository }],
  }).compile();
  app = module.createNestApplication({ logger: false });
  setupApp(app);
  await app.init();
  api = request(app.getHttpServer());
});
after(async () => {
  await app?.close();
});

test('빈 목록은 200과 빈 배열', async () => {
  const response = await api.get('/books').expect(200);
  assert.deepEqual(response.body, []);
});
test('POST 201, 응답 DTO와 기본 대여 가능 여부', async () => {
  const response = await api
    .post('/books')
    .send({ categoryId: 1, title: '스프링 입문' })
    .expect(201);
  assert.deepEqual(response.body, {
    bookId: 1,
    title: '스프링 입문',
    description: null,
    categoryName: '프로그래밍',
    isAvailable: true,
  });
});
test('최신순 목록에 대여 불가능 도서도 포함', async () => {
  await api
    .post('/books')
    .send({ categoryId: 1, title: 'NestJS', description: '설명' })
    .expect(201);
  rows[0].isAvailable = false;
  const { body } = await api.get('/books').expect(200);
  assert.deepEqual(
    body.map((row) => row.bookId),
    [2, 1],
  );
  assert.equal(body[1].isAvailable, false);
  assert.deepEqual(
    Object.keys(body[0]).sort(),
    ['bookId', 'title', 'description', 'categoryName', 'isAvailable'].sort(),
  );
});
test('제목 부분 검색과 검색 결과 없음', async () => {
  assert.equal(
    (await api.get('/books').query({ keyword: '스프링' }).expect(200)).body
      .length,
    1,
  );
  assert.deepEqual(
    (await api.get('/books').query({ keyword: '없는제목' }).expect(200)).body,
    [],
  );
});
test('중복 제목은 409', async () => {
  const { body } = await api
    .post('/books')
    .send({ categoryId: 1, title: '스프링 입문' })
    .expect(409);
  assert.match(body.message, /이미 등록/);
});
test('없는 카테고리는 404', async () => {
  await api
    .post('/books')
    .send({ categoryId: 999, title: '없는 카테고리' })
    .expect(404);
});
for (const [name, payload] of [
  ['빈 제목', { categoryId: 1, title: '' }],
  ['공백 제목', { categoryId: 1, title: '   ' }],
  ['제목 누락', { categoryId: 1 }],
  ['숫자 제목', { categoryId: 1, title: 123 }],
  ['101자 제목', { categoryId: 1, title: '가'.repeat(101) }],
  ['카테고리 누락', { title: '제목' }],
  ['문자열 카테고리', { categoryId: '1', title: '제목' }],
  ['음수 카테고리', { categoryId: -1, title: '제목' }],
  ['소수 카테고리', { categoryId: 1.5, title: '제목' }],
  ['boolean 카테고리', { categoryId: true, title: '제목' }],
  ['숫자 설명', { categoryId: 1, title: '제목', description: 123 }],
  ['임의 대여 상태', { categoryId: 1, title: '제목', isAvailable: false }],
]) {
  test(name + ' 요청은 400이며 저장되지 않음', async () => {
    const count = rows.length;
    await api.post('/books').send(payload).expect(400);
    assert.equal(rows.length, count);
  });
}
test('검색 파라미터 오류는 400', async () => {
  await api
    .get('/books')
    .query({ keyword: '가'.repeat(101) })
    .expect(400);
  await api.get('/books?keyword=a&keyword=b').expect(400);
});
test('100자 제목은 허용', async () => {
  await api
    .post('/books')
    .send({ categoryId: 1, title: '가'.repeat(100), description: null })
    .expect(201);
});
test('기타 DB 오류를 중복 오류로 오인하지 않음', async () => {
  await api
    .post('/books')
    .send({ categoryId: 1, title: 'DB 연결 오류' })
    .expect(500);
});
test('ORM 목록 조회는 관계 조인, 내림차순, LIKE 입력 이스케이프 사용', async () => {
  let options;
  const ormRepository = new BookRepository(
    {
      find: async (value) => {
        options = value;
        return [];
      },
    },
    {},
  );
  await ormRepository.findAll('100%_');
  assert.deepEqual(options.relations, { category: true });
  assert.deepEqual(options.order, { bookId: 'DESC' });
  assert.equal(options.where.title.value, '%100\\%\\_%');
});
