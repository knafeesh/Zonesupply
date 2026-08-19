import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, IsNull, In } from 'typeorm';
import { ConsolidationBatch, BatchStatus } from './consolidation-batch.entity';
import { BatchOrder, BatchOrderDeliveryStatus } from './batch-order.entity';
import { Order } from '../orders/order.entity';
import { OrderStatus } from '../common/enums/order-status.enum';
import { DeliveryPartnersService } from '../delivery-partners/delivery-partners.service';
import { DeliveryPartner } from '../delivery-partners/delivery-partner.entity';
import { CreditLedgerService } from '../credit-ledger/credit-ledger.service';
import { NotificationsService } from '../notifications/notifications.service';
import { DeliveryPartnerStatus } from '../common/enums/delivery-partner-status.enum';
import { Wholesaler } from '../wholesalers/wholesaler.entity';
import { Retailer } from '../retailers/retailer.entity';
import { UserRole } from '../common/enums/user-role.enum';

@Injectable()
export class ConsolidationService {
  constructor(
    @InjectRepository(ConsolidationBatch)
    private readonly batchRepo: Repository<ConsolidationBatch>,
    @InjectRepository(BatchOrder)
    private readonly batchOrderRepo: Repository<BatchOrder>,
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
    private readonly partnersService: DeliveryPartnersService,
    private readonly creditLedgerService: CreditLedgerService,
    private readonly notificationsService: NotificationsService,
    private readonly dataSource: DataSource,
  ) {}

  async processOrderPooling(zoneId: string, wholesalerId: string): Promise<any> {
    const pendingOrders = await this.orderRepo.find({
      where: { zoneId, wholesalerId, status: In([OrderStatus.PENDING, OrderStatus.CONFIRMED]) },
      relations: { retailer: true },
    });

    if (pendingOrders.length === 0) return { status: 'no_orders' };

    const orderCount = pendingOrders.length;
    let totalValue = 0;
    let oldestCreatedAt = pendingOrders[0].createdAt;

    for (const order of pendingOrders) {
      totalValue += Number(order.totalAmount);
      if (order.createdAt < oldestCreatedAt) {
        oldestCreatedAt = order.createdAt;
      }
    }

    const elapsedMs = Date.now() - oldestCreatedAt.getTime();
    const elapsedHours = elapsedMs / (1000 * 60 * 60);

    const COUNT_THRESHOLD = 3;
    const VALUE_THRESHOLD = 5000;
    const MAX_WAIT_SLA_HOURS = 4;

    const shouldConsolidate =
      orderCount >= COUNT_THRESHOLD ||
      totalValue >= VALUE_THRESHOLD ||
      elapsedHours >= MAX_WAIT_SLA_HOURS;

    if (!shouldConsolidate) {
      return { status: 'waiting_for_more', count: orderCount, value: totalValue };
    }

    // Begin consolidation transaction
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Find nearest available delivery partner in zone
      const availablePartners = await this.partnersService.findAvailableInZone(zoneId);
      let assignedPartner = availablePartners.length > 0 ? availablePartners[0] : null;

      // Create Consolidation Batch
      const batch = queryRunner.manager.create(ConsolidationBatch, {
        zoneId,
        wholesalerId,
        deliveryPartnerId: assignedPartner ? assignedPartner.id : null,
        status: BatchStatus.CREATED,
        totalValue,
        orderCount,
      });

      const savedBatch = await queryRunner.manager.save(ConsolidationBatch, batch);

      // Check wholesaler coordinates
      const wholesaler = await queryRunner.manager.findOne(Wholesaler, { where: { id: wholesalerId } });
      const wLat = wholesaler ? Number(wholesaler.latitude) : 0;
      const wLng = wholesaler ? Number(wholesaler.longitude) : 0;

      // Sort pending orders by distance (simple heuristic route optimization)
      const ordersWithCoords: { order: Order; dist: number }[] = [];
      for (const order of pendingOrders) {
        const retailer = await queryRunner.manager.findOne(Retailer, { where: { id: order.retailerId } });
        const rLat = retailer ? Number(retailer.latitude) : 0;
        const rLng = retailer ? Number(retailer.longitude) : 0;
        const dist = this.calculateDistance(wLat, wLng, rLat, rLng);
        ordersWithCoords.push({ order, dist });
      }

      ordersWithCoords.sort((a, b) => a.dist - b.dist);

      // Save batch orders in optimized sequence
      for (let i = 0; i < ordersWithCoords.length; i++) {
        const item = ordersWithCoords[i];
        const batchOrder = queryRunner.manager.create(BatchOrder, {
          batchId: savedBatch.id,
          orderId: item.order.id,
          deliverySequence: i + 1,
          deliveryStatus: BatchOrderDeliveryStatus.PENDING,
        });
        await queryRunner.manager.save(BatchOrder, batchOrder);

        // Update Order status
        item.order.status = OrderStatus.CONSOLIDATED;
        item.order.consolidationBatchId = savedBatch.id;
        await queryRunner.manager.save(Order, item.order);
      }

      // If partner assigned, mark them BUSY
      if (assignedPartner) {
        assignedPartner.status = DeliveryPartnerStatus.BUSY;
        await queryRunner.manager.save(assignedPartner);
      }

      await queryRunner.commitTransaction();

      // Dispatch Notifications
      if (assignedPartner) {
        await this.notificationsService.sendToUser(assignedPartner.userId, {
          title: 'Delivery Job Assigned',
          message: `A new consolidated batch of ${orderCount} orders in your zone is ready for pickup.`,
        });
      }

      for (const order of pendingOrders) {
        await this.notificationsService.sendToUser(order.retailer.userId, {
          title: 'Order Consolidated',
          message: `Your order has been consolidated into batch #${savedBatch.id.substring(0, 8)}.`,
        });
      }

      return savedBatch;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async findAvailableJobs(): Promise<ConsolidationBatch[]> {
    return this.batchRepo.find({
      where: { status: BatchStatus.CREATED, deliveryPartnerId: IsNull() },
      order: { createdAt: 'DESC' },
    });
  }

  async findMyJobs(agentUserId: string): Promise<ConsolidationBatch[]> {
    const partner = await this.partnersService.findByUserId(agentUserId);
    return this.batchRepo.find({
      where: [
        { deliveryPartnerId: partner.id, status: BatchStatus.CREATED },
        { deliveryPartnerId: partner.id, status: BatchStatus.PICKED_UP },
        { deliveryPartnerId: partner.id, status: BatchStatus.IN_TRANSIT },
      ],
      order: { createdAt: 'DESC' },
    });
  }

  async claimJob(batchId: string, agentUserId: string): Promise<ConsolidationBatch> {
    const partner = await this.partnersService.findByUserId(agentUserId);
    const batch = await this.batchRepo.findOneBy({ id: batchId });
    if (!batch) throw new NotFoundException('Batch not found');
    if (batch.deliveryPartnerId) throw new BadRequestException('Job already claimed');

    batch.deliveryPartnerId = partner.id;
    const saved = await this.batchRepo.save(batch);

    partner.status = DeliveryPartnerStatus.BUSY;
    await this.partnersService.update(agentUserId, { status: DeliveryPartnerStatus.BUSY });

    return saved;
  }

  async markPickedUp(batchId: string): Promise<ConsolidationBatch> {
    const batch = await this.batchRepo.findOneBy({ id: batchId });
    if (!batch) throw new NotFoundException('Batch not found');
    batch.status = BatchStatus.PICKED_UP;
    batch.pickupTime = new Date();
    const saved = await this.batchRepo.save(batch);

    // All orders → DISPATCHED (picked up from wholesaler, heading out)
    const batchOrders = await this.batchOrderRepo.findBy({ batchId });
    for (const bo of batchOrders) {
      await this.orderRepo.update(bo.orderId, { status: OrderStatus.DISPATCHED });
    }

    return saved;
  }

  async markInTransit(batchId: string): Promise<ConsolidationBatch> {
    const batch = await this.batchRepo.findOneBy({ id: batchId });
    if (!batch) throw new NotFoundException('Batch not found');

    // Only transition if currently PICKED_UP
    if (batch.status === BatchStatus.PICKED_UP) {
      batch.status = BatchStatus.IN_TRANSIT;
      await this.batchRepo.save(batch);

      // All still-pending orders → IN_TRANSIT (out for delivery)
      const batchOrders = await this.batchOrderRepo.findBy({ batchId });
      for (const bo of batchOrders) {
        await this.orderRepo.update(bo.orderId, { status: OrderStatus.IN_TRANSIT });
      }
    }

    return batch;
  }

  async confirmPOD(
    batchId: string,
    orderId: string,
    partnerUserId: string,
    coords: { lat: number; lng: number },
    status: 'delivered' | 'failed',
    otp?: string,
  ): Promise<BatchOrder> {
    const partner = await this.partnersService.findByUserId(partnerUserId);
    const bo = await this.batchOrderRepo.findOne({
      where: { batchId, orderId },
      relations: { order: true },
    });

    if (!bo) throw new NotFoundException('Order in batch not found');

    // 1. Geofence Check
    const retailer = await this.dataSource.manager.findOne(Retailer, {
      where: { id: bo.order.retailerId },
    });

    if (retailer) {
      const distance = this.calculateDistance(
        coords.lat,
        coords.lng,
        Number(retailer.latitude),
        Number(retailer.longitude),
      );
      if (distance > 0.5) {
        throw new BadRequestException(
          `Delivery confirm rejected. You are ${Math.round(distance * 1000)}m away. Must be within 500m radius of shop.`,
        );
      }
    }

    // 1b. OTP Check
    if (status === 'delivered' && bo.order.deliveryOtp) {
      if (bo.order.deliveryOtp !== otp) {
        throw new BadRequestException(
          `Delivery verification failed. Invalid OTP code. Please ask the retailer for the correct OTP.`,
        );
      }
    }

    // Update status
    bo.deliveryStatus =
      status === 'delivered'
        ? BatchOrderDeliveryStatus.DELIVERED
        : BatchOrderDeliveryStatus.FAILED;

    const saved = await this.batchOrderRepo.save(bo);

    // Update Order Status
    const orderStatus =
      status === 'delivered' ? OrderStatus.DELIVERED : OrderStatus.CANCELLED;
    await this.orderRepo.update(orderId, { status: orderStatus });

    // 2. Ledger balance reconciliation (COD / payment settles outstanding)
    if (status === 'delivered') {
      // If payment method settles outstanding, credit back outstanding.
      // For this spec, cash/COD payment settles ledger balance.
      // We will credit the ledger to settle the debit transaction recorded at order time.
      await this.creditLedgerService.recordCreditPayment(
        bo.order.retailerId,
        bo.order.wholesalerId,
        bo.order.totalAmount,
        orderId,
      );
    } else {
      // Reversal for failed/cancelled delivery
      await this.creditLedgerService.recordReversal(
        bo.order.retailerId,
        bo.order.wholesalerId,
        orderId,
        bo.order.totalAmount,
      );
    }

    // 3. Complete Batch check if all drops done
    const remaining = await this.batchOrderRepo.countBy({
      batchId,
      deliveryStatus: BatchOrderDeliveryStatus.PENDING,
    });

    if (remaining === 0) {
      await this.batchRepo.update(batchId, { status: BatchStatus.COMPLETED });
      // Restore partner status
      partner.status = DeliveryPartnerStatus.AVAILABLE;
      await this.partnersService.update(partnerUserId, { status: DeliveryPartnerStatus.AVAILABLE });
    }

    return saved;
  }

  async findAll(wholesalerUserId?: string): Promise<any[]> {
    let whereClause = {};
    if (wholesalerUserId) {
      const wholesaler = await this.dataSource.getRepository(Wholesaler).findOne({
        where: { userId: wholesalerUserId },
      });
      if (wholesaler) {
        whereClause = { wholesalerId: wholesaler.id };
      }
    }
    const batches = await this.batchRepo.find({
      where: whereClause,
      relations: {
        zone: true,
        deliveryPartner: { user: true },
      },
      order: { createdAt: 'DESC' },
    });

    const populated: any[] = [];
    for (const b of batches) {
      const batchOrders = await this.dataSource.getRepository(BatchOrder).find({
        where: { batchId: b.id },
        relations: {
          order: {
            retailer: { user: true },
          },
        },
      });

      const retailerNames = Array.from(
        new Set(
          batchOrders
            .map(bo => bo.order?.retailer?.shopName || bo.order?.retailer?.user?.name)
            .filter(Boolean),
        ),
      );

      const deliveredCount = batchOrders.filter(
        bo => bo.deliveryStatus === BatchOrderDeliveryStatus.DELIVERED,
      ).length;

      populated.push({
        ...b,
        retailerNames: retailerNames.join(', ') || 'Retailer',
        deliveredCount,
      });
    }

    return populated;
  }

  async findOpenBatches(wholesalerUserId?: string): Promise<ConsolidationBatch[]> {
    let whereClause: any = [
      { status: BatchStatus.CREATED },
      { status: BatchStatus.PICKED_UP },
      { status: BatchStatus.IN_TRANSIT },
    ];

    if (wholesalerUserId) {
      const wholesaler = await this.dataSource.getRepository(Wholesaler).findOne({
        where: { userId: wholesalerUserId },
      });
      if (wholesaler) {
        whereClause = [
          { status: BatchStatus.CREATED, wholesalerId: wholesaler.id },
          { status: BatchStatus.PICKED_UP, wholesalerId: wholesaler.id },
          { status: BatchStatus.IN_TRANSIT, wholesalerId: wholesaler.id },
        ];
      }
    }

    return this.batchRepo.find({
      where: whereClause,
      order: { createdAt: 'DESC' },
    });
  }

  async closeBatch(id: string): Promise<ConsolidationBatch> {
    const batch = await this.batchRepo.findOneBy({ id });
    if (!batch) throw new NotFoundException('Batch not found');
    batch.status = BatchStatus.COMPLETED;
    return this.batchRepo.save(batch);
  }

  async assignDeliveryAgent(id: string, agentId: string): Promise<ConsolidationBatch> {
    const batch = await this.batchRepo.findOneBy({ id });
    if (!batch) throw new NotFoundException('Batch not found');
    
    const partner = await this.partnersService.findOne(agentId);
    batch.deliveryPartnerId = partner.id;
    
    partner.status = DeliveryPartnerStatus.BUSY;
    await this.partnersService.update(partner.userId, { status: DeliveryPartnerStatus.BUSY });
    
    const saved = await this.batchRepo.save(batch);

    await this.notificationsService.sendToUser(partner.userId, {
      title: 'Delivery Job Assigned',
      message: `A new consolidated batch of ${batch.orderCount} orders in your zone is ready for pickup.`,
    });

    return saved;
  }

  async findOne(id: string): Promise<any> {
    const batch = await this.batchRepo.findOne({
      where: { id },
      relations: {
        zone: true,
        deliveryPartner: { user: true },
        wholesaler: { user: true },
      },
    });
    if (!batch) throw new NotFoundException('Batch not found');

    const batchOrders = await this.batchOrderRepo.find({
      where: { batchId: id },
      relations: {
        order: {
          retailer: { user: true },
        },
      },
      order: { deliverySequence: 'ASC' },
    });

    return {
      ...batch,
      orders: batchOrders.map(bo => ({
        id: bo.order.id,
        retailerName: bo.order.retailer?.shopName || bo.order.retailer?.user?.name || 'Retailer',
        shopName: bo.order.retailer?.shopName,
        address: bo.order.retailer?.address,
        phone: bo.order.retailer?.user?.phone,
        latitude: bo.order.retailer?.latitude,
        longitude: bo.order.retailer?.longitude,
        totalAmount: bo.order.totalAmount,
        status: bo.order.status,
        deliveryStatus: bo.deliveryStatus,
        deliverySequence: bo.deliverySequence,
        paymentMethod: bo.order.paymentIntentId ? 'ONLINE' : 'COD',
        paymentStatus: bo.order.isPaid ? 'PAID' : 'PENDING',
        deliveryOtp: bo.order.deliveryOtp,
      })),
    };
  }

  async findOneSecure(id: string, user: any): Promise<any> {
    const batchData = await this.findOne(id);

    if (user.role === UserRole.WHOLESALER) {
      const wholesaler = await this.dataSource.getRepository(Wholesaler).findOne({
        where: { userId: user.id },
      });
      if (!wholesaler || batchData.wholesalerId !== wholesaler.id) {
        throw new ForbiddenException('Access denied to this consolidation batch');
      }
    } else if (user.role === UserRole.DELIVERY) {
      const partner = await this.partnersService.findByUserId(user.id);
      if (batchData.deliveryPartnerId && batchData.deliveryPartnerId !== partner.id) {
        throw new ForbiddenException('Access denied to this consolidation batch');
      }
    }
    return batchData;
  }

  async closeBatchSecure(id: string, userId: string): Promise<ConsolidationBatch> {
    const wholesaler = await this.dataSource.getRepository(Wholesaler).findOne({
      where: { userId },
    });
    if (!wholesaler) throw new NotFoundException('Wholesaler profile not found');
    const batch = await this.batchRepo.findOneBy({ id });
    if (!batch) throw new NotFoundException('Batch not found');
    if (batch.wholesalerId !== wholesaler.id) {
      throw new ForbiddenException('Cannot close another wholesaler\'s batch');
    }
    batch.status = BatchStatus.COMPLETED;
    return this.batchRepo.save(batch);
  }

  async assignDeliveryAgentSecure(id: string, agentId: string, user: any): Promise<ConsolidationBatch> {
    const batch = await this.batchRepo.findOneBy({ id });
    if (!batch) throw new NotFoundException('Batch not found');

    if (user.role === UserRole.WHOLESALER) {
      const wholesaler = await this.dataSource.getRepository(Wholesaler).findOne({
        where: { userId: user.id },
      });
      if (!wholesaler || batch.wholesalerId !== wholesaler.id) {
        throw new ForbiddenException('Cannot assign agent to another wholesaler\'s batch');
      }
    }
    const partner = await this.partnersService.findOne(agentId);
    batch.deliveryPartnerId = partner.id;
    
    partner.status = DeliveryPartnerStatus.BUSY;
    await this.partnersService.update(partner.userId, { status: DeliveryPartnerStatus.BUSY });
    
    const saved = await this.batchRepo.save(batch);

    await this.notificationsService.sendToUser(partner.userId, {
      title: 'Delivery Job Assigned',
      message: `A new consolidated batch of ${batch.orderCount} orders in your zone is ready for pickup.`,
    });

    return saved;
  }

  async getDeliveryAgents(): Promise<DeliveryPartner[]> {
    return this.partnersService.findAll();
  }

  async processOrderPoolingManualByUserId(zoneId: string, userId: string): Promise<ConsolidationBatch> {
    const wholesaler = await this.dataSource.getRepository(Wholesaler).findOne({
      where: { userId },
    });
    if (!wholesaler) throw new NotFoundException('Wholesaler profile not found');
    return this.processOrderPoolingManual(zoneId, wholesaler.id);
  }

  async processOrderPoolingManual(zoneId: string, wholesalerId: string): Promise<ConsolidationBatch> {
    const pendingOrders = await this.orderRepo.find({
      where: { zoneId, wholesalerId, status: In([OrderStatus.PENDING, OrderStatus.CONFIRMED]) },
      relations: { retailer: true },
    });

    if (pendingOrders.length === 0) {
      throw new BadRequestException('No pending orders in this zone to consolidate.');
    }

    const orderCount = pendingOrders.length;
    let totalValue = 0;

    for (const order of pendingOrders) {
      totalValue += Number(order.totalAmount);
    }

    // Begin consolidation transaction
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Find nearest available delivery partner in zone
      const availablePartners = await this.partnersService.findAvailableInZone(zoneId);
      let assignedPartner = availablePartners.length > 0 ? availablePartners[0] : null;

      // Create Consolidation Batch
      const batch = queryRunner.manager.create(ConsolidationBatch, {
        zoneId,
        wholesalerId,
        deliveryPartnerId: assignedPartner ? assignedPartner.id : null,
        status: BatchStatus.CREATED,
        totalValue,
        orderCount,
      });

      const savedBatch = await queryRunner.manager.save(ConsolidationBatch, batch);

      // Check wholesaler coordinates
      const wholesaler = await queryRunner.manager.findOne(Wholesaler, { where: { id: wholesalerId } });
      const wLat = wholesaler ? Number(wholesaler.latitude) : 0;
      const wLng = wholesaler ? Number(wholesaler.longitude) : 0;

      // Sort pending orders by distance (simple heuristic route optimization)
      const ordersWithCoords: { order: Order; dist: number }[] = [];
      for (const order of pendingOrders) {
        const retailer = await queryRunner.manager.findOne(Retailer, { where: { id: order.retailerId } });
        const rLat = retailer ? Number(retailer.latitude) : 0;
        const rLng = retailer ? Number(retailer.longitude) : 0;
        const dist = this.calculateDistance(wLat, wLng, rLat, rLng);
        ordersWithCoords.push({ order, dist });
      }

      ordersWithCoords.sort((a, b) => a.dist - b.dist);

      // Save batch orders in optimized sequence
      for (let i = 0; i < ordersWithCoords.length; i++) {
        const item = ordersWithCoords[i];
        const batchOrder = queryRunner.manager.create(BatchOrder, {
          batchId: savedBatch.id,
          orderId: item.order.id,
          deliverySequence: i + 1,
          deliveryStatus: BatchOrderDeliveryStatus.PENDING,
        });
        await queryRunner.manager.save(BatchOrder, batchOrder);

        // Update Order status
        item.order.status = OrderStatus.CONSOLIDATED;
        item.order.consolidationBatchId = savedBatch.id;
        await queryRunner.manager.save(Order, item.order);
      }

      // If partner assigned, mark them BUSY
      if (assignedPartner) {
        assignedPartner.status = DeliveryPartnerStatus.BUSY;
        await queryRunner.manager.save(assignedPartner);
      }

      await queryRunner.commitTransaction();

      // Dispatch Notifications
      if (assignedPartner) {
        await this.notificationsService.sendToUser(assignedPartner.userId, {
          title: 'Delivery Job Assigned',
          message: `A new consolidated batch of ${orderCount} orders in your zone is ready for pickup.`,
        });
      }

      for (const order of pendingOrders) {
        await this.notificationsService.sendToUser(order.retailer.userId, {
          title: 'Order Consolidated',
          message: `Your order has been consolidated into batch #${savedBatch.id.substring(0, 8)}.`,
        });
      }

      return savedBatch;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async mergeOrdersIntoBatch(wholesalerUserId: string, orderIds: string[]): Promise<ConsolidationBatch> {
    if (orderIds.length === 0) {
      throw new BadRequestException('No orders selected for merging.');
    }

    const wholesaler = await this.dataSource.getRepository(Wholesaler).findOne({
      where: { userId: wholesalerUserId },
    });
    if (!wholesaler) throw new NotFoundException('Wholesaler profile not found');

    const orders = await this.orderRepo.find({
      where: { id: In(orderIds), wholesalerId: wholesaler.id, status: In([OrderStatus.PENDING, OrderStatus.CONFIRMED]) },
      relations: { retailer: true },
    });

    if (orders.length !== orderIds.length) {
      throw new BadRequestException('Some orders are invalid or not in pending state.');
    }

    const zoneId = orders[0].zoneId;
    const orderCount = orders.length;
    let totalValue = 0;
    for (const o of orders) {
      totalValue += Number(o.totalAmount);
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const availablePartners = await this.partnersService.findAvailableInZone(zoneId);
      let assignedPartner = availablePartners.length > 0 ? availablePartners[0] : null;

      const batch = queryRunner.manager.create(ConsolidationBatch, {
        zoneId,
        wholesalerId: wholesaler.id,
        deliveryPartnerId: assignedPartner ? assignedPartner.id : null,
        status: BatchStatus.CREATED,
        totalValue,
        orderCount,
      });

      const savedBatch = await queryRunner.manager.save(ConsolidationBatch, batch);

      const wLat = Number(wholesaler.latitude) || 0;
      const wLng = Number(wholesaler.longitude) || 0;

      const ordersWithCoords: { order: Order; dist: number }[] = [];
      for (const order of orders) {
        const retailer = await queryRunner.manager.findOne(Retailer, { where: { id: order.retailerId } });
        const rLat = retailer ? Number(retailer.latitude) : 0;
        const rLng = retailer ? Number(retailer.longitude) : 0;
        const dist = this.calculateDistance(wLat, wLng, rLat, rLng);
        ordersWithCoords.push({ order, dist });
      }

      ordersWithCoords.sort((a, b) => a.dist - b.dist);

      for (let i = 0; i < ordersWithCoords.length; i++) {
        const item = ordersWithCoords[i];
        const batchOrder = queryRunner.manager.create(BatchOrder, {
          batchId: savedBatch.id,
          orderId: item.order.id,
          deliverySequence: i + 1,
          deliveryStatus: BatchOrderDeliveryStatus.PENDING,
        });
        await queryRunner.manager.save(BatchOrder, batchOrder);

        item.order.status = OrderStatus.CONSOLIDATED;
        item.order.consolidationBatchId = savedBatch.id;
        await queryRunner.manager.save(Order, item.order);
      }

      if (assignedPartner) {
        assignedPartner.status = DeliveryPartnerStatus.BUSY;
        await queryRunner.manager.save(assignedPartner);
      }

      await queryRunner.commitTransaction();

      if (assignedPartner) {
        await this.notificationsService.sendToUser(assignedPartner.userId, {
          title: 'Delivery Job Assigned',
          message: `A manual batch of ${orderCount} orders in your zone is ready for pickup.`,
        });
      }

      return savedBatch;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  // Haversine distance helper
  private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // radius in km
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) *
        Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }
}
