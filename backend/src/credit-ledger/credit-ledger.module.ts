import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CreditLedger } from './credit-ledger.entity';
import { LedgerTransaction } from './ledger-transaction.entity';
import { CreditLedgerService } from './credit-ledger.service';
import { CreditLedgerController } from './credit-ledger.controller';

@Module({
  imports: [TypeOrmModule.forFeature([CreditLedger, LedgerTransaction])],
  providers: [CreditLedgerService],
  controllers: [CreditLedgerController],
  exports: [CreditLedgerService, TypeOrmModule],
})
export class CreditLedgerModule {}
