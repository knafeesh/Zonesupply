import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { Wholesaler } from '../wholesalers/wholesaler.entity';

export enum SellerLedgerEntryType {
  SALE = 'SALE',
  COMMISSION = 'COMMISSION',
  REFUND = 'REFUND',
  CANCELLATION = 'CANCELLATION',
  ADJUSTMENT = 'ADJUSTMENT',
  SETTLEMENT = 'SETTLEMENT',
  EARNING = 'EARNING', // Legacy alias for SALE
}

export enum SellerLedgerEntryStatus {
  PENDING = 'PENDING',
  ELIGIBLE = 'ELIGIBLE',
  SETTLED = 'SETTLED',
  CANCELLED = 'CANCELLED',
}

@Entity('seller_ledger_entries')
export class SellerLedgerEntry {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column()
  wholesalerId: string;

  @ManyToOne(() => Wholesaler, { eager: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'wholesalerId' })
  wholesaler: Wholesaler;

  /** Associated parent or child order ID */
  @Index()
  @Column({ nullable: true })
  orderId: string;

  @Index()
  @Column({ nullable: true })
  sellerOrderId: string;

  /** Full order value related to this event */
  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  grossAmount: number;

  /** Platform's commission cut */
  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  commissionAmount: number;

  /** Amount credited to seller */
  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  credit: number;

  /** Amount debited from seller (commission, refunds, adjustments) */
  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  debit: number;

  /** Net amount resulting from this transaction (+ for earning, - for payout/refund) */
  @Column({ type: 'decimal', precision: 10, scale: 2 })
  netAmount: number;

  /** The commission rate applied at the time of this entry */
  @Column({ type: 'decimal', precision: 5, scale: 2, default: 5.0 })
  commissionRate: number;

  @Column({
    type: 'enum',
    enum: SellerLedgerEntryType,
    default: SellerLedgerEntryType.SALE,
  })
  type: SellerLedgerEntryType;

  @Column({
    type: 'enum',
    enum: SellerLedgerEntryStatus,
    default: SellerLedgerEntryStatus.PENDING,
  })
  status: SellerLedgerEntryStatus;

  /** Set when this entry is included in a settlement batch */
  @Index()
  @Column({ nullable: true })
  settlementId: string;

  @Column({ nullable: true })
  settledAt: Date;

  @Column({ nullable: true })
  providerReference: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'text', nullable: true })
  note: string;

  @CreateDateColumn()
  createdAt: Date;
}
