import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { createObserveModule } from '@nestjs/observe';
import { databaseProviders } from './database.provider';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { LibraryController } from './library.controller';
import { LibraryService } from './library.service';
import { LibraryRepository } from './library.repository';

export const { ObserveModule, ObserveInstrument } = createObserveModule();

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),

    ...(process.env.OBSERVE_APP_KEY && process.env.OBSERVE_APP_SECRET
      ? [
          ObserveModule.forRoot({
            appKey: process.env.OBSERVE_APP_KEY,
            appSecret: process.env.OBSERVE_APP_SECRET,
            serviceId: 'study',
          }),
        ]
      : []),
  ],

  controllers: [AppController, LibraryController],

  providers: [
    ...databaseProviders,
    AppService,
    LibraryService,
    LibraryRepository,
  ],

  exports: [...databaseProviders],
})
export class AppModule {}
