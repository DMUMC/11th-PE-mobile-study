import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Member } from './member.entity';
import { MembersService } from './members.service';
import { MovieLogController } from './movielog.controller';
import { Rating } from './rating.entity';
import { RatingsService } from './ratings.service';

@Module({
  imports: [TypeOrmModule.forFeature([Member, Rating])],
  controllers: [MovieLogController],
  providers: [MembersService, RatingsService],
})
export class MovieLogModule {}
