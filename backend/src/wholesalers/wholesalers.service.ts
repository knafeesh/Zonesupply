import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { Wholesaler } from './wholesaler.entity';
import { User } from '../users/user.entity';
import { Retailer } from '../retailers/retailer.entity';
import { FavoriteWholesaler } from './favorite-wholesaler.entity';
import { Product } from '../products/product.entity';
import { Order } from '../orders/order.entity';
import { OrderStatus } from '../common/enums/order-status.enum';

@Injectable()
export class WholesalersService {
  constructor(
    @InjectRepository(Wholesaler)
    private readonly wholesalerRepo: Repository<Wholesaler>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(Retailer)
    private readonly retailerRepo: Repository<Retailer>,
    @InjectRepository(FavoriteWholesaler)
    private readonly favoriteRepo: Repository<FavoriteWholesaler>,
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
  ) {}

  async createProfile(
    user: User,
    initialData?: {
      businessName?: string;
      gstNumber?: string;
      panNumber?: string;
      address?: string;
      shopNumber?: string;
      latitude?: number;
      longitude?: number;
    },
  ): Promise<Wholesaler> {
    const wholesaler = this.wholesalerRepo.create({
      userId: user.id,
      businessName: initialData?.businessName?.trim() || `${user.name}'s Wholesale`,
      gstNumber: initialData?.gstNumber?.trim() || undefined,
      panNumber: initialData?.panNumber?.trim() || undefined,
      address: initialData?.address?.trim() || undefined,
      shopNumber: initialData?.shopNumber?.trim() || undefined,
      latitude: initialData?.latitude ?? 0,
      longitude: initialData?.longitude ?? 0,
    });
    return this.wholesalerRepo.save(wholesaler);
  }

  async createDefault(
    user: User,
    initialData?: {
      businessName?: string;
      gstNumber?: string;
      panNumber?: string;
      address?: string;
      shopNumber?: string;
      latitude?: number;
      longitude?: number;
    },
  ): Promise<Wholesaler> {
    return this.createProfile(user, initialData);
  }

  async findByUserId(userId: string): Promise<Wholesaler> {
    let wholesaler = await this.wholesalerRepo.findOne({
      where: { userId },
      relations: { user: true, zone: true },
    });
    if (!wholesaler) {
      const user = await this.userRepo.findOne({ where: { id: userId } });
      if (user) {
        wholesaler = await this.createProfile(user);
        return (await this.wholesalerRepo.findOne({
          where: { id: wholesaler.id },
          relations: { user: true, zone: true },
        })) || wholesaler;
      }
      throw new NotFoundException(`Wholesaler profile for user ${userId} not found`);
    }
    return wholesaler;
  }

  async findProfileByUserId(userId: string): Promise<any> {
    return this.findByUserId(userId);
  }

  async findOne(id: string): Promise<Wholesaler> {
    const wholesaler = await this.wholesalerRepo.findOne({
      where: { id },
      relations: { user: true, zone: true },
    });
    if (!wholesaler) {
      throw new NotFoundException(`Wholesaler with ID ${id} not found`);
    }
    return wholesaler;
  }

  async update(
    userId: string,
    dto: {
      businessName?: string;
      gstNumber?: string;
      address?: string;
      latitude?: number;
      longitude?: number;
      zoneId?: string;
    },
  ): Promise<Wholesaler> {
    const wholesaler = await this.findByUserId(userId);
    Object.assign(wholesaler, dto);
    return this.wholesalerRepo.save(wholesaler);
  }

  async updateProfile(
    userId: string,
    dto: {
      name?: string;
      email?: string;
      phone?: string;
      profilePicture?: string;
      businessName?: string;
      gstNumber?: string;
      panNumber?: string;
      address?: string;
      shopNumber?: string;
      latitude?: number;
      longitude?: number;
      zoneId?: string;
    },
  ): Promise<any> {
    const wholesaler = await this.findByUserId(userId);

    // Save user fields if provided
    if (dto.name !== undefined || dto.phone !== undefined || dto.email !== undefined || dto.profilePicture !== undefined) {
      const user = wholesaler.user;
      if (dto.name !== undefined && dto.name.trim().length > 0) user.name = dto.name.trim();
      if (dto.phone !== undefined) user.phone = dto.phone.trim();
      if (dto.email !== undefined && dto.email.trim().length > 0) user.email = dto.email.trim();
      if (dto.profilePicture !== undefined) user.profilePicture = dto.profilePicture;
      await this.userRepo.save(user);
    }

    // Save wholesaler fields if provided
    if (dto.businessName !== undefined && dto.businessName.trim().length > 0) wholesaler.businessName = dto.businessName.trim();
    if (dto.gstNumber !== undefined) wholesaler.gstNumber = dto.gstNumber.trim();
    if (dto.panNumber !== undefined) wholesaler.panNumber = dto.panNumber.trim();
    if (dto.address !== undefined) wholesaler.address = dto.address.trim();
    if (dto.shopNumber !== undefined) wholesaler.shopNumber = dto.shopNumber.trim();
    if (dto.latitude !== undefined) wholesaler.latitude = dto.latitude;
    if (dto.longitude !== undefined) wholesaler.longitude = dto.longitude;
    if (dto.zoneId !== undefined) wholesaler.zoneId = dto.zoneId;

    await this.wholesalerRepo.save(wholesaler);

    return this.findProfileByUserId(userId);
  }

  async toggleFavorite(retailerUserId: string, wholesalerId: string): Promise<{ favorited: boolean }> {
    const retailer = await this.retailerRepo.findOne({ where: { userId: retailerUserId } });
    if (!retailer) {
      throw new NotFoundException('Retailer profile not found');
    }

    const fav = await this.favoriteRepo.findOne({
      where: { retailerId: retailer.id, wholesalerId },
    });

    if (fav) {
      await this.favoriteRepo.remove(fav);
      return { favorited: false };
    }

    const newFav = this.favoriteRepo.create({
      retailerId: retailer.id,
      wholesalerId,
    });
    await this.favoriteRepo.save(newFav);
    return { favorited: true };
  }

  async getFavorites(retailerUserId: string): Promise<Wholesaler[]> {
    const retailer = await this.retailerRepo.findOne({ where: { userId: retailerUserId } });
    if (!retailer) {
      throw new NotFoundException('Retailer profile not found');
    }

    const favs = await this.favoriteRepo.find({
      where: { retailerId: retailer.id },
      relations: { wholesaler: { user: true, zone: true } },
    });
    return favs.map(f => f.wholesaler);
  }

  async isFavorited(retailerUserId: string, wholesalerId: string): Promise<boolean> {
    const retailer = await this.retailerRepo.findOne({ where: { userId: retailerUserId } });
    if (!retailer) return false;

    const count = await this.favoriteRepo.count({
      where: { retailerId: retailer.id, wholesalerId },
    });
    return count > 0;
  }

  async findAll(category?: string): Promise<any[]> {
    const wholesalers = await this.wholesalerRepo.find({
      relations: { user: true, zone: true },
      order: { createdAt: 'DESC' },
    });

    const enriched = await Promise.all(
      wholesalers.map(async (w) => {
        const products = await this.productRepo.find({
          where: { wholesalerId: w.id, isAvailable: true },
          select: { category: true },
        });

        const productCount = products.length;
        const categories = Array.from(
          new Set(
            products
              .map((p) => p.category?.trim())
              .filter((c): c is string => Boolean(c && c.length > 0)),
          ),
        );

        return {
          ...w,
          productCount,
          categories,
        };
      }),
    );

    if (!category || category.trim().length === 0 || category.toLowerCase() === 'all') {
      return enriched;
    }

    const catLower = category.toLowerCase().trim();
    return enriched.filter((w) => {
      // 1. Check if wholesaler has products with this category
      const hasCatInProducts = w.categories.some((c: string) => {
        const cl = c.toLowerCase();
        return cl.includes(catLower) || catLower.includes(cl);
      });
      if (hasCatInProducts) return true;

      // 2. Check business name relevance
      const bName = (w.businessName || '').toLowerCase();
      if (catLower.includes('fashion')) {
        return bName.includes('textile') || bName.includes('garment') || bName.includes('fashion') || bName.includes('wear') || bName.includes('cloth') || bName.includes('apparel');
      } else if (catLower.includes('grocery') || catLower.includes('rice') || catLower.includes('atta') || catLower.includes('oil') || catLower.includes('grain')) {
        return bName.includes('grocery') || bName.includes('kirana') || bName.includes('mill') || bName.includes('food') || bName.includes('trader') || bName.includes('grain') || bName.includes('spice') || bName.includes('fmcg');
      } else if (catLower.includes('home') || catLower.includes('personal') || catLower.includes('care')) {
        return bName.includes('care') || bName.includes('hygiene') || bName.includes('clean') || bName.includes('chemical') || bName.includes('fmcg');
      } else if (catLower.includes('luggage') || catLower.includes('apparel') || catLower.includes('bag') || catLower.includes('accessories')) {
        return bName.includes('luggage') || bName.includes('bag') || bName.includes('leather') || bName.includes('accessory') || bName.includes('apparel') || bName.includes('trolley');
      } else if (catLower.includes('restaurant') || catLower.includes('houseware') || catLower.includes('cookware')) {
        return bName.includes('restaurant') || bName.includes('hotel') || bName.includes('cookware') || bName.includes('utensil') || bName.includes('crockery') || bName.includes('pack');
      } else if (catLower.includes('health') || catLower.includes('otc') || catLower.includes('medical')) {
        return bName.includes('pharma') || bName.includes('health') || bName.includes('medical') || bName.includes('ayurved') || bName.includes('wellness');
      } else if (catLower.includes('appliance') || catLower.includes('kitchen') || catLower.includes('electronic')) {
        return bName.includes('appliance') || bName.includes('electronic') || bName.includes('electrical') || bName.includes('kitchen');
      }

      return bName.includes(catLower);
    });
  }

  async findByZone(zoneId: string): Promise<Wholesaler[]> {
    return this.wholesalerRepo.find({
      where: { zoneId },
      relations: { user: true, zone: true },
    });
  }

  async getAnalytics(userId: string): Promise<any> {
    const wholesaler = await this.findByUserId(userId);
    const wholesalerId = wholesaler.id;

    const [products, orders] = await Promise.all([
      this.productRepo.find({ where: { wholesalerId } }),
      this.orderRepo.find({
        where: { wholesalerId },
        relations: { retailer: true, items: true },
        order: { createdAt: 'DESC' },
      }),
    ]);

    const totalProducts = products.length;
    const lowStockProducts = products.filter(p => Number(p.stockQuantity) > 0 && Number(p.stockQuantity) <= 10).length;
    const outOfStockProducts = products.filter(p => Number(p.stockQuantity) <= 0).length;

    let totalRevenue = 0;
    let todaySales = 0;
    let pendingOrders = 0;
    let activeOrders = 0;

    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    orders.forEach(order => {
      const amount = Number(order.totalAmount) || 0;
      if (order.status !== OrderStatus.CANCELLED) {
        totalRevenue += amount;
        if (new Date(order.createdAt) >= startOfToday) {
          todaySales += amount;
        }
      }
      if (order.status === OrderStatus.PENDING) {
        pendingOrders++;
      }
      if ([OrderStatus.PENDING, OrderStatus.CONFIRMED, OrderStatus.IN_TRANSIT].includes(order.status)) {
        activeOrders++;
      }
    });

    const dailyChart: { date: string; revenue: number; orders: number }[] = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dayStart = new Date(d.getFullYear(), d.getMonth(), d.getDate());
      const dayEnd = new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59, 999);
      const dateLabel = dayStart.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });

      let dayRev = 0;
      let dayOrderCount = 0;

      orders.forEach(order => {
        const orderDate = new Date(order.createdAt);
        if (orderDate >= dayStart && orderDate <= dayEnd && order.status !== OrderStatus.CANCELLED) {
          dayRev += Number(order.totalAmount) || 0;
          dayOrderCount++;
        }
      });

      dailyChart.push({
        date: dateLabel,
        revenue: Math.round(dayRev * 100) / 100,
        orders: dayOrderCount,
      });
    }

    return {
      wholesaler,
      stats: {
        totalRevenue: Math.round(totalRevenue * 100) / 100,
        todaySales: Math.round(todaySales * 100) / 100,
        totalOrders: orders.length,
        pendingOrders,
        activeOrders,
        totalProducts,
        lowStockProducts,
        outOfStockProducts,
      },
      dailyChart,
      recentOrders: orders.slice(0, 5),
    };
  }
}
