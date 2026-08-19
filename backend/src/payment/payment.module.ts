import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PaymentService } from './payment.service';
import { PaymentController } from './payment.controller';
import { PaymentTransaction } from './entities/payment-transaction.entity';
import { WebhookEvent } from './entities/webhook-event.entity';
import { Refund } from './entities/refund.entity';
import { Order } from '../orders/order.entity';
import { Wholesaler } from '../wholesalers/wholesaler.entity';
import { OrdersModule } from '../orders/orders.module';
import { SellerLedgerModule } from '../seller-ledger/seller-ledger.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      PaymentTransaction,
      WebhookEvent,
      Refund,
      Order,
      Wholesaler,
    ]),
    forwardRef(() => OrdersModule),
    forwardRef(() => SellerLedgerModule),
  ],
  controllers: [PaymentController],
  providers: [PaymentService],
  exports: [PaymentService, TypeOrmModule],
})
export class PaymentModule {}
