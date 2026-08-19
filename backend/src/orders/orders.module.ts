import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Order } from './order.entity';
import { OrderItem } from './order-item.entity';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { ProductsModule } from '../products/products.module';
import { ConsolidationModule } from '../consolidation/consolidation.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { RetailersModule } from '../retailers/retailers.module';
import { WholesalersModule } from '../wholesalers/wholesalers.module';
import { CreditLedgerModule } from '../credit-ledger/credit-ledger.module';
import { SellerLedgerModule } from '../seller-ledger/seller-ledger.module';
import { BullModule } from '@nestjs/bullmq';

@Module({
  imports: [
    TypeOrmModule.forFeature([Order, OrderItem]),
    ProductsModule,
    ConsolidationModule,
    NotificationsModule,
    RetailersModule,
    WholesalersModule,
    CreditLedgerModule,
    SellerLedgerModule,
    BullModule.registerQueue({ name: 'consolidation' }),
  ],
  providers: [OrdersService],
  controllers: [OrdersController],
  exports: [OrdersService, TypeOrmModule],
})
export class OrdersModule {}
