import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Req,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { UserRole } from '../common/enums/user-role.enum';
import { CreditLedgerService } from './credit-ledger.service';
import { InjectRepository } from '@nestjs/typeorm';
import { CreditLedger } from './credit-ledger.entity';
import { Repository } from 'typeorm';
import { LedgerTransactionType } from '../common/enums/ledger-transaction-type.enum';

@ApiTags('Credit Ledger')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('credit-ledger')
export class CreditLedgerController {
  constructor(
    private readonly ledgerService: CreditLedgerService,
    @InjectRepository(CreditLedger)
    private readonly ledgerRepo: Repository<CreditLedger>,
  ) {}

  @Get('retailer/outstanding')
  @Roles(UserRole.RETAILER)
  async getOutstanding(@Req() req: any) {
    // retailer is linked to user.id
    // We should first find the retailer profile ID
    // We will query Outstanding via user.id -> retailer.id
    // Wait, let's keep it simple: retailer will look up via retailer's user ID
    // We can fetch user id from request
    return this.ledgerService.getRetailerOutstanding(req.user.id);
  }

  @Get('wholesaler/outstanding')
  @Roles(UserRole.WHOLESALER)
  async getWholesalerOutstanding(@Req() req: any) {
    return this.ledgerService.getWholesalerOutstanding(req.user.id);
  }

  @Get('wholesaler/transactions')
  @Roles(UserRole.WHOLESALER)
  async getWholesalerTransactions(@Req() req: any) {
    return this.ledgerService.getWholesalerTransactions(req.user.id);
  }

  @Get(':ledgerId/transactions')
  async getTransactions(@Param('ledgerId') ledgerId: string, @Req() req: any) {
    return this.ledgerService.getLedgerTransactionsSecure(ledgerId, req.user);
  }

  @Post('limit')
  @Roles(UserRole.ADMIN)
  async updateLimit(
    @Body()
    dto: {
      retailerId: string;
      wholesalerId: string;
      limit: number;
    },
  ) {
    const ledger = await this.ledgerService.getOrCreateLedger(
      dto.retailerId,
      dto.wholesalerId,
      dto.limit,
    );
    ledger.creditLimit = dto.limit;
    return this.ledgerRepo.save(ledger);
  }

  @Post('transaction')
  @Roles(UserRole.WHOLESALER)
  async recordManualTransaction(
    @Req() req: any,
    @Body()
    dto: {
      retailerId: string;
      amount: number;
      type: LedgerTransactionType;
      note?: string;
    },
  ) {
    return this.ledgerService.recordManualTransaction(req.user.id, dto);
  }
}
