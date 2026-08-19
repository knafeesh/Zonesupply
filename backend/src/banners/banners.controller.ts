import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Req,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { BannersService } from './banners.service';
import { CreateBannerDto } from './dto/create-banner.dto';
import { UpdateBannerDto } from './dto/update-banner.dto';

@ApiTags('Banners')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('banners')
export class BannersController {
  constructor(private readonly bannersService: BannersService) {}

  @Get()
  @ApiQuery({ name: 'category', required: false })
  @ApiQuery({ name: 'wholesalerId', required: false })
  findAll(
    @Query('category') category?: string,
    @Query('wholesalerId') wholesalerId?: string,
  ) {
    return this.bannersService.findAll(category, wholesalerId);
  }

  @Get('my')
  @Roles(UserRole.WHOLESALER)
  findMine(@Req() req: any) {
    return this.bannersService.findMyBanners(req.user.id);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.bannersService.findOne(id);
  }

  @Post()
  @Roles(UserRole.WHOLESALER)
  create(@Body() dto: CreateBannerDto, @Req() req: any) {
    return this.bannersService.create(dto, req.user.id);
  }

  @Patch(':id')
  @Roles(UserRole.WHOLESALER)
  update(
    @Param('id') id: string,
    @Body() dto: UpdateBannerDto,
    @Req() req: any,
  ) {
    return this.bannersService.update(id, dto, req.user.id);
  }

  @Patch(':id/toggle')
  @Roles(UserRole.WHOLESALER)
  toggleActive(@Param('id') id: string, @Req() req: any) {
    return this.bannersService.toggleActive(id, req.user.id);
  }

  @Delete(':id')
  @Roles(UserRole.WHOLESALER)
  @HttpCode(HttpStatus.NO_CONTENT)
  delete(@Param('id') id: string, @Req() req: any) {
    return this.bannersService.delete(id, req.user.id);
  }
}
