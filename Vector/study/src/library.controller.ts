import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
} from '@nestjs/common';
import { LibraryService } from './library.service';

@Controller()
export class LibraryController {
  constructor(private readonly service: LibraryService) {}

  @Get('books/category/:categoryId')
  findBooksByCategory(@Param('categoryId', ParseIntPipe) categoryId: number) {
    return this.service.findBooksByCategory(categoryId);
  }

  @Post('rentals')
  createRental(@Body() body: unknown) {
    return this.service.createRental(body);
  }
}
