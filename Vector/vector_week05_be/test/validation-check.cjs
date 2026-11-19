require('reflect-metadata');
require('ts-node').register({ project: require('node:path').resolve(__dirname, '../tsconfig.json') });
const assert = require('node:assert/strict');
const { BooksService } = require('../src/books.service.ts');
const { BooksController } = require('../src/books.controller.ts');
const { CreateBookDto } = require('../src/create-book.dto.ts');
const { createValidationPipe } = require('../src/validation.ts');
const { HTTP_CODE_METADATA } = require('@nestjs/common/constants');

(async () => {
  const pipe = createValidationPipe();
  const metadata = { type: 'body', metatype: CreateBookDto };
  const valid = { title: 'ORM test', description: 'Local validation only', categoryId: 1 };
  const dto = await pipe.transform(valid, metadata);
  assert.equal(dto.categoryId, 1);
  for (const invalid of [
    { ...valid, categoryId: 0 },
    { ...valid, categoryId: '1' },
    { ...valid, title: '' },
    { ...valid, description: 12 },
    { ...valid, unexpected: true },
    {},
  ]) {
    await assert.rejects(() => pipe.transform(invalid, metadata), e => e.getStatus() === 400);
  }
  let saved = 0;
  const category = { id: 1, name: 'Test category' };
  const books = {
    create: input => input,
    save: async input => { saved++; return { id: 5, ...input }; },
    find: async options => {
      assert.deepEqual(options, { relations: { category: true }, order: { id: 'DESC' } });
      return [];
    },
  };
  const categories = { findOneBy: async ({ id }) => id === 1 ? category : null };
  const service = new BooksService(books, categories);
  await assert.rejects(() => service.create({ ...valid, categoryId: 999999 }), e => e.getStatus() === 404);
  assert.equal(saved, 0, 'Missing category must not save a book');
  const created = await service.create(dto);
  assert.equal(created.category.name, 'Test category');
  assert.equal(created.isAvailable, true);
  assert.equal(saved, 1);
  assert.deepEqual(await service.findAll(), []);
  assert.equal(Reflect.getMetadata(HTTP_CODE_METADATA, BooksController.prototype.create), 201);
  console.log('PASS: DTO rejects 6 invalid inputs with 400; missing category returns 404 without save; creation maps category and availability; controller declares 201; query requests ID DESC.');
  console.log('Repository substitutes only. No real DB writes or HTTP requests were made.');
})().catch(error => { console.error(error); process.exitCode = 1; });
