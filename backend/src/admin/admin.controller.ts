import {
  Controller,
  Get,
  Patch,
  Param,
  Body,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { AdminService } from './admin.service';
import { SettlementCycle } from '../wholesalers/wholesaler.entity';

@ApiTags('Admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
@Controller('admin')
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('stats')
  @ApiOperation({ summary: 'Super Admin platform & financial statistics' })
  getStats() {
    return this.adminService.getPlatformStats();
  }

  @Get('sellers')
  @ApiOperation({ summary: 'List all registered sellers with payment & order counts' })
  getSellers() {
    return this.adminService.getAllSellers();
  }

  @Patch('sellers/:id/toggle-status')
  @ApiOperation({ summary: 'Toggle seller active/suspended status' })
  toggleSellerStatus(@Param('id') id: string) {
    return this.adminService.toggleSellerStatus(id);
  }

  @Patch('sellers/:id/commission')
  @ApiOperation({ summary: 'Update platform commission rate for a seller' })
  updateCommission(
    @Param('id') id: string,
    @Body('commissionRate') commissionRate: number,
  ) {
    return this.adminService.updateSellerCommission(id, commissionRate);
  }

  @Patch('sellers/:id/settlement-cycle')
  @ApiOperation({ summary: 'Update settlement cycle schedule for a seller' })
  updateSettlementCycle(
    @Param('id') id: string,
    @Body('settlementCycle') settlementCycle: SettlementCycle,
  ) {
    return this.adminService.updateSettlementCycle(id, settlementCycle);
  }

  @Get('products')
  @ApiOperation({ summary: 'List all products across all sellers' })
  getProducts() {
    return this.adminService.getAllProducts();
  }

  @Get('orders')
  @ApiOperation({ summary: 'List all marketplace parent and child orders' })
  getOrders() {
    return this.adminService.getAllOrders();
  }
}
