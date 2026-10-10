// src/book.controller.ts
import { Controller, Get, Body, Post, Param } from '@nestjs/common';
import { BooksService } from './books.service';

@Controller('books') // 이 컨트롤러로 들어오는 기본 주소: /books
export class BooksController {
  // 주방장(BookService)을 주입받습니다.
  constructor(private readonly booksService: BooksService) {}

  // HTTP GET 방식으로 /books 요청이 들어왔을 때 실행되는 핸들러
  @Get()
  async getBooks(): Promise<any> {
    return await this.booksService.getAllBooks();
  }

  // POST http://localhost:3000/books
  @Post()
  async createBook(@Body() body: Record<string, any>): Promise<string> {
    return await this.booksService.createBook(body);
  }

  @Get('category/:categoryId')
  async getBooksByCategoryId(
    @Param('categoryId') categoryId: number,
  ): Promise<any> {
    return await this.booksService.getBooksByCategoryId(categoryId);
  }
}
