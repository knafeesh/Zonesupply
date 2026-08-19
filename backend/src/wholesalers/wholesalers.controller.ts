import { Controller, Get, Body, Req, UseGuards, Patch, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { WholesalersService } from './wholesalers.service';
import { UpdateWholesalerProfileDto } from './dto/update-profile.dto';

@ApiTags('Wholesalers')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('wholesalers')
export class WholesalersController {
  constructor(private readonly wholesalersService: WholesalersService) {}

  @Get()
  @ApiQuery({ name: 'category', required: false, type: String })
  findAll(@Query('category') category?: string) {
    return this.wholesalersService.findAll(category);
  }

  @Get('analytics/overview')
  @Roles(UserRole.WHOLESALER, UserRole.ADMIN)
  getAnalytics(@Req() req: any) {
    return this.wholesalersService.getAnalytics(req.user.id);
  }

  @Get('profile')
  @Roles(UserRole.WHOLESALER)
  getProfile(@Req() req: any) {
    return this.wholesalersService.findProfileByUserId(req.user.id);
  }

  @Patch('profile')
  @Roles(UserRole.WHOLESALER)
  updateProfile(
    @Req() req: any,
    @Body() dto: UpdateWholesalerProfileDto,
  ) {
    return this.wholesalersService.updateProfile(req.user.id, dto);
  }

  @Get('favorites/my')
  getFavorites(@Req() req: any) {
    return this.wholesalersService.getFavorites(req.user.id);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.wholesalersService.findOne(id);
  }

  @Post(':id/favorite')
  toggleFavorite(@Param('id') id: string, @Req() req: any) {
    return this.wholesalersService.toggleFavorite(req.user.id, id);
  }
}
