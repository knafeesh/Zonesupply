import {
  Controller,
  Post,
  Get,
  Patch,
  Param,
  Body,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation } from '@nestjs/swagger';
import { OrdersService } from './orders.service';
import { PlaceOrderDto } from './dto/place-order.dto';
import { OrderStatus } from '../common/enums/order-status.enum';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';

@ApiTags('Orders')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Post('checkout-summary')
  @Roles(UserRole.RETAILER)
  @ApiOperation({ summary: 'Calculate official checkout summary, discounts, delivery fee & taxes' })
  async getCheckoutSummary(
    @Body('items') items: { productId: string; quantity: number }[],
    @Req() req: any,
  ) {
    return this.ordersService.calculateCheckoutSummary(items, req.user?.id);
  }

  @Post()
  @Roles(UserRole.RETAILER)
  @ApiOperation({ summary: 'Place order for cart (atomic multi-wholesaler split)' })
  async placeOrder(@Body() dto: PlaceOrderDto, @Req() req: any) {
    return this.ordersService.placeOrder(dto, req.user.id);
  }

  @Get()
  @Roles(UserRole.RETAILER, UserRole.WHOLESALER, UserRole.ADMIN)
  @ApiOperation({ summary: 'Get orders (Retailer parent orders, Wholesaler sub-orders, or Admin all orders)' })
  async getOrders(@Req() req: any) {
    if (req.user.role === UserRole.ADMIN) {
      return this.ordersService.findAll();
    }
    if (req.user.role === UserRole.RETAILER) {
      return this.ordersService.findByRetailer(req.user.id);
    }
    return this.ordersService.findByWholesaler(req.user.id);
  }

  @Get('my')
  @Roles(UserRole.RETAILER, UserRole.WHOLESALER)
  @ApiOperation({ summary: 'Get my orders (Retailer parent orders or Wholesaler sub-orders)' })
  async getMyOrders(@Req() req: any) {
    if (req.user.role === UserRole.RETAILER) {
      return this.ordersService.findByRetailer(req.user.id);
    }
    return this.ordersService.findByWholesaler(req.user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get order by ID with tenant security check' })
  async getOrder(@Param('id') id: string, @Req() req: any) {
    return this.ordersService.findOneSecure(id, req.user);
  }

  @Get(':id/tracking')
  @ApiOperation({ summary: 'Get live tracking, batch status and agent location' })
  async getTracking(@Param('id') id: string, @Req() req: any) {
    return this.ordersService.getOrderTracking(id, req.user);
  }

  @Patch(':id/status')
  @Roles(UserRole.WHOLESALER, UserRole.ADMIN)
  @ApiOperation({ summary: 'Update order fulfillment status' })
  async updateStatus(
    @Param('id') id: string,
    @Body('status') status: OrderStatus,
    @Req() req: any,
  ) {
    const wholesalerUserId =
      req.user.role === UserRole.WHOLESALER ? req.user.id : undefined;
    return this.ordersService.updateStatus(id, status, wholesalerUserId);
  }
}
