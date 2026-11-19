import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { BooksModule } from './books.module';
import { MovieLogModule } from './movielog/movielog.module';
import { databaseOptions } from './database.config';

@Module({
  imports: [
    TypeOrmModule.forRoot(databaseOptions()),
    BooksModule,
    MovieLogModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
