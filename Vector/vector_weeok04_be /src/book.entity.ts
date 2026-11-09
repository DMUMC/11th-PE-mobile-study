import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';

import { Category } from './category.entity';

@Entity('book')
export class Book {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  title: string;

  @Column()
  description: string;

  @Column({ default: true })
  isAvailable: boolean;

  @ManyToOne(() => Category, category => category.books)
  @JoinColumn({ name: 'category_id' })
  category: Category;
}