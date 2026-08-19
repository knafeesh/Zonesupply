import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, IsNull } from 'typeorm';
import { InjectQueue } from '@nestjs/bullmq';
import { Queue } from 'bullmq';
import { Order, OrderPaymentStatus } from './order.entity';
import { OrderItem } from './order-item.entity';
import { OrderStatus } from '../common/enums/order-status.enum';
import { DeliveryTracking } from '../delivery/delivery-tracking.entity';
import { ConsolidationBatch } from '../consolidation/consolidation-batch.entity';
import { PlaceOrderDto } from './dto/place-order.dto';
import { ProductsService } from '../products/products.service';
import { NotificationsService } from '../notifications/notifications.service';
import { RetailersService } from '../retailers/retailers.service';
import { CreditLedgerService } from '../credit-ledger/credit-ledger.service';
import { Product } from '../products/product.entity';
import { WholesalersService } from '../wholesalers/wholesalers.service';
import { UserRole } from '../common/enums/user-role.enum';
import { SellerLedgerService } from '../seller-ledger/seller-ledger.service';

export interface CheckoutSummary {
  subtotal: number;
  discountAmount: number;
  deliveryFee: number;
  taxAmount: number;
  totalAmount: number;
  sellerBreakdown: {
    wholesalerId: string;
    businessName: string;
    itemCount: number;
    subtotal: number;
  }[];
}

@Injectable()
export class OrdersService {
  constructor(
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    @InjectRepository(OrderItem)
    private readonly itemRepo: Repository<OrderItem>,
    private readonly productsService: ProductsService,
    private readonly retailersService: RetailersService,
    private readonly creditLedgerService: CreditLedgerService,
    @InjectQueue('consolidation')
    private readonly consolidationQueue: Queue,
    private readonly dataSource: DataSource,
    private readonly notificationsService: NotificationsService,
    private readonly wholesalersService: WholesalersService,
    private readonly sellerLedgerService: SellerLedgerService,
  ) {}

  /**
   * 1. Calculate Checkout Summary (Server-side financial authority)
   */
  async calculateCheckoutSummary(
    items: { productId: string; quantity: number }[],
    userId?: string,
  ): Promise<CheckoutSummary> {
    if (!items || items.length === 0) {
      throw new BadRequestException('Cart cannot be empty');
    }

    const sellerMap: {
      [wholesalerId: string]: {
        wholesalerId: string;
        businessName: string;
        itemCount: number;
        subtotal: number;
      };
    } = {};

    let subtotal = 0;

    for (const item of items) {
      const product = await this.productsService.findOne(item.productId);
      const itemSubtotal = Number(product.pricePerUnit) * item.quantity;
      subtotal += itemSubtotal;

      const wId = product.wholesalerId;
      if (!sellerMap[wId]) {
        sellerMap[wId] = {
          wholesalerId: wId,
          businessName: product.wholesaler?.businessName || 'Wholesale Supplier',
          itemCount: 0,
          subtotal: 0,
        };
      }
      sellerMap[wId].itemCount += item.quantity;
      sellerMap[wId].subtotal += itemSubtotal;
    }

    // 15% wholesale cart discount policy (or promotional rule)
    const discountAmount = parseFloat((subtotal * 0.15).toFixed(2));
    // Free delivery above ₹1,500
    const deliveryFee = subtotal >= 1500 ? 0.0 : 49.0;
    // Standard GST / Taxes where applicable (e.g. 0% for basic staple groceries or 5%)
    const taxAmount = 0.0;
    const totalAmount = parseFloat(
      (subtotal - discountAmount + deliveryFee + taxAmount).toFixed(2),
    );

    return {
      subtotal: parseFloat(subtotal.toFixed(2)),
      discountAmount,
      deliveryFee,
      taxAmount,
      totalAmount,
      sellerBreakdown: Object.values(sellerMap).map((s) => ({
        ...s,
        subtotal: parseFloat(s.subtotal.toFixed(2)),
      })),
    };
  }

  /**
   * 2. Place Order: Atomically creates 1 Parent Order + N Child Seller Orders
   */
  async placeOrder(dto: PlaceOrderDto, userId: string): Promise<Order> {
    const retailer = await this.retailersService.findByUserId(userId);
    const retailerId = retailer.id;
    const zoneId = retailer.zoneId;

    if (!zoneId) {
      throw new BadRequestException(
        'Your account has no delivery zone assigned. Please contact support.',
      );
    }

    // Calculate official financial breakdown
    const summary = await this.calculateCheckoutSummary(dto.items, userId);

    // Group items by wholesaler
    const itemsByWholesaler: {
      [wholesalerId: string]: {
        productId: string;
        quantity: number;
        price: number;
        product: Product;
      }[];
    } = {};

    for (const item of dto.items) {
      const product = await this.productsService.findOne(item.productId);
      const wholesalerId = product.wholesalerId;
      if (!itemsByWholesaler[wholesalerId]) {
        itemsByWholesaler[wholesalerId] = [];
      }
      itemsByWholesaler[wholesalerId].push({
        productId: item.productId,
        quantity: item.quantity,
        price: product.pricePerUnit,
        product,
      });
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    const isPaid = dto.paymentIntentId != null;
    const paymentMethod = dto.paymentMethod || (isPaid ? 'UPI' : 'COD');

    // COD Eligibility Enforcement: Real wholesale safety policy
    if (paymentMethod === 'COD' && summary.totalAmount > 15000) {
      await queryRunner.rollbackTransaction();
      await queryRunner.release();
      throw new BadRequestException(
        'Cash on Delivery (COD) is available only for orders up to ₹15,000. For higher-value wholesale orders, please use Direct UPI or Debit/Credit Card.',
      );
    }

    const paymentStatus = isPaid
      ? OrderPaymentStatus.PAID
      : OrderPaymentStatus.PENDING;

    // Generate root order number (e.g. ZS10042)
    const baseOrderNumber = `ZS${Math.floor(10000 + Math.random() * 90000)}`;

    try {
      // 1. Create PARENT ORDER (Combined Cart)
      const parentOrder = queryRunner.manager.create(Order, {
        orderNumber: baseOrderNumber,
        retailerId,
        zoneId,
        deliveryAddress: dto.deliveryAddress,
        deliveryZone: dto.deliveryZone,
        totalAmount: summary.totalAmount,
        subtotalAmount: summary.subtotal,
        discountAmount: summary.discountAmount,
        deliveryFee: summary.deliveryFee,
        taxAmount: summary.taxAmount,
        status: isPaid ? OrderStatus.CONFIRMED : OrderStatus.PENDING,
        paymentIntentId: dto.paymentIntentId,
        paymentMethod,
        paymentStatus,
        isPaid,
      });
      const savedParentOrder = await queryRunner.manager.save(Order, parentOrder);

      const createdSellerOrders: Order[] = [];
      const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      let sellerIdx = 0;

      // 2. Create CHILD SELLER ORDERS for each Wholesaler
      for (const [wholesalerId, groupItems] of Object.entries(itemsByWholesaler)) {
        let sellerGross = 0;
        for (const item of groupItems) {
          sellerGross += Number(item.price) * item.quantity;
        }

        // Credit check if placing on credit
        if (paymentMethod === 'CREDIT') {
          const hasCredit = await this.creditLedgerService.checkCreditLimit(
            retailerId,
            wholesalerId,
            sellerGross,
          );
          if (!hasCredit) {
            throw new BadRequestException(
              `Credit limit exceeded for wholesaler ${wholesalerId}`,
            );
          }
        }

        // Fetch wholesaler commission rate snapshot
        const wholesaler = await this.wholesalersService.findOne(wholesalerId);
        const commissionRate = Number(wholesaler.commissionRate) || 5.0;
        const commissionAmount = parseFloat(
          ((sellerGross * commissionRate) / 100).toFixed(2),
        );
        const sellerNetAmount = parseFloat(
          (sellerGross - commissionAmount).toFixed(2),
        );

        // Lock & deduct stock quantities
        const savedOrderItems: OrderItem[] = [];
        for (const item of groupItems) {
          const lockedProduct = await queryRunner.manager.findOne(Product, {
            where: { id: item.productId },
            lock: { mode: 'pessimistic_write' },
          });

          if (!lockedProduct) {
            throw new NotFoundException(`Product ${item.productId} not found`);
          }

          if (lockedProduct.stockQuantity < item.quantity) {
            throw new BadRequestException(
              `Insufficient stock for product ${lockedProduct.name}. Available: ${lockedProduct.stockQuantity}`,
            );
          }

          lockedProduct.stockQuantity -= item.quantity;
          await queryRunner.manager.save(Product, lockedProduct);

          const orderItem = queryRunner.manager.create(OrderItem, {
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.price,
            subtotal: Number(item.price) * item.quantity,
          });
          savedOrderItems.push(orderItem);
        }

        // Child seller order record
        const suffix = alphabet[sellerIdx % alphabet.length];
        sellerIdx++;
        const sellerOrderNumber = `${baseOrderNumber}-${suffix}`;

        const sellerOrder = queryRunner.manager.create(Order, {
          orderNumber: sellerOrderNumber,
          parentOrderId: savedParentOrder.id,
          retailerId,
          wholesalerId,
          zoneId,
          deliveryAddress: dto.deliveryAddress,
          deliveryZone: dto.deliveryZone,
          status: isPaid ? OrderStatus.CONFIRMED : OrderStatus.PENDING,
          totalAmount: sellerGross,
          sellerGrossAmount: sellerGross,
          commissionRate,
          commissionAmount,
          sellerNetAmount,
          items: savedOrderItems,
          paymentIntentId: dto.paymentIntentId,
          paymentMethod,
          paymentStatus,
          isPaid,
          deliveryOtp: Math.floor(1000 + Math.random() * 9000).toString(),
        });
        const savedSellerOrder = await queryRunner.manager.save(Order, sellerOrder);

        // 3. Record Initial Seller Ledger Sale entry
        await this.sellerLedgerService.recordSale(
          wholesalerId,
          savedParentOrder.id,
          savedSellerOrder.id,
          sellerGross,
          queryRunner.manager,
        );

        // 4. Record Debit Ledger transaction if on credit
        if (paymentMethod === 'CREDIT') {
          await this.creditLedgerService.recordDebit(
            retailerId,
            wholesalerId,
            savedSellerOrder.id,
            sellerGross,
            queryRunner.manager,
          );
        }

        createdSellerOrders.push(savedSellerOrder);
      }

      await queryRunner.commitTransaction();

      // 5. Dispatch child seller orders to BullMQ pooling queue
      for (const sOrder of createdSellerOrders) {
        try {
          await this.consolidationQueue.add('pool-order', {
            orderId: sOrder.id,
            zoneId: sOrder.zoneId,
            wholesalerId: sOrder.wholesalerId,
          });
        } catch (err) {
          console.error('Failed to add order to consolidation queue', err);
        }
      }

      // 6. Push notification to retailer
      try {
        await this.notificationsService.sendToUser(retailer.userId, {
          title: 'Order Confirmed',
          message: `Order #${baseOrderNumber} for ₹${summary.totalAmount} has been placed across ${createdSellerOrders.length} wholesaler(s).`,
        });
      } catch (_) {}

      // Fetch populated parent order to return
      return this.findOne(savedParentOrder.id);
    } catch (err) {
      if (queryRunner.isTransactionActive) {
        await queryRunner.rollbackTransaction();
      }
      throw err;
    } finally {
      if (!queryRunner.isReleased) {
        await queryRunner.release();
      }
    }
  }

  /**
   * 3. Mark Order as Paid (invoked upon backend payment verification / webhook)
   */
  async markOrderAsPaid(
    parentOrderId: string,
    providerPaymentId: string,
    paymentMethod = 'UPI',
  ): Promise<Order> {
    const parentOrder = await this.orderRepo.findOne({
      where: { id: parentOrderId },
      relations: { childOrders: true },
    });

    if (!parentOrder) {
      throw new NotFoundException(`Order ${parentOrderId} not found`);
    }

    parentOrder.isPaid = true;
    parentOrder.paymentStatus = OrderPaymentStatus.PAID;
    parentOrder.paymentIntentId = providerPaymentId;
    parentOrder.paymentMethod = paymentMethod;
    if (parentOrder.status === OrderStatus.PENDING) {
      parentOrder.status = OrderStatus.CONFIRMED;
    }
    await this.orderRepo.save(parentOrder);

    // Update all child seller orders
    if (parentOrder.childOrders) {
      for (const child of parentOrder.childOrders) {
        child.isPaid = true;
        child.paymentStatus = OrderPaymentStatus.PAID;
        child.paymentIntentId = providerPaymentId;
        child.paymentMethod = paymentMethod;
        if (child.status === OrderStatus.PENDING) {
          child.status = OrderStatus.CONFIRMED;
        }
        await this.orderRepo.save(child);
      }
    }

    return parentOrder;
  }

  /**
   * 4. Retailer Query: Returns Parent Orders with their Child Seller Orders
   */
  async findByRetailer(userId: string): Promise<Order[]> {
    const retailer = await this.retailersService.findByUserId(userId);
    return this.orderRepo.find({
      where: { retailerId: retailer.id, parentOrderId: IsNull() },
      order: { createdAt: 'DESC' },
      relations: {
        items: true,
        childOrders: {
          items: true,
          wholesaler: { user: true },
        },
        wholesaler: { user: true },
      },
    });
  }

  /**
   * 5. Wholesaler Query: Returns ONLY sub-orders for that Wholesaler (Tenant Isolation)
   */
  async findByWholesaler(userId: string): Promise<Order[]> {
    const wholesaler = await this.wholesalersService.findByUserId(userId);
    return this.orderRepo.find({
      where: { wholesalerId: wholesaler.id },
      order: { createdAt: 'DESC' },
      relations: {
        items: true,
        wholesaler: { user: true },
        retailer: { user: true },
        parentOrder: true,
      },
    });
  }

  /**
   * 6. Admin Query: Returns all orders
   */
  async findAll(): Promise<Order[]> {
    return this.orderRepo.find({
      order: { createdAt: 'DESC' },
      relations: {
        items: true,
        wholesaler: { user: true },
        retailer: { user: true },
        childOrders: {
          items: true,
          wholesaler: { user: true },
        },
      },
    });
  }

  async findOne(id: string): Promise<Order> {
    const order = await this.orderRepo.findOne({
      where: { id },
      relations: {
        items: true,
        wholesaler: { user: true },
        retailer: { user: true },
        childOrders: {
          items: true,
          wholesaler: { user: true },
        },
        parentOrder: true,
      },
    });
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  async findOneSecure(id: string, user: any): Promise<Order> {
    const order = await this.findOne(id);
    if (user.role === UserRole.WHOLESALER) {
      const wholesaler = await this.wholesalersService.findByUserId(user.id);
      if (order.wholesalerId !== wholesaler.id) {
        throw new ForbiddenException('Access denied to this order');
      }
    } else if (user.role === UserRole.RETAILER) {
      const retailer = await this.retailersService.findByUserId(user.id);
      if (order.retailerId !== retailer.id) {
        throw new ForbiddenException('Access denied to this order');
      }
    }
    return order;
  }

  /**
   * 7. Update Status (Seller fulfillment & Delivery settlement eligibility)
   */
  async updateStatus(
    id: string,
    status: OrderStatus,
    userId?: string,
  ): Promise<Order> {
    const order = await this.findOne(id);
    if (userId) {
      const wholesaler = await this.wholesalersService.findByUserId(userId);
      if (order.wholesalerId !== wholesaler.id) {
        throw new ForbiddenException("Cannot modify another wholesaler's order");
      }
    }

    const oldStatus = order.status;
    if (status !== oldStatus) {
      if (status === OrderStatus.CANCELLED) {
        // Reverse credit ledger ONLY IF placed with CREDIT and has a valid wholesalerId
        if (order.paymentMethod === 'CREDIT' && order.wholesalerId) {
          try {
            await this.creditLedgerService.recordReversal(
              order.retailerId,
              order.wholesalerId,
              order.id,
              order.totalAmount,
            );
          } catch (err) {
            console.error('Failed to record credit reversal', err);
          }
        }
        // If parent order cancelled, cancel child seller orders as well
        if (!order.parentOrderId && order.childOrders && order.childOrders.length > 0) {
          for (const child of order.childOrders) {
            child.status = OrderStatus.CANCELLED;
            await this.orderRepo.save(child);
            if (child.paymentMethod === 'CREDIT' && child.wholesalerId) {
              try {
                await this.creditLedgerService.recordReversal(
                  child.retailerId,
                  child.wholesalerId,
                  child.id,
                  child.totalAmount,
                );
              } catch (_) {}
            }
          }
        }
      } else if (status === OrderStatus.DELIVERED) {
        // Mark ledger entries as settlement-eligible for seller sub-orders
        if (order.wholesalerId) {
          try {
            await this.sellerLedgerService.markEntriesEligible(order.id);
          } catch (err) {
            console.error('Failed to mark entries eligible', err);
          }
        }
        order.settlementEligibleAt = new Date();
        status = OrderStatus.SETTLEMENT_ELIGIBLE;
      }
    }

    order.status = status;
    const saved = await this.orderRepo.save(order);

    // If child order updated, check if parent order status should advance
    if (order.parentOrderId) {
      try {
        const parent = await this.findOne(order.parentOrderId);
        if (parent.childOrders && parent.childOrders.length > 0) {
          const allDelivered = parent.childOrders.every(
            (c) =>
              c.status === OrderStatus.DELIVERED ||
              c.status === OrderStatus.SETTLEMENT_ELIGIBLE,
          );
          if (allDelivered) {
            parent.status = OrderStatus.DELIVERED;
            await this.orderRepo.save(parent);
          }
        }
      } catch (_) {}
    }

    return saved;
  }

  async getOrderTracking(orderId: string, user: any): Promise<any> {
    const order = await this.orderRepo.findOne({
      where: { id: orderId },
      relations: { retailer: true, childOrders: true },
    });
    if (!order) throw new NotFoundException('Order not found');

    if (user.role === UserRole.RETAILER) {
      const retailer = await this.retailersService.findByUserId(user.id);
      if (order.retailerId !== retailer.id) {
        throw new ForbiddenException('Access denied');
      }
    }

    // Check if parent order or has batch
    const batchId =
      order.consolidationBatchId ||
      order.childOrders?.find((c) => c.consolidationBatchId)?.consolidationBatchId;

    if (!batchId) {
      return {
        status: order.status,
        agent: null,
        location: null,
        childStatuses: order.childOrders?.map((c) => ({
          sellerOrderId: c.id,
          orderNumber: c.orderNumber,
          wholesalerId: c.wholesalerId,
          status: c.status,
        })),
      };
    }

    const batch = await this.dataSource
      .getRepository(ConsolidationBatch)
      .findOne({
        where: { id: batchId },
        relations: { deliveryPartner: { user: true } },
      });

    let agent: { name: string; phone: string } | null = null;
    if (batch?.deliveryPartner) {
      agent = {
        name: batch.deliveryPartner.user?.name || 'Agent',
        phone: batch.deliveryPartner.user?.phone || '+91 99999 99999',
      };
    }

    const tracking = await this.dataSource
      .getRepository(DeliveryTracking)
      .findOne({
        where: { batchId },
        order: { timestamp: 'DESC' },
      });

    return {
      status: order.status,
      batchStatus: batch?.status,
      agent,
      childStatuses: order.childOrders?.map((c) => ({
        sellerOrderId: c.id,
        orderNumber: c.orderNumber,
        wholesalerId: c.wholesalerId,
        status: c.status,
      })),
      location: tracking
        ? {
            latitude: Number(tracking.latitude),
            longitude: Number(tracking.longitude),
            timestamp: tracking.timestamp,
          }
        : null,
    };
  }
}
