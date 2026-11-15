import { BadRequestException, Injectable } from '@nestjs/common';
import type { PipeTransform } from '@nestjs/common';

@Injectable()
export class SafeMemberIdPipe implements PipeTransform<string, string> {
  transform(value: string): string {
    const memberId = Number(value);
    if (!/^[1-9]\d*$/.test(value) || !Number.isSafeInteger(memberId)) {
      throw new BadRequestException('memberId는 양의 안전 정수여야 합니다.');
    }
    return value;
  }
}
