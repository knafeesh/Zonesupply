import { Controller, Get, Patch, Param, Body, UseGuards, Req, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { ConsolidationService } from './consolidation.service';

@ApiTags('Consolidation')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('consolidation')
export class ConsolidationController {
  constructor(private readonly consolidationService: ConsolidationService) {}

  @Get()
  @Roles(UserRole.WHOLESALER, UserRole.ADMIN)
  async findAll(@Req() req: any) {
    if (req.user.role === UserRole.WHOLESALER) {
      return this.consolidationService.findAll(req.user.id);
    }
    return this.consolidationService.findAll();
  }

  @Get('agents')
  @Roles(UserRole.WHOLESALER, UserRole.ADMIN)
  getAgents() {
    return this.consolidationService.getDeliveryAgents();
  }

  @Get('open')
  @Roles(UserRole.WHOLESALER, UserRole.DELIVERY)
  findOpen(@Req() req: any) {
    if (req.user.role === UserRole.WHOLESALER) {
      return this.consolidationService.findOpenBatches(req.user.id);
    }
    return this.consolidationService.findOpenBatches();
  }

  @Post('create')
  @Roles(UserRole.WHOLESALER)
  async createBatchManual(@Req() req: any, @Body('zoneId') zoneId: string) {
    return this.consolidationService.processOrderPoolingManualByUserId(zoneId, req.user.id);
  }

  @Post('merge')
  @Roles(UserRole.WHOLESALER)
  async mergeOrders(@Req() req: any, @Body('orderIds') orderIds: string[]) {
    return this.consolidationService.mergeOrdersIntoBatch(req.user.id, orderIds);
  }

  @Get(':id')
  @Roles(UserRole.WHOLESALER, UserRole.ADMIN, UserRole.DELIVERY)
  findOne(@Param('id') id: string, @Req() req: any) {
    return this.consolidationService.findOneSecure(id, req.user);
  }

  @Patch(':id/close')
  @Roles(UserRole.WHOLESALER)
  closeBatch(@Param('id') id: string, @Req() req: any) {
    return this.consolidationService.closeBatchSecure(id, req.user.id);
  }

  @Patch(':id/assign')
  @Roles(UserRole.WHOLESALER, UserRole.ADMIN)
  assignAgent(
    @Param('id') id: string,
    @Body('agentId') agentId: string,
    @Req() req: any,
  ) {
    return this.consolidationService.assignDeliveryAgentSecure(id, agentId, req.user);
  }
}
