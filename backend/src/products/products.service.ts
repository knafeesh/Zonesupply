import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Inject } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { Product } from './product.entity';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { WholesalersService } from '../wholesalers/wholesalers.service';

@Injectable()
export class ProductsService {
  constructor(
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @Inject(CACHE_MANAGER) private cacheManager: any,
    private readonly wholesalersService: WholesalersService,
  ) {}

  async create(dto: CreateProductDto, userId: string): Promise<Product> {
    const wholesaler = await this.wholesalersService.findByUserId(userId);
    const product = this.productRepo.create({ ...dto, wholesalerId: wholesaler.id });
    if (!product.images) {
      product.images = [];
    }
    if (!product.imageUrl && product.images.length > 0) {
      product.imageUrl = product.images[0];
    }
    const saved = await this.productRepo.save(product);
    await this.cacheManager.del('products:all');
    return saved;
  }

  async findAll(): Promise<Product[]> {
    const cached = (await this.cacheManager.get('products:all')) as Product[];
    if (cached) return cached;

    const products = await this.productRepo.find({
      where: { isAvailable: true },
      order: { createdAt: 'DESC' },
      relations: { wholesaler: { user: true } },
    });
    await this.cacheManager.set('products:all', products, 300);
    return products;
  }

  async findByWholesaler(userId: string): Promise<Product[]> {
    const wholesaler = await this.wholesalersService.findByUserId(userId);
    return this.productRepo.find({
      where: { wholesalerId: wholesaler.id, isAvailable: true },
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Product> {
    const product = await this.productRepo.findOne({
      where: { id },
      relations: { wholesaler: { user: true } },
    });
    if (!product) throw new NotFoundException('Product not found');
    return product;
  }

  async updateStock(id: string, quantity: number, userId: string): Promise<Product> {
    const wholesaler = await this.wholesalersService.findByUserId(userId);
    const product = await this.findOne(id);
    if (product.wholesalerId !== wholesaler.id) {
      throw new ForbiddenException('Cannot update stock for another wholesaler\'s product');
    }
    product.stockQuantity = quantity;
    const saved = await this.productRepo.save(product);
    await this.cacheManager.del('products:all');
    return saved;
  }

  async update(id: string, dto: UpdateProductDto, userId: string): Promise<Product> {
    const wholesaler = await this.wholesalersService.findByUserId(userId);
    const product = await this.findOne(id);
    if (product.wholesalerId !== wholesaler.id) {
      throw new ForbiddenException('Cannot modify another wholesaler\'s product');
    }
    Object.assign(product, dto);
    if (!product.images) {
      product.images = [];
    }
    if (!product.imageUrl && product.images.length > 0) {
      product.imageUrl = product.images[0];
    }
    const saved = await this.productRepo.save(product);
    await this.cacheManager.del('products:all');
    return saved;
  }

  async remove(id: string, userId: string): Promise<void> {
    const wholesaler = await this.wholesalersService.findByUserId(userId);
    const product = await this.findOne(id);
    if (product.wholesalerId !== wholesaler.id) {
      throw new ForbiddenException('Cannot delete another wholesaler\'s product');
    }

    try {
      await this.productRepo.remove(product);
    } catch (err) {
      // If historical orders reference this product, soft-delete by deactivating
      product.isAvailable = false;
      await this.productRepo.save(product);
    }

    await this.cacheManager.del('products:all');
  }

  async findByWholesalerId(wholesalerId: string): Promise<Product[]> {
    return this.productRepo.find({
      where: { wholesalerId, isAvailable: true },
      order: { createdAt: 'DESC' },
      relations: { wholesaler: { user: true } },
    });
  }

  async findByBarcode(barcode: string): Promise<Product | null> {
    return this.productRepo.findOne({
      where: { barcode, isAvailable: true },
      relations: { wholesaler: { user: true } },
    });
  }
}
