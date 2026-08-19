import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConsolidationService } from '../consolidation/consolidation.service';
import { ConsolidationBatch } from '../consolidation/consolidation-batch.entity';
import { DeliveryTracking } from './delivery-tracking.entity';
import { DeliveryPartnersService } from '../delivery-partners/delivery-partners.service';
import { BatchOrder } from '../consolidation/batch-order.entity';

@Injectable()
export class DeliveryService {
  constructor(
    private readonly consolidationService: ConsolidationService,
    private readonly partnersService: DeliveryPartnersService,
    @InjectRepository(DeliveryTracking)
    private readonly trackingRepo: Repository<DeliveryTracking>,
  ) {}

  async getAvailableJobs(): Promise<ConsolidationBatch[]> {
    return this.consolidationService.findAvailableJobs();
  }

  async claimJob(batchId: string, agentUserId: string): Promise<ConsolidationBatch> {
    return this.consolidationService.claimJob(batchId, agentUserId);
  }

  async getMyJobs(agentUserId: string): Promise<ConsolidationBatch[]> {
    return this.consolidationService.findMyJobs(agentUserId);
  }

  async markPickedUp(batchId: string): Promise<ConsolidationBatch> {
    return this.consolidationService.markPickedUp(batchId);
  }

  async markInTransit(batchId: string): Promise<ConsolidationBatch> {
    return this.consolidationService.markInTransit(batchId);
  }

  async confirmPOD(
    batchId: string,
    orderId: string,
    partnerUserId: string,
    coords: { lat: number; lng: number },
    status: 'delivered' | 'failed',
    otp?: string,
  ): Promise<BatchOrder> {
    return this.consolidationService.confirmPOD(batchId, orderId, partnerUserId, coords, status, otp);
  }

  async updateLocation(
    userId: string,
    latitude: number,
    longitude: number,
    batchId?: string,
  ): Promise<DeliveryTracking> {
    const partner = await this.partnersService.findByUserId(userId);
    const tracking = this.trackingRepo.create({
      deliveryPartnerId: partner.id,
      batchId,
      latitude,
      longitude,
    });
    return this.trackingRepo.save(tracking);
  }
}
