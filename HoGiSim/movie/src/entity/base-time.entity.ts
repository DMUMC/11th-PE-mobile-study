import { CreateDateColumn, UpdateDateColumn } from 'typeorm';

export abstract class BaseTimeEntity {
  @CreateDateColumn({
    name: 'created_at',
    type: 'datetime',
    precision: 0,
    default: () => 'CURRENT_TIMESTAMP',
    update: false,
  })
  createdAt: Date;

  @UpdateDateColumn({
    name: 'updated_at',
    type: 'datetime',
    precision: 0,
    default: () => 'CURRENT_TIMESTAMP',
    onUpdate: 'CURRENT_TIMESTAMP',
  })
  updatedAt: Date;
}
