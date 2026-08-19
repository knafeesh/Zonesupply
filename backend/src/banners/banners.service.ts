import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Banner } from './banner.entity';
import { CreateBannerDto } from './dto/create-banner.dto';
import { UpdateBannerDto } from './dto/update-banner.dto';
import { WholesalersService } from '../wholesalers/wholesalers.service';

@Injectable()
export class BannersService {
  constructor(
    @InjectRepository(Banner)
    private readonly bannerRepo: Repository<Banner>,
    private readonly wholesalersService: WholesalersService,
  ) {}

  async findAll(category?: string, wholesalerId?: string): Promise<Banner[]> {
    const query = this.bannerRepo.createQueryBuilder('banner')
      .leftJoinAndSelect('banner.wholesaler', 'wholesaler')
      .leftJoinAndSelect('wholesaler.user', 'user')
      .where('banner.isActive = :isActive', { isActive: true });

    if (category && category.trim().length > 0) {
      query.andWhere('LOWER(banner.category) = LOWER(:category)', { category: category.trim() });
    }

    if (wholesalerId) {
      query.andWhere('banner.wholesalerId = :wholesalerId', { wholesalerId });
    }

    query.orderBy('banner.displayOrder', 'ASC')
         .addOrderBy('banner.createdAt', 'DESC');

    return query.getMany();
  }

  async findMyBanners(userId: string): Promise<Banner[]> {
    const wholesaler = await this.wholesalersService.findByUserId(userId);
    return this.bannerRepo.find({
      where: { wholesalerId: wholesaler.id },
      order: { createdAt: 'DESC' },
      relations: { wholesaler: { user: true } },
    });
  }

  async findOne(id: string): Promise<Banner> {
    const banner = await this.bannerRepo.findOne({
      where: { id },
      relations: { wholesaler: { user: true } },
    });
    if (!banner) {
      throw new NotFoundException('Banner not found');
    }
    return banner;
  }

  async create(dto: CreateBannerDto, userId: string): Promise<Banner> {
    const wholesaler = await this.wholesalersService.findByUserId(userId);
    const banner = this.bannerRepo.create({
      ...dto,
      wholesalerId: wholesaler.id,
    });
    return this.bannerRepo.save(banner);
  }

  async update(id: string, dto: UpdateBannerDto, userId: string): Promise<Banner> {
    const wholesaler = await this.wholesalersService.findByUserId(userId);
    const banner = await this.findOne(id);

    if (banner.wholesalerId !== wholesaler.id) {
      throw new ForbiddenException('You do not have permission to update this banner');
    }

    Object.assign(banner, dto);
    return this.bannerRepo.save(banner);
  }

  async toggleActive(id: string, userId: string): Promise<Banner> {
    const wholesaler = await this.wholesalersService.findByUserId(userId);
    const banner = await this.findOne(id);

    if (banner.wholesalerId !== wholesaler.id) {
      throw new ForbiddenException('You do not have permission to modify this banner');
    }

    banner.isActive = !banner.isActive;
    return this.bannerRepo.save(banner);
  }

  async delete(id: string, userId: string): Promise<void> {
    const wholesaler = await this.wholesalersService.findByUserId(userId);
    const banner = await this.findOne(id);

    if (banner.wholesalerId !== wholesaler.id) {
      throw new ForbiddenException('You do not have permission to delete this banner');
    }

    await this.bannerRepo.remove(banner);
  }
}
