import { IsOptional, IsString, MaxLength } from 'class-validator';

export class BookQueryDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  keyword?: string;
}
