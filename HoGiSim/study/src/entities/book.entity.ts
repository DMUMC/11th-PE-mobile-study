import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from 'typeorm';
import type { Relation } from 'typeorm';
import { Category } from './category.entity.js';

@Entity('book')
@Index('uq_book_title', ['title'], { unique: true })
export class Book {
  @PrimaryGeneratedColumn({ name: 'book_id' })
  bookId: number;

  @ManyToOne(() => Category, (category) => category.books, { nullable: false })
  @JoinColumn({ name: 'category_id' })
  category: Relation<Category>;

  @Column({ type: 'varchar', length: 100 })
  title: string;

  @Column({ type: 'text', nullable: true })
  description: string | null;

  @Column({ name: 'is_available', type: 'boolean', default: true })
  isAvailable: boolean;
}
