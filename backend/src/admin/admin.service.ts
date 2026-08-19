import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/user.entity';
import { Wholesaler, SettlementCycle } from '../wholesalers/wholesaler.entity';
import { Retailer } from '../retailers/retailer.entity';
import { Product } from '../products/product.entity';
import { Order } from '../orders/order.entity';
import { UserRole } from '../common/enums/user-role.enum';
import { OrderStatus } from '../common/enums/order-status.enum';
import { PaymentTransaction, PaymentTransactionStatus } from '../payment/entities/payment-transaction.entity';
import { Refund } from '../payment/entities/refund.entity';
import { Settlement } from '../seller-ledger/settlement.entity';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    @InjectRepository(Wholesaler)
    private readonly wholesalerRepo: Repository<Wholesaler>,
    @InjectRepository(Retailer)
    private readonly retailerRepo: Repository<Retailer>,
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    @InjectRepository(PaymentTransaction)
    private readonly txRepo: Repository<PaymentTransaction>,
    @InjectRepository(Refund)
    private readonly refundRepo: Repository<Refund>,
    @InjectRepository(Settlement)
    private readonly settlementRepo: Repository<Settlement>,
  ) {}

  async getPlatformStats(): Promise<any> {
    const [
      totalSellers,
      totalRetailers,
      totalProducts,
      orders,
      transactions,
      refunds,
      settlements,
    ] = await Promise.all([
      this.wholesalerRepo.count(),
      this.retailerRepo.count(),
      this.productRepo.count(),
      this.orderRepo.find({ order: { createdAt: 'DESC' } }),
      this.txRepo.find(),
      this.refundRepo.find(),
      this.settlementRepo.find(),
    ]);

    let totalGmv = 0;
    let pendingOrders = 0;
    let deliveredOrders = 0;
    let totalPlatformCommission = 0;

    orders.forEach((order) => {
      const amount = Number(order.totalAmount) || 0;
      const comm = Number(order.commissionAmount) || 0;
      if (order.status !== OrderStatus.CANCELLED) {
        totalGmv += amount;
        totalPlatformCommission += comm;
      }
      if (order.status === OrderStatus.PENDING) {
        pendingOrders++;
      }
      if (
        order.status === OrderStatus.DELIVERED ||
        order.status === OrderStatus.SETTLEMENT_ELIGIBLE
      ) {
        deliveredOrders++;
      }
    });

    const totalCollections = transactions
      .filter((t) => t.status === PaymentTransactionStatus.SUCCESS)
      .reduce((sum, t) => sum + Number(t.amount || 0), 0);

    const totalRefundedAmount = refunds.reduce(
      (sum, r) => sum + Number(r.amount || 0),
      0,
    );

    const totalSettledAmount = settlements.reduce(
      (sum, s) => sum + Number(s.totalNet || 0),
      0,
    );

    // Monthly volume calculation (last 6 months)
    const monthlyStats: { month: string; gmv: number; orders: number }[] = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date();
      d.setMonth(d.getMonth() - i);
      const year = d.getFullYear();
      const month = d.getMonth();
      const monthStart = new Date(year, month, 1);
      const monthEnd = new Date(year, month + 1, 0, 23, 59, 59, 999);
      const label = monthStart.toLocaleDateString('en-US', {
        month: 'short',
        year: 'numeric',
      });

      let monthGmv = 0;
      let monthOrderCount = 0;

      orders.forEach((order) => {
        const orderDate = new Date(order.createdAt);
        if (
          orderDate >= monthStart &&
          orderDate <= monthEnd &&
          order.status !== OrderStatus.CANCELLED
        ) {
          monthGmv += Number(order.totalAmount) || 0;
          monthOrderCount++;
        }
      });

      monthlyStats.push({
        month: label,
        gmv: Math.round(monthGmv * 100) / 100,
        orders: monthOrderCount,
      });
    }

    return {
      totalSellers,
      totalRetailers,
      totalProducts,
      totalOrders: orders.length,
      totalGmv: Math.round(totalGmv * 100) / 100,
      totalCollections: Math.round(totalCollections * 100) / 100,
      totalPlatformCommission: Math.round(totalPlatformCommission * 100) / 100,
      totalRefundedAmount: Math.round(totalRefundedAmount * 100) / 100,
      totalSettledAmount: Math.round(totalSettledAmount * 100) / 100,
      pendingOrders,
      deliveredOrders,
      monthlyStats,
      recentOrders: orders.slice(0, 10),
    };
  }

  async getAllSellers(): Promise<any[]> {
    const wholesalers = await this.wholesalerRepo.find({
      relations: { user: true, zone: true, paymentAccount: true },
      order: { createdAt: 'DESC' },
    });

    return Promise.all(
      wholesalers.map(async (w) => {
        const [productCount, orderCount] = await Promise.all([
          this.productRepo.count({ where: { wholesalerId: w.id } }),
          this.orderRepo.count({ where: { wholesalerId: w.id } }),
        ]);

        return {
          ...w,
          commissionRate: Number(w.commissionRate) || 5.0,
          settlementCycle: w.settlementCycle || SettlementCycle.T_2,
          productCount,
          orderCount,
        };
      }),
    );
  }

  async updateSellerCommission(
    sellerId: string,
    commissionRate: number,
  ): Promise<Wholesaler> {
    const wholesaler = await this.wholesalerRepo.findOne({ where: { id: sellerId } });
    if (!wholesaler) {
      throw new NotFoundException(`Seller ${sellerId} not found`);
    }
    if (commissionRate < 0 || commissionRate > 100) {
      throw new BadRequestException('Commission rate must be between 0 and 100%');
    }
    wholesaler.commissionRate = Number(commissionRate);
    return this.wholesalerRepo.save(wholesaler);
  }

  async updateSettlementCycle(
    sellerId: string,
    settlementCycle: SettlementCycle,
  ): Promise<Wholesaler> {
    const wholesaler = await this.wholesalerRepo.findOne({ where: { id: sellerId } });
    if (!wholesaler) {
      throw new NotFoundException(`Seller ${sellerId} not found`);
    }
    wholesaler.settlementCycle = settlementCycle;
    return this.wholesalerRepo.save(wholesaler);
  }

  async toggleSellerStatus(sellerId: string): Promise<any> {
    const wholesaler = await this.wholesalerRepo.findOne({
      where: { id: sellerId },
      relations: { user: true },
    });
    if (!wholesaler || !wholesaler.user) {
      throw new NotFoundException(`Seller with ID ${sellerId} not found`);
    }

    wholesaler.user.isActive = !wholesaler.user.isActive;
    await this.userRepo.save(wholesaler.user);

    return {
      sellerId: wholesaler.id,
      userId: wholesaler.user.id,
      isActive: wholesaler.user.isActive,
      message: `Seller account is now ${wholesaler.user.isActive ? 'Active' : 'Suspended'}`,
    };
  }

  async getAllProducts(): Promise<Product[]> {
    return this.productRepo.find({
      relations: { wholesaler: { user: true } },
      order: { createdAt: 'DESC' },
    });
  }

  async getAllOrders(): Promise<Order[]> {
    return this.orderRepo.find({
      relations: {
        wholesaler: true,
        retailer: true,
        items: { product: true },
        childOrders: { wholesaler: true, items: { product: true } },
      },
      order: { createdAt: 'DESC' },
    });
  }
}
