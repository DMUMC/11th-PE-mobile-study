import { Controller, Post, Body } from '@nestjs/common';
import { RentalService } from './rental.service';

@Controller('rentals')
export class RentalController {
  constructor(private readonly rentalService: RentalService) {}

  @Post()
  async rentalBook(@Body() body: Record<string, any>): Promise<string> {
    return await this.rentalService.rentalBook(body);
  }
}
