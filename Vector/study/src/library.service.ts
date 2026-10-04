import { BadRequestException, Injectable } from '@nestjs/common';
import { LibraryRepository } from './library.repository';

@Injectable()
export class LibraryService {
  constructor(private readonly repository: LibraryRepository) {}

  findBooksByCategory(categoryId: number) {
    this.validateId(categoryId, 'categoryId');
    return this.repository.findBooksByCategory(categoryId);
  }

  async createRental(body: unknown) {
    if (typeof body !== 'object' || body === null || Array.isArray(body)) {
      throw new BadRequestException('userId와 bookId를 JSON으로 전달해주세요.');
    }
    const { userId, bookId } = body as Record<string, unknown>;
    this.validateId(userId, 'userId');
    this.validateId(bookId, 'bookId');
    try {
      return await this.repository.createRental(userId, bookId);
    } catch (error: unknown) {
      if (
        typeof error === 'object' &&
        error !== null &&
        'code' in error &&
        error.code === 'ER_NO_REFERENCED_ROW_2'
      ) {
        throw new BadRequestException(
          '존재하는 userId와 bookId를 입력해주세요.',
        );
      }
      throw error;
    }
  }

  private validateId(value: unknown, name: string): asserts value is number {
    if (
      typeof value !== 'number' ||
      !Number.isSafeInteger(value) ||
      value <= 0
    ) {
      throw new BadRequestException(`${name}는 양의 정수여야 합니다.`);
    }
  }
}
