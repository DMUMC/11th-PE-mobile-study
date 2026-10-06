import { Injectable } from '@nestjs/common';
import { RentalRepository } from './rental.repository';

@Injectable()
export class RentalService {
  constructor(private readonly rentalRepository: RentalRepository) {}

  async rentalBook(body: Record<string, any>): Promise<string> {
    await this.rentalRepository.rentalBook(body);
    return '도서 대여가 완료되었습니다!';
  }
}
