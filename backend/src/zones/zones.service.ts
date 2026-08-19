import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Zone } from './zone.entity';

@Injectable()
export class ZonesService {
  constructor(
    @InjectRepository(Zone)
    private readonly zoneRepo: Repository<Zone>,
  ) {}

  async create(dto: {
    name: string;
    city: string;
    pincode: string;
    centerLat: number;
    centerLng: number;
    radiusKm: number;
  }): Promise<Zone> {
    const zone = this.zoneRepo.create(dto);
    return this.zoneRepo.save(zone);
  }

  async findAll(): Promise<Zone[]> {
    return this.zoneRepo.find();
  }

  async findOne(id: string): Promise<Zone> {
    const zone = await this.zoneRepo.findOneBy({ id });
    if (!zone) {
      throw new NotFoundException(`Zone with ID ${id} not found`);
    }
    return zone;
  }
}
