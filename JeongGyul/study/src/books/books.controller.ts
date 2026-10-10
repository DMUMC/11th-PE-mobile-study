// src/book.controller.ts
import { Controller, Get, Body, Post, Param } from '@nestjs/common';
import { BooksService } from './books.service';
import { BookResponseDto } from './dto/book.dto';

@Controller('books')
export class BooksController {
  constructor(private readonly booksService: BooksService) {}

  @Get()
  async getBooks(): Promise<BookResponseDto[]> {
    return await this.booksService.getAllBooks();
  }

  @Post()
  async createBook(@Body() body: Record<string, any>): Promise<string> {
    return await this.booksService.createBook(body);
  }

  // @Get('category/:categoryId')
  // async getBooksByCategoryId(
  //   @Param('categoryId') categoryId: number,
  // ): Promise<any> {
  //   return await this.booksService.getBooksByCategoryId(categoryId);
  // }
}
