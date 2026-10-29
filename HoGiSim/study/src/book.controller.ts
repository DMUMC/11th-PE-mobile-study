import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Query,
} from '@nestjs/common';
import { BookService } from './book.service.js';
import { BookQueryDto } from './dto/book-query.dto.js';
import { CreateBookDto } from './dto/create-book.dto.js';
import type { BookResponseDto } from './dto/book-response.dto.js';

@Controller('books')
export class BookController {
  constructor(private readonly bookService: BookService) {}

  @Get()
  getBooks(@Query() query: BookQueryDto): Promise<BookResponseDto[]> {
    return this.bookService.getAllBooks(query.keyword);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  createBook(@Body() body: CreateBookDto): Promise<BookResponseDto> {
    return this.bookService.createBook(body);
  }
}
