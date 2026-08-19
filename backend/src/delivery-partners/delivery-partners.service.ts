import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DeliveryPartner } from './delivery-partner.entity';
import { User } from '../users/user.entity';
import { DeliveryPartnerStatus } from '../common/enums/delivery-partner-status.enum';

@Injectable()
export class DeliveryPartnersService {
  constructor(
    @InjectRepository(DeliveryPartner)
    private readonly partnerRepo: Repository<DeliveryPartner>,
  ) {}

  async createDefault(user: User): Promise<DeliveryPartner> {
    const partner = this.partnerRepo.create({
      userId: user.id,
      vehicleType: 'two_wheeler',
      status: DeliveryPartnerStatus.OFFLINE,
    });
    return this.partnerRepo.save(partner);
  }

  async findByUserId(userId: string): Promise<DeliveryPartner> {
    const partner = await this.partnerRepo.findOne({
      where: { userId },
      relations: { user: true, currentZone: true },
    });
    if (!partner) {
      throw new NotFoundException(`Delivery Partner profile for user ${userId} not found`);
    }
    return partner;
  }

  async findOne(id: string): Promise<DeliveryPartner> {
    const partner = await this.partnerRepo.findOne({
      where: { id },
      relations: { user: true, currentZone: true },
    });
    if (!partner) {
      throw new NotFoundException(`Delivery Partner with ID ${id} not found`);
    }
    return partner;
  }

  async update(
    userId: string,
    dto: {
      vehicleType?: string;
      licenseNumber?: string;
      currentZoneId?: string;
      status?: DeliveryPartnerStatus;
    },
  ): Promise<DeliveryPartner> {
    const partner = await this.findByUserId(userId);
    Object.assign(partner, dto);
    return this.partnerRepo.save(partner);
  }

  async findAll(): Promise<DeliveryPartner[]> {
    return this.partnerRepo.find({ relations: { user: true, currentZone: true } });
  }

  async findAvailableInZone(zoneId: string): Promise<DeliveryPartner[]> {
    return this.partnerRepo.find({
      where: {
        currentZoneId: zoneId,
        status: DeliveryPartnerStatus.AVAILABLE,
      },
      relations: { user: true },
    });
  }
}
