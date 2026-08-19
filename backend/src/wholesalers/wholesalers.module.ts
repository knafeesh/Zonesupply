import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Wholesaler } from './wholesaler.entity';
import { User } from '../users/user.entity';
import { Retailer } from '../retailers/retailer.entity';
import { FavoriteWholesaler } from './favorite-wholesaler.entity';
import { Product } from '../products/product.entity';
import { Order } from '../orders/order.entity';
import { WholesalersService } from './wholesalers.service';
import { WholesalersController } from './wholesalers.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Wholesaler, User, Retailer, FavoriteWholesaler, Product, Order])],
  controllers: [WholesalersController],
  providers: [WholesalersService],
  exports: [WholesalersService, TypeOrmModule],
})
export class WholesalersModule {}
