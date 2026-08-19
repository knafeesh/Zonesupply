import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { User } from './user.entity';
import { WholesalersModule } from '../wholesalers/wholesalers.module';
import { RetailersModule } from '../retailers/retailers.module';
import { DeliveryPartnersModule } from '../delivery-partners/delivery-partners.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([User]),
    WholesalersModule,
    RetailersModule,
    DeliveryPartnersModule,
  ],
  providers: [UsersService],
  controllers: [UsersController],
  exports: [UsersService],
})
export class UsersModule {}
