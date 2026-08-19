import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConsolidationBatch } from './consolidation-batch.entity';
import { BatchOrder } from './batch-order.entity';
import { Order } from '../orders/order.entity';
import { ConsolidationService } from './consolidation.service';
import { ConsolidationController } from './consolidation.controller';
import { ConsolidationProcessor } from './consolidation.processor';
import { DeliveryPartnersModule } from '../delivery-partners/delivery-partners.module';
import { CreditLedgerModule } from '../credit-ledger/credit-ledger.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([ConsolidationBatch, BatchOrder, Order]),
    DeliveryPartnersModule,
    CreditLedgerModule,
    NotificationsModule,
  ],
  providers: [ConsolidationService, ConsolidationProcessor],
  controllers: [ConsolidationController],
  exports: [ConsolidationService, TypeOrmModule],
})
export class ConsolidationModule {}
