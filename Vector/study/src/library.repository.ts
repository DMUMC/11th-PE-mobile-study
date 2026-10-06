import { Inject, Injectable } from '@nestjs/common';
import type { Pool, ResultSetHeader, RowDataPacket } from 'mysql2/promise';
import { DATABASE_CONNECTION } from './database.provider';

@Injectable()
export class LibraryRepository {
  constructor(@Inject(DATABASE_CONNECTION) private readonly db: Pool) {}

  async findBooksByCategory(categoryId: number) {
    const [books] = await this.db.execute<RowDataPacket[]>(
      'SELECT * FROM book WHERE category_id = ?',
      [categoryId],
    );
    return books;
  }

  async createRental(userId: number, bookId: number) {
    const [result] = await this.db.execute<ResultSetHeader>(
      `INSERT INTO rental (user_id, book_id, rented_at, due_at)
       VALUES (?, ?, NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY))`,
      [userId, bookId],
    );
    const [rentals] = await this.db.execute<RowDataPacket[]>(
      'SELECT * FROM rental WHERE rental_id = ?',
      [result.insertId],
    );
    return rentals[0];
  }
}
