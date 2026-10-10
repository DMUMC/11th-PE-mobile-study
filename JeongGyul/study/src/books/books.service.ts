// src/book.service.ts
import { Injectable } from '@nestjs/common';
import { BooksRepository } from './books.repository';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Book } from './entities/book.entity';
import { BookResponseDto } from './dto/book.dto';

@Injectable()
export class BooksService {
  constructor(
    @InjectRepository(Book) private readonly booksRepository: Repository<Book>,
  ) {}

  async getAllBooks(): Promise<BookResponseDto[]> {
    const books = await this.booksRepository.find({
      relations: {
        category: true,
      },
      order: {
        bookId: 'DESC',
      },
    });

    return books.map((book) => BookResponseDto.from(book));
  }

  async createBook(body: Record<string, any>): Promise<string> {
    await this.booksRepository.create(body);
    return '도서 등록이 완료되었습니다!';
  }

  // async getBooksByCategoryId(categoryId: number): Promise<any> {
  //   return await this.booksRepository.findBookByCategoryId(categoryId);
  // }
}
