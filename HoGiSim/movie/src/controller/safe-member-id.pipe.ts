import { BadRequestException, Injectable } from '@nestjs/common';
import type { ArgumentMetadata, PipeTransform } from '@nestjs/common';

@Injectable()
export class SafeIdPipe implements PipeTransform<string, string> {
  transform(value: string, metadata: ArgumentMetadata): string {
    const id = Number(value);
    if (!/^[1-9]\d*$/.test(value) || !Number.isSafeInteger(id)) {
      throw new BadRequestException(
        `${metadata.data}는 양의 안전 정수여야 합니다.`,
      );
    }
    return value;
  }
}
