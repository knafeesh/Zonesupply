import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags, ApiOperation, ApiParam, ApiBody } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { SellerLedgerService } from './seller-ledger.service';

@ApiTags('Seller Ledger')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('seller-ledger')
export class SellerLedgerController {
  constructor(private readonly sellerLedgerService: SellerLedgerService) {}

  // ─── Wholesaler Endpoints ──────────────────────────────────────────────────

  @Get('my/summary')
  @Roles(UserRole.WHOLESALER)
  @ApiOperation({ summary: 'Get wholesaler payment summary & settlement KPI metrics' })
  async getMySummary(@Req() req: any) {
    const wholesalerId = await this.sellerLedgerService.resolveWholesalerId(req.user);
    return this.sellerLedgerService.getSellerSummary(wholesalerId);
  }

  @Get('my')
  @Roles(UserRole.WHOLESALER)
  @ApiOperation({ summary: 'Get my ledger entries (sales, commissions, refunds, settlements)' })
  async getMyEntries(@Req() req: any) {
    const wholesalerId = await this.sellerLedgerService.resolveWholesalerId(req.user);
    return this.sellerLedgerService.getEntries(wholesalerId);
  }

  @Get('my/balance')
  @Roles(UserRole.WHOLESALER)
  @ApiOperation({ summary: 'Get my pending settlement balance' })
  async getMyBalance(@Req() req: any) {
    const wholesalerId = await this.sellerLedgerService.resolveWholesalerId(req.user);
    return this.sellerLedgerService.getPendingBalance(wholesalerId);
  }

  @Get('my/settlements')
  @Roles(UserRole.WHOLESALER)
  @ApiOperation({ summary: 'Get my settlement history with UTR references' })
  async getMySettlements(@Req() req: any) {
    const wholesalerId = await this.sellerLedgerService.resolveWholesalerId(req.user);
    return this.sellerLedgerService.getSettlements(wholesalerId);
  }

  @Get('my/payment-account')
  @Roles(UserRole.WHOLESALER)
  @ApiOperation({ summary: 'Get my registered payout / bank account details' })
  async getMyPaymentAccount(@Req() req: any) {
    const wholesalerId = await this.sellerLedgerService.resolveWholesalerId(req.user);
    return this.sellerLedgerService.getPaymentAccount(wholesalerId);
  }

  @Patch('my/payment-account')
  @Roles(UserRole.WHOLESALER)
  @ApiOperation({ summary: 'Update payout account (bank / IFSC / UPI VPA)' })
  async updateMyPaymentAccount(
    @Req() req: any,
    @Body()
    body: {
      beneficiaryName?: string;
      accountNumber?: string;
      ifscCode?: string;
      bankName?: string;
      vpaId?: string;
    },
  ) {
    const wholesalerId = await this.sellerLedgerService.resolveWholesalerId(req.user);
    return this.sellerLedgerService.updatePaymentAccount(wholesalerId, body);
  }

  // ─── Admin Endpoints ───────────────────────────────────────────────────────

  @Get('admin/balances')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: view all wholesaler balances & settlement queues' })
  async getAllPendingBalances() {
    return this.sellerLedgerService.getAllPendingBalances();
  }

  @Get('admin/entries/:wholesalerId')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: view ledger entries for a wholesaler' })
  @ApiParam({ name: 'wholesalerId', description: 'Wholesaler UUID' })
  async getEntriesAdmin(@Param('wholesalerId') wholesalerId: string) {
    return this.sellerLedgerService.getEntries(wholesalerId);
  }

  @Get('admin/settlements/:wholesalerId')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: view settlement history for a wholesaler' })
  @ApiParam({ name: 'wholesalerId', description: 'Wholesaler UUID' })
  async getSettlementsAdmin(@Param('wholesalerId') wholesalerId: string) {
    return this.sellerLedgerService.getSettlements(wholesalerId);
  }

  @Post('admin/settle/:wholesalerId')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: trigger payout settlement for a wholesaler' })
  @ApiParam({ name: 'wholesalerId', description: 'Wholesaler UUID' })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        paymentReference: { type: 'string', example: 'UTR20260818123456' },
        note: { type: 'string', example: 'Weekly payout batch' },
      },
    },
  })
  async triggerSettlement(
    @Param('wholesalerId') wholesalerId: string,
    @Body() body: { paymentReference?: string; note?: string },
  ) {
    return this.sellerLedgerService.triggerSettlement(
      wholesalerId,
      body.paymentReference,
      body.note,
    );
  }

  @Post('admin/adjustment/:wholesalerId')
  @Roles(UserRole.ADMIN)
  @ApiOperation({ summary: 'Admin: record credit or debit adjustment on seller ledger' })
  async recordAdjustment(
    @Param('wholesalerId') wholesalerId: string,
    @Body() body: { amount: number; isCredit: boolean; note: string },
  ) {
    return this.sellerLedgerService.recordAdjustment(
      wholesalerId,
      body.amount,
      body.isCredit,
      body.note,
    );
  }
}
