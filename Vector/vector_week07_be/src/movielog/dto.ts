import { Transform } from 'class-transformer';
import {
  IsEmail,
  IsInt,
  IsString,
  Length,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class EmailQuery {
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim().toLowerCase() : value,
  )
  @IsEmail()
  @MaxLength(254)
  email: string;
}

export class NicknameQuery {
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @Length(2, 24)
  nickname: string;
}

export class LoginDto extends EmailQuery {
  @IsString()
  @Matches(/^(?=.*[A-Za-z])(?=.*[0-9])[\x21-\x7E]{8,72}$/, {
    message:
      'password must contain letters and digits and use 8 to 72 printable ASCII characters without spaces',
  })
  password: string;
}

export class SignupDto extends LoginDto {
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @Length(2, 24)
  nickname: string;
}

export class UpdateRatingDto {
  @IsInt()
  @Min(1)
  @Max(5)
  score: number;
}

export class CreateRatingDto extends UpdateRatingDto {
  @IsInt()
  @Min(1)
  @Max(2147483647)
  movieId: number;
}
