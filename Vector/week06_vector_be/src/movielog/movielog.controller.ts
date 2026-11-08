import {
  Body,
  Controller,
  Delete,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  UsePipes,
} from '@nestjs/common';
import { ValidationPipe } from '@nestjs/common';
import { apiError } from './api-error';
import {
  CreateRatingDto,
  EmailQuery,
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

  // For the local workbook the caller identity is supplied by the test client.
  @Post('ratings')
  create(
    @Headers('x-member-id') memberId: string | undefined,
    @Body() dto: CreateRatingDto,
  ) {
    return this.ratings.create(positiveId(memberId, 'x-member-id'), dto);
  }

  @Patch('ratings/:id')
  update(
    @Headers('x-member-id') memberId: string | undefined,
    @Param('id') id: string,
    @Body() dto: UpdateRatingDto,
  ) {
    return this.ratings.update(
      positiveId(id, 'id'),
      positiveId(memberId, 'x-member-id'),
      dto.score,
    );
  }

  @Delete('ratings/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(
    @Headers('x-member-id') memberId: string | undefined,
    @Param('id') id: string,
  ) {
    return this.ratings.remove(
      positiveId(id, 'id'),
      positiveId(memberId, 'x-member-id'),
    );
  }
}
