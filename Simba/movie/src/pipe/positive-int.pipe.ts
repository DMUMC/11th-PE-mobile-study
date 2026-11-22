import { BadRequestException, Injectable, PipeTransform } from '@nestjs/common';

// ParseIntPipe 뒤에 붙여 경로의 id가 1 이상인지 확인한다. 예) DELETE /favorites/0 → 400
@Injectable()
export class PositiveIntPipe implements PipeTransform<number, number> {
  transform(value: number): number {
    if (value < 1) {
      throw new BadRequestException('movieId는 양의 정수여야 합니다.');
    }
    return value;
  }
}
