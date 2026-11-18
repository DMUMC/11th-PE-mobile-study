import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
  UsePipes,
} from '@nestjs/common';
import { ValidationPipe } from '@nestjs/common';
import { CurrentMember, JwtGuard } from './auth';
import { apiError } from './api-error';
import {
  CreateRatingDto,
  EmailQuery,
  LoginDto,
  NicknameQuery,
  SignupDto,
  UpdateRatingDto,
} from './dto';
import { MembersService } from './members.service';
import { RatingsService } from './ratings.service';

function positiveId(value: string | undefined, field: string) {
  const id = Number(value);
  if (!value || !/^[0-9]+$/.test(value) || id < 1 || id > 2147483647) {
    throw apiError(
      HttpStatus.BAD_REQUEST,
      'VALIDATION_ERROR',
      field + ' must be a positive 32-bit integer',
    );
  }
  return id;
}

@Controller()
@UsePipes(
  new ValidationPipe({
    transform: true,
    whitelist: true,
    forbidNonWhitelisted: true,
    exceptionFactory: (errors) =>
      apiError(
        HttpStatus.BAD_REQUEST,
        'VALIDATION_ERROR',
        errors
          .flatMap((error) => Object.values(error.constraints ?? {}))
          .join(', '),
      ),
  }),
)
export class MovieLogController {
  constructor(
    private readonly members: MembersService,
    private readonly ratings: RatingsService,
  ) {}

  @Post('members')
  signup(@Body() dto: SignupDto) {
    return this.members.signup(dto);
  }

  @Post('auth/login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto) {
    return this.members.login(dto);
  }

  @Get('members/me')
  @UseGuards(JwtGuard)
  me(@CurrentMember() memberId: number) {
    return this.members.me(memberId);
  }

  @Get('members/check-email')
  checkEmail(@Query() query: EmailQuery) {
    return this.members.available('email', query.email);
  }

  @Get('members/check-nickname')
  checkNickname(@Query() query: NicknameQuery) {
    return this.members.available('nickname', query.nickname);
  }

  @Get('members/:memberId/ratings')
  list(@Param('memberId') memberId: string) {
    return this.ratings.list(positiveId(memberId, 'memberId'));
  }

  @Post('ratings')
  @UseGuards(JwtGuard)
  create(@CurrentMember() memberId: number, @Body() dto: CreateRatingDto) {
    return this.ratings.create(memberId, dto);
  }

  @Patch('ratings/:id')
  @UseGuards(JwtGuard)
  update(
    @CurrentMember() memberId: number,
    @Param('id') id: string,
    @Body() dto: UpdateRatingDto,
  ) {
    return this.ratings.update(positiveId(id, 'id'), memberId, dto.score);
  }

  @Delete('ratings/:id')
  @UseGuards(JwtGuard)
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@CurrentMember() memberId: number, @Param('id') id: string) {
    return this.ratings.remove(positiveId(id, 'id'), memberId);
  }
}
