import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  OneToMany,
  JoinColumn,
  Index,
} from 'typeorm';
import { Retailer } from '../retailers/retailer.entity';
import { Wholesaler } from '../wholesalers/wholesaler.entity';
import { Zone } from '../zones/zone.entity';
import { OrderStatus } from '../common/enums/order-status.enum';
import { OrderItem } from './order-item.entity';

export enum OrderPaymentStatus {
  PENDING = 'PENDING',
  PAID = 'PAID',
  FAILED = 'FAILED',
  REFUNDED = 'REFUNDED',
  PARTIALLY_REFUNDED = 'PARTIALLY_REFUNDED',
}

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /** Human-readable order number (e.g. ZS10001 for parent, ZS10001-A for seller sub-order) */
  @Index()
  @Column({ nullable: true })
  orderNumber: string;

  /** Parent Order relationship for multi-wholesaler order splitting */
  @Index()
  @Column({ nullable: true })
  parentOrderId: string;

  @ManyToOne(() => Order, (order) => order.childOrders, {
    nullable: true,
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'parentOrderId' })
  parentOrder: Order;

  @OneToMany(() => Order, (order) => order.parentOrder)
  childOrders: Order[];

  @ManyToOne(() => Retailer, { eager: false })
  @JoinColumn({ name: 'retailerId' })
  retailer: Retailer;

  @Index()
  @Column()
  retailerId: string;

  /** Wholesaler for seller-specific sub-order (null on multi-seller parent orders) */
  @ManyToOne(() => Wholesaler, { eager: false, nullable: true })
  @JoinColumn({ name: 'wholesalerId' })
  wholesaler: Wholesaler;

  @Index()
  @Column({ nullable: true })
  wholesalerId: string;

  @ManyToOne(() => Zone, { eager: false, nullable: true })
  @JoinColumn({ name: 'zoneId' })
  zone: Zone;

  @Column({ nullable: true })
  zoneId: string;

  @OneToMany(() => OrderItem, (item) => item.order, { cascade: true, eager: true })
  items: OrderItem[];

  @Column({ type: 'enum', enum: OrderStatus, default: OrderStatus.PENDING })
  status: OrderStatus;

  /** Final total amount for this order record */
  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  totalAmount: number;

  /** Financial Breakdown calculated server-side */
  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  subtotalAmount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  discountAmount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  deliveryFee: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  taxAmount: number;

  /** Seller-specific gross, commission, and net snapshot */
  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  sellerGrossAmount: number;

  @Column({ type: 'decimal', precision: 5, scale: 2, default: 5.0 })
  commissionRate: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  commissionAmount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  sellerNetAmount: number;

  @Column({ nullable: true })
  deliveryAddress: string;

  @Column({ nullable: true })
  deliveryZone: string;

  @Column({ nullable: true })
  paymentIntentId: string;

  @Column({ default: 'UPI' })
  paymentMethod: string;

  @Column({
    type: 'enum',
    enum: OrderPaymentStatus,
    default: OrderPaymentStatus.PENDING,
  })
  paymentStatus: OrderPaymentStatus;

  @Column({ default: false })
  isPaid: boolean;

  @Column({ nullable: true })
  consolidationBatchId: string;

  @Column({ nullable: true })
  deliveryOtp: string;

  /** When the order becomes eligible for settlement payout (e.g. after delivery + return window) */
  @Column({ nullable: true })
  settlementEligibleAt: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
