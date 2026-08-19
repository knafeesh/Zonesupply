import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminService } from './admin.service';
import { AdminController } from './admin.controller';
import { User } from '../users/user.entity';
import { Wholesaler } from '../wholesalers/wholesaler.entity';
import { Retailer } from '../retailers/retailer.entity';
import { Product } from '../products/product.entity';
import { Order } from '../orders/order.entity';
import { PaymentTransaction } from '../payment/entities/payment-transaction.entity';
import { Refund } from '../payment/entities/refund.entity';
import { Settlement } from '../seller-ledger/settlement.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      Wholesaler,
      Retailer,
      Product,
      Order,
      PaymentTransaction,
      Refund,
      Settlement,
    ]),
  ],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
