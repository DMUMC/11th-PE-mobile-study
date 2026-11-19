import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MemberController } from './controller/member.controller';
import { RatingController } from './controller/rating.controller';
import { Member } from './entity/member.entity';
import { Rating } from './entity/rating.entity';
import { MemberService } from './service/member.service';
import { RatingService } from './service/rating.service';

// 도메인 모듈 없이 AppModule 하나가 모든 Controller/Service/Entity를 등록한다 (레이어 구조).
@Module({
  imports: [
    // forRoot()가 .env를 process.env로 먼저 읽어 들인 뒤 아래 TypeORM 설정이 그 값을 사용한다.
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot({
      type: 'mysql',
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT ?? 3306),
      username: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
      autoLoadEntities: true,
      // TypeORM(mysql)은 BIGINT를 기본적으로 문자열("1")로 돌려준다.
      // id를 API 명세대로 number로 응답하기 위해 안전한 범위의 BIGINT는 number로 받는다.
      supportBigNumbers: true,
      bigNumberStrings: false,
      // 테이블은 sql/schema.sql로 직접 만든다. TypeORM이 스키마를 바꾸지 않게 한다.
      synchronize: false,
    }),
    TypeOrmModule.forFeature([Member, Rating]),
  ],
  controllers: [MemberController, RatingController],
  providers: [MemberService, RatingService],
})
export class AppModule {}
