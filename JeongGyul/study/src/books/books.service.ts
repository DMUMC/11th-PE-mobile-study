// src/book.service.ts
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Book } from './entities/book.entity';
import { Category } from './entities/category.entity';
import { CreateBookDto, BookResponseDto } from './dto/book.dto';

@Injectable()
export class BooksService {
  constructor(
    @InjectRepository(Book)
    private readonly booksRepository: Repository<Book>,

    @InjectRepository(Category)
    private readonly categoryRepository: Repository<Category>,
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

  async createBook(dto: CreateBookDto): Promise<BookResponseDto> {
    const category = await this.categoryRepository.findOneBy({
      categoryId: dto.categoryId,
    });

    if (!category) {
      throw new NotFoundException('존재하지 않는 카테고리입니다.');
    }

    const book = this.booksRepository.create({
      category,
      title: dto.title,
      description: dto.description ?? null,
      isAvailable: true,
    });

    const savedBook = await this.booksRepository.save(book);

    return BookResponseDto.from(savedBook);
  }

  // async getBooksByCategoryId(categoryId: number): Promise<any> {
  //   return await this.booksRepository.findBookByCategoryId(categoryId);
  // }
}
