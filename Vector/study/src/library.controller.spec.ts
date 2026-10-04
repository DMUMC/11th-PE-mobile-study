import { Test } from '@nestjs/testing';
import type { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { DATABASE_CONNECTION } from './database.provider';
import { LibraryController } from './library.controller';
import { LibraryService } from './library.service';
import { LibraryRepository } from './library.repository';

describe('Library API', () => {
  let app: INestApplication;
  const execute = jest.fn();

  beforeEach(async () => {
    execute.mockReset();
    const module = await Test.createTestingModule({
      controllers: [LibraryController],
      providers: [
        LibraryService,
        LibraryRepository,
        { provide: DATABASE_CONNECTION, useValue: { execute } },
      ],
    }).compile();
    app = module.createNestApplication();
    await app.init();
  });
  afterEach(async () => {
    await app.close();
  });

  it('filters books using the category parameter', async () => {
    execute.mockResolvedValueOnce([[{ book_id: 1, category_id: 2 }]]);
    await request(app.getHttpServer())
      .get('/books/category/2')
      .expect(200)
      .expect([{ book_id: 1, category_id: 2 }]);
    expect(execute).toHaveBeenCalledWith(
      'SELECT * FROM book WHERE category_id = ?',
      [2],
    );
  });

  it.each(['abc', '0', '-1', '1%20OR%201=1'])(
    'rejects invalid category %s',
    async (id) => {
      await request(app.getHttpServer())
        .get(`/books/category/${id}`)
        .expect(400);
      expect(execute).not.toHaveBeenCalled();
    },
  );

  it('creates a rental with database-generated dates and returns it', async () => {
    const rental = { rental_id: 3, user_id: 1, book_id: 2 };
    execute
      .mockResolvedValueOnce([{ insertId: 3 }])
      .mockResolvedValueOnce([[rental]]);
    await request(app.getHttpServer())
      .post('/rentals')
      .send({ userId: 1, bookId: 2 })
      .expect(201)
      .expect(rental);
    expect(execute).toHaveBeenNthCalledWith(
      1,
      expect.stringMatching(
        /VALUES \(\?, \?, NOW\(\), DATE_ADD\(NOW\(\), INTERVAL 7 DAY\)\)/,
      ),
      [1, 2],
    );
    expect(execute).toHaveBeenNthCalledWith(
      2,
      'SELECT * FROM rental WHERE rental_id = ?',
      [3],
    );
  });

  it.each([{}, { userId: '1', bookId: 2 }, { userId: 1, bookId: -1 }])(
    'rejects invalid rental input %j',
    async (body) => {
      await request(app.getHttpServer())
        .post('/rentals')
        .send(body)
        .expect(400);
      expect(execute).not.toHaveBeenCalled();
    },
  );

  it('reports missing users/books as a bad request', async () => {
    execute.mockRejectedValueOnce({ code: 'ER_NO_REFERENCED_ROW_2' });
    await request(app.getHttpServer())
      .post('/rentals')
      .send({ userId: 9999, bookId: 9999 })
      .expect(400);
  });
});
