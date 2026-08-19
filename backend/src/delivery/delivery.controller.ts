import { Controller, Get, Patch, Post, Param, Body, UseGuards, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { DeliveryService } from './delivery.service';

@ApiTags('Delivery')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('delivery')
export class DeliveryController {
  constructor(private readonly deliveryService: DeliveryService) {}

  @Get('jobs/available')
  @Roles(UserRole.DELIVERY)
  getAvailableJobs() {
    return this.deliveryService.getAvailableJobs();
  }

  @Get('jobs/mine')
  @Roles(UserRole.DELIVERY)
  getMyJobs(@Req() req: any) {
    return this.deliveryService.getMyJobs(req.user.id);
  }

  @Patch('jobs/:batchId/claim')
  @Roles(UserRole.DELIVERY)
  claimJob(@Param('batchId') batchId: string, @Req() req: any) {
    return this.deliveryService.claimJob(batchId, req.user.id);
  }

  @Patch('batches/:batchId/pickup')
  @Roles(UserRole.DELIVERY)
  markPickedUp(@Param('batchId') batchId: string) {
    return this.deliveryService.markPickedUp(batchId);
  }

  @Patch('batches/:batchId/transit')
  @Roles(UserRole.DELIVERY)
  markInTransit(@Param('batchId') batchId: string) {
    return this.deliveryService.markInTransit(batchId);
  }

  @Post('batches/:batchId/orders/:orderId/delivered')
  @Roles(UserRole.DELIVERY)
  confirmPOD(
    @Param('batchId') batchId: string,
    @Param('orderId') orderId: string,
    @Body() dto: { lat: number; lng: number; status: 'delivered' | 'failed'; otp?: string },
    @Req() req: any,
  ) {
    return this.deliveryService.confirmPOD(
      batchId,
      orderId,
      req.user.id,
      { lat: dto.lat, lng: dto.lng },
      dto.status,
      dto.otp,
    );
  }

  @Post('location')
  @Roles(UserRole.DELIVERY)
  updateLocation(
    @Body() dto: { lat: number; lng: number; batchId?: string },
    @Req() req: any,
  ) {
    return this.deliveryService.updateLocation(req.user.id, dto.lat, dto.lng, dto.batchId);
  }
}
