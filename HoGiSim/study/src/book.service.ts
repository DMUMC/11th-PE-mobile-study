import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { QueryFailedError } from 'typeorm';
import { BookRepository } from './book.repository.js';
import { BookResponseDto } from './dto/book-response.dto.js';
import type { CreateBookDto } from './dto/create-book.dto.js';

@Injectable()
export class BookService {
  constructor(private readonly bookRepository: BookRepository) {}

  async getAllBooks(keyword?: string): Promise<BookResponseDto[]> {
    return (await this.bookRepository.findAll(keyword)).map(
      BookResponseDto.from,
    );
  }

  async createBook(body: CreateBookDto): Promise<BookResponseDto> {
    const category = await this.bookRepository.findCategory(body.categoryId);
    if (!category) {
      throw new NotFoundException('존재하지 않는 카테고리입니다.');
    }

    try {
      return BookResponseDto.from(
        await this.bookRepository.create(
          category,
          body.title,
          body.description,
        ),
      );
    } catch (error) {
      if (error instanceof QueryFailedError) {
        const driverError = error.driverError as { code?: string };
        // DB UNIQUE 제약이 동시 요청의 중복 등록도 막습니다.
        if (driverError.code === 'ER_DUP_ENTRY') {
          throw new ConflictException('이미 등록된 도서 제목입니다.');
        }
        if (driverError.code === 'ER_NO_REFERENCED_ROW_2') {
          throw new NotFoundException('존재하지 않는 카테고리입니다.');
        }
      }
      throw error;
    }
  }
}
