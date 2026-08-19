import { IsString, IsNumber, IsOptional, Min, IsArray, IsBoolean } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateProductDto {
  @ApiProperty({ example: 'Basmati Rice 25kg' })
  @IsString()
  name: string;

  @ApiPropertyOptional({ example: 'Premium long-grain basmati rice' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiProperty({ example: 1250.00 })
  @IsNumber()
  @Min(0)
  pricePerUnit: number;

  @ApiProperty({ example: 'bag' })
  @IsString()
  unit: string;

  @ApiProperty({ example: 100 })
  @IsNumber()
  @Min(0)
  stockQuantity: number;

  @ApiPropertyOptional({ example: 'Grains' })
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({ type: [String], example: [] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  images?: string[];

  @ApiPropertyOptional({ example: 10.0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  discount?: number;

  @ApiPropertyOptional({ example: '8901234567890' })
  @IsOptional()
  @IsString()
  barcode?: string;

  @ApiPropertyOptional({ example: { size: 'M', color: 'Red' } })
  @IsOptional()
  specifications?: any;

  @ApiPropertyOptional({ example: true, default: true })
  @IsOptional()
  isAvailable?: boolean;
}
