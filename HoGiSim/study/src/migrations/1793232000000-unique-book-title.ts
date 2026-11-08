import { TableIndex } from 'typeorm';
import type { MigrationInterface, QueryRunner } from 'typeorm';

export class UniqueBookTitle1793232000000 implements MigrationInterface {
  // MySQL DDL은 암묵적으로 커밋되므로 트랜잭션으로 감싸지 않습니다.
  transaction = false;

  async up(queryRunner: QueryRunner): Promise<void> {
    const duplicates = (await queryRunner.query(
      'SELECT title, COUNT(*) AS count FROM book GROUP BY title HAVING COUNT(*) > 1 LIMIT 1',
    )) as unknown[];
    if (duplicates.length > 0) {
      throw new Error(
        '중복 제목이 있어 UNIQUE 인덱스를 추가할 수 없습니다. 기존 데이터를 먼저 확인하세요.',
      );
    }
    await queryRunner.createIndex(
      'book',
      new TableIndex({
        name: 'uq_book_title',
        columnNames: ['title'],
        isUnique: true,
      }),
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.dropIndex('book', 'uq_book_title');
  }
}
