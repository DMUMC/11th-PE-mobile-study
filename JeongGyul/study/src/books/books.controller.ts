// src/book.controller.ts
import { Controller, Get, Body, Post, Param } from '@nestjs/common';
import { BooksService } from './books.service';
import { CreateBookDto, BookResponseDto } from './dto/book.dto';

@Controller('books')
export class BooksController {
  constructor(private readonly booksService: BooksService) {}

  @Get()
  async getBooks(): Promise<BookResponseDto[]> {
    return await this.booksService.getAllBooks();
  }

  @Post()
  async createBook(@Body() dto: CreateBookDto): Promise<BookResponseDto> {
    return await this.booksService.createBook(dto);
  }

  // @Get('category/:categoryId')
  // async getBooksByCategoryId(
  //   @Param('categoryId') categoryId: number,
  // ): Promise<any> {
  //   return await this.booksService.getBooksByCategoryId(categoryId);
  // }
}
