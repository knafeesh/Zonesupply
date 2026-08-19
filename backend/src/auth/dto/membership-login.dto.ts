import { IsString, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class MembershipLoginDto {
  @ApiProperty({ example: 'ZS100002' })
  @IsString()
  membershipId: string;

  @ApiProperty({ example: '8168051355' })
  @IsString()
  mobile: string;

  @ApiPropertyOptional({ example: 'MOHAMMAD NAFEESH' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: 'knafeesh2@gmail.com' })
  @IsOptional()
  @IsString()
  email?: string;

  @ApiPropertyOptional({ example: 'clothes shop' })
  @IsOptional()
  @IsString()
  shopName?: string;
}
