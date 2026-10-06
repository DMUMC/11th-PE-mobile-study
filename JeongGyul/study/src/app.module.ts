import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { databaseProviders } from './database.provider';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { BookController } from './book/book.controller';
import { BookService } from './book/book.service';
import { BookRepository } from './book/book.repository';
import { RentalController } from './rental/rental.controller';
import { RentalService } from './rental/rental.service';
import { RentalRepository } from './rental/rental.repository';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),
  ],
  controllers: [AppController, BookController, RentalController],
  providers: [
    ...databaseProviders,
    AppService,
    BookService,
    BookRepository,
    RentalService,
    RentalRepository,
  ],
  exports: [...databaseProviders],
})
export class AppModule {}
