import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DeliveryPartner } from './delivery-partner.entity';
import { DeliveryPartnersService } from './delivery-partners.service';

@Module({
  imports: [TypeOrmModule.forFeature([DeliveryPartner])],
  providers: [DeliveryPartnersService],
  exports: [DeliveryPartnersService, TypeOrmModule],
})
export class DeliveryPartnersModule {}
