import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Book } from './book.entity';
import { Category } from './category.entity';
import { CreateBookDto } from './create-book.dto';

@Injectable()
export class BooksService {
  constructor(
    @InjectRepository(Book) private readonly books: Repository<Book>,
    @InjectRepository(Category) private readonly categories: Repository<Category>,
  ) {}

  findAll() {
    // No creation timestamp exists: use descending auto-increment IDs.
    return this.books.find({ relations: { category: true }, order: { id: 'DESC' } });
  }

  async create(dto: CreateBookDto) {
    const category = await this.categories.findOneBy({ id: dto.categoryId });
    if (!category) {
      throw new NotFoundException(`Category ${dto.categoryId} not found`);
    }
    const book = this.books.create({
      title: dto.title,
      description: dto.description,
      category,
      isAvailable: true,
    });
    return this.books.save(book);
  }
}
