import { IsString, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { UserRole } from '../../common/enums/user-role.enum';

export class GoogleAuthDto {
  @ApiProperty({ description: 'Google ID token from client SDK' })
  @IsString()
  idToken: string;

  @ApiProperty({ enum: UserRole, default: UserRole.RETAILER })
  @IsEnum(UserRole)
  role: UserRole;
}
