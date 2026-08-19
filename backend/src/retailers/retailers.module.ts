import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Retailer } from './retailer.entity';
import { RetailersService } from './retailers.service';
import { RetailersController } from './retailers.controller';
import { Zone } from '../zones/zone.entity';
import { User } from '../users/user.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Retailer, Zone, User])],
  controllers: [RetailersController],
  providers: [RetailersService],
  exports: [RetailersService, TypeOrmModule],
})
export class RetailersModule {}
