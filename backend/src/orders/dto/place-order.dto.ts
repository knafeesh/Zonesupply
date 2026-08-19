import {
  IsArray,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class OrderItemDto {
  @ApiProperty({ example: 'product-uuid-1' })
  @IsString()
  @IsNotEmpty()
  productId: string;

  @ApiProperty({ example: 10 })
  @IsNumber()
  quantity: number;
}

export class PlaceOrderDto {
  @ApiProperty({ type: [OrderItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items: OrderItemDto[];

  @ApiProperty({ example: '123 Main Street, Bangalore' })
  @IsString()
  @IsNotEmpty()
  deliveryAddress: string;

  @ApiProperty({ example: 'South Bangalore Hub', required: false })
  @IsString()
  @IsOptional()
  deliveryZone?: string;

  @ApiProperty({ example: 'pi_test_12345', required: false })
  @IsString()
  @IsOptional()
  paymentIntentId?: string;

  @ApiProperty({ example: 'UPI', required: false })
  @IsString()
  @IsOptional()
  paymentMethod?: string;
}
