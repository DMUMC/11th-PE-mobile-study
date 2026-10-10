// src/book.service.ts
import { Injectable } from '@nestjs/common';
import { BooksRepository } from './books.repository';

@Injectable()
export class BooksService {
  // 창고지기(BookRepository)를 주입받습니다.
  constructor(private readonly booksRepository: BooksRepository) {}

  async getAllBooks(): Promise<any> {
    return await this.booksRepository.findAll();
  }

  // book.service.ts에 추가
  async createBook(body: Record<string, any>): Promise<string> {
    await this.booksRepository.create(body);
    return '도서 등록이 완료되었습니다!';
  }

  async getBooksByCategoryId(categoryId: number): Promise<any> {
    return await this.booksRepository.findBookByCategoryId(categoryId);
  }
}
