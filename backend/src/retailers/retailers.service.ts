import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Retailer } from './retailer.entity';
import { User } from '../users/user.entity';
import { Zone } from '../zones/zone.entity';

@Injectable()
export class RetailersService {
  constructor(
    @InjectRepository(Retailer)
    private readonly retailerRepo: Repository<Retailer>,
    @InjectRepository(Zone)
    private readonly zoneRepo: Repository<Zone>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  async createDefault(user: User): Promise<Retailer> {
    // Auto-assign to first available zone so orders can be placed immediately
    const defaultZone = await this.zoneRepo.findOne({ where: {} });

    const retailer = this.retailerRepo.create({
      userId: user.id,
      shopName: `${user.name}'s Shop`,
      latitude: 0,
      longitude: 0,
      zoneId: defaultZone?.id ?? undefined,
    });
    return this.retailerRepo.save(retailer);
  }

  async findByUserId(userId: string): Promise<Retailer> {
    const retailer = await this.retailerRepo.findOne({
      where: { userId },
      relations: { user: true, zone: true },
    });
    if (!retailer) {
      throw new NotFoundException(`Retailer profile for user ${userId} not found`);
    }
    return retailer;
  }

  async findOne(id: string): Promise<Retailer> {
    const retailer = await this.retailerRepo.findOne({
      where: { id },
      relations: { user: true, zone: true },
    });
    if (!retailer) {
      throw new NotFoundException(`Retailer with ID ${id} not found`);
    }
    return retailer;
  }

  async update(
    userId: string,
    dto: {
      shopName?: string;
      gstNumber?: string;
      address?: string;
      latitude?: number;
      longitude?: number;
      zoneId?: string;
    },
  ): Promise<Retailer> {
    const retailer = await this.findByUserId(userId);
    Object.assign(retailer, dto);
    return this.retailerRepo.save(retailer);
  }

  async updateProfile(
    userId: string,
    dto: {
      name?: string;
      phone?: string;
      profilePicture?: string;
      shopName?: string;
      gstNumber?: string;
      address?: string;
      latitude?: number;
      longitude?: number;
      zoneId?: string;
    },
  ): Promise<any> {
    const retailer = await this.findByUserId(userId);

    // Save user fields if provided
    if (dto.name !== undefined || dto.phone !== undefined || dto.profilePicture !== undefined) {
      const user = retailer.user;
      if (dto.name !== undefined) user.name = dto.name;
      if (dto.phone !== undefined) user.phone = dto.phone;
      if (dto.profilePicture !== undefined) user.profilePicture = dto.profilePicture;
      await this.userRepo.save(user);
    }

    // Save retailer fields if provided
    if (dto.shopName !== undefined) retailer.shopName = dto.shopName;
    if (dto.gstNumber !== undefined) retailer.gstNumber = dto.gstNumber;
    if (dto.address !== undefined) retailer.address = dto.address;
    if (dto.latitude !== undefined) retailer.latitude = dto.latitude;
    if (dto.longitude !== undefined) retailer.longitude = dto.longitude;
    if (dto.zoneId !== undefined) retailer.zoneId = dto.zoneId;

    await this.retailerRepo.save(retailer);

    return this.findByUserId(userId);
  }

  async findAll(): Promise<Retailer[]> {
    return this.retailerRepo.find({ relations: { user: true, zone: true } });
  }

  async findByZone(zoneId: string): Promise<Retailer[]> {
    return this.retailerRepo.find({
      where: { zoneId },
      relations: { user: true, zone: true },
    });
  }
}
