import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SellerLedgerEntry } from './seller-ledger-entry.entity';
import { Settlement } from './settlement.entity';
import { WholesalerPaymentAccount } from './wholesaler-payment-account.entity';
import { Wholesaler } from '../wholesalers/wholesaler.entity';
import { SellerLedgerService } from './seller-ledger.service';
import { SellerLedgerController } from './seller-ledger.controller';
import { PaymentModule } from '../payment/payment.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      SellerLedgerEntry,
      Settlement,
      WholesalerPaymentAccount,
      Wholesaler,
    ]),
    forwardRef(() => PaymentModule),
  ],
  providers: [SellerLedgerService],
  controllers: [SellerLedgerController],
  exports: [SellerLedgerService, TypeOrmModule],
})
export class SellerLedgerModule {}
