import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Like, Repository } from 'typeorm';
import { Book } from './entities/book.entity.js';
import { Category } from './entities/category.entity.js';

@Injectable()
export class BookRepository {
  constructor(
    @InjectRepository(Book) private readonly books: Repository<Book>,
    @InjectRepository(Category)
    private readonly categories: Repository<Category>,
  ) {}

  findAll(keyword?: string): Promise<Book[]> {
    // LIKE의 특수 문자를 이스케이프하여 입력한 제목 자체를 검색합니다.
    const escaped = keyword?.replace(/[\\%_]/g, '\\$&');
    return this.books.find({
      where: escaped ? { title: Like(`%${escaped}%`) } : {},
      relations: { category: true },
      order: { bookId: 'DESC' },
    });
  }

  findCategory(categoryId: number): Promise<Category | null> {
    return this.categories.findOneBy({ categoryId });
  }

  create(
    category: Category,
    title: string,
    description?: string | null,
  ): Promise<Book> {
    return this.books.save(
      this.books.create({
        category,
        title,
        description: description ?? null,
        isAvailable: true,
      }),
    );
  }
}
