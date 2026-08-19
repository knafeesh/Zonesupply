import { Controller, Get, Body, Req, UseGuards, Patch } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { RetailersService } from './retailers.service';

@ApiTags('Retailers')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('retailers')
export class RetailersController {
  constructor(private readonly retailersService: RetailersService) {}

  @Get('profile')
  @Roles(UserRole.RETAILER)
  getProfile(@Req() req: any) {
    return this.retailersService.findByUserId(req.user.id);
  }

  @Patch('profile')
  @Roles(UserRole.RETAILER)
  updateProfile(
    @Req() req: any,
    @Body()
    dto: {
      name?: string;
      phone?: string;
      profilePicture?: string;
      shopName?: string;
      gstNumber?: string;
      address?: string;
      latitude?: number;
      longitude?: number;
      zoneId?: string;
    },
  ) {
    return this.retailersService.updateProfile(req.user.id, dto);
  }
}
