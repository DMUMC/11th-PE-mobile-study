import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthController } from './controller/auth.controller';
import { FavoriteController } from './controller/favorite.controller';
import { MemberController } from './controller/member.controller';
import { MovieRecordController } from './controller/movie-record.controller';
import { RatingController } from './controller/rating.controller';
import { Favorite } from './entity/favorite.entity';
import { Member } from './entity/member.entity';
import { Rating } from './entity/rating.entity';
import { AuthGuard } from './guard/auth.guard';
import { AuthService } from './service/auth.service';
import { FavoriteService } from './service/favorite.service';
import { MemberService } from './service/member.service';
import { MovieRecordService } from './service/movie-record.service';
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
    TypeOrmModule.forFeature([Member, Rating, Favorite]),
    // global: true → 어느 클래스에서든 JwtService를 주입받을 수 있다.
    // registerAsync + ConfigService: .env를 읽은 뒤에 secret/expiresIn을 정한다.
    JwtModule.registerAsync({
      global: true,
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const secret = config.getOrThrow<string>('JWT_SECRET');
        if (secret.length < 32) {
          throw new Error('JWT_SECRET은 32자 이상이어야 합니다.');
        }
        return {
          secret,
          signOptions: {
            // .env 값은 항상 문자열이다. "3600"을 그대로 넘기면 jsonwebtoken이
            // 단위 없는 문자열을 밀리초로 해석해 3.6초짜리 토큰이 된다. 숫자(초)로 바꿔 넘긴다.
            expiresIn: Number(config.getOrThrow<string>('JWT_ACCESS_EXPIRATION')),
          },
        };
      },
    }),
  ],
  controllers: [
    AuthController,
    MemberController,
    RatingController,
    FavoriteController,
    MovieRecordController,
  ],
  providers: [
    AuthService,
    MemberService,
    RatingService,
    FavoriteService,
    MovieRecordService,
    AuthGuard,
  ],
})
export class AppModule {}
