import { IsString, IsNotEmpty, IsOptional, IsBoolean, IsNumber } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateBannerDto {
  @ApiProperty({ example: 'Summer Ethnic Collection' })
  @IsString()
  @IsNotEmpty()
  title: string;

  @ApiPropertyOptional({ example: 'Flat 50% wholesale discount on all Sarees' })
  @IsString()
  @IsOptional()
  subtitle?: string;

  @ApiPropertyOptional({ example: 'TRENDING NOW' })
  @IsString()
  @IsOptional()
  tag?: string;

  @ApiProperty({ example: 'https://images.unsplash.com/...' })
  @IsString()
  @IsNotEmpty()
  imageUrl: string;

  @ApiPropertyOptional({ example: 'Fashion' })
  @IsString()
  @IsOptional()
  category?: string;

  @ApiPropertyOptional({ example: 'Ethnic Wear' })
  @IsString()
  @IsOptional()
  subCategory?: string;

  @ApiPropertyOptional({ example: '#6C3BD5' })
  @IsString()
  @IsOptional()
  gradientStart?: string;

  @ApiPropertyOptional({ example: '#BB4DE0' })
  @IsString()
  @IsOptional()
  gradientEnd?: string;

  @ApiPropertyOptional({ example: true })
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;

  @ApiPropertyOptional({ example: 0 })
  @IsNumber()
  @IsOptional()
  displayOrder?: number;
}
