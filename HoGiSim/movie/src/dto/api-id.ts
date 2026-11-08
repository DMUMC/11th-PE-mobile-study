import { InternalServerErrorException } from '@nestjs/common';

export function toApiId(value: string): number {
  const id = Number(value);
  if (!Number.isSafeInteger(id) || id <= 0) {
    throw new InternalServerErrorException(
      '저장된 식별자를 처리할 수 없습니다.',
    );
  }
  return id;
}
