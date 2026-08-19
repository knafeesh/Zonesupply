import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DeliveryService } from './delivery.service';
import { DeliveryController } from './delivery.controller';
import { ConsolidationModule } from '../consolidation/consolidation.module';
import { DeliveryTracking } from './delivery-tracking.entity';
import { DeliveryPartnersModule } from '../delivery-partners/delivery-partners.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([DeliveryTracking]),
    ConsolidationModule,
    DeliveryPartnersModule,
  ],
  providers: [DeliveryService],
  controllers: [DeliveryController],
  exports: [DeliveryService, TypeOrmModule],
})
export class DeliveryModule {}
