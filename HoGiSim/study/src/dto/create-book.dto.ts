import {
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateBookDto {
  @IsInt()
  @Min(1)
  @Max(2147483647)
  categoryId: number;

  @IsString()
  @Matches(/\S/u, { message: 'title은 공백만 입력할 수 없습니다.' })
  @MaxLength(100)
  title: string;

  @IsOptional()
  @IsString()
  description?: string | null;
}
