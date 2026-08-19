import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { Wholesaler } from '../wholesalers/wholesaler.entity';

export enum SettlementStatus {
  PENDING = 'PENDING',
  ELIGIBLE = 'ELIGIBLE',
  PROCESSING = 'PROCESSING',
  PAID = 'PAID',
  COMPLETED = 'COMPLETED', // Legacy alias for PAID
  FAILED = 'FAILED',
  ON_HOLD = 'ON_HOLD',
}

@Entity('seller_settlements')
export class Settlement {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column()
  wholesalerId: string;

  @ManyToOne(() => Wholesaler, { eager: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'wholesalerId' })
  wholesaler: Wholesaler;

  /** Total gross collected across all settled entries */
  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  totalGross: number;

  /** Total platform commission retained */
  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  totalCommission: number;

  /** Total adjustments applied */
  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  totalAdjustments: number;

  /** Total refunds deducted */
  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  totalRefunds: number;

  /** Net payout amount transferred to wholesaler (totalGross - commission - refunds - adjustments) */
  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  totalNet: number;

  /** Number of orders/entries included in this payout batch */
  @Column({ default: 0 })
  entryCount: number;

  @Column({
    type: 'enum',
    enum: SettlementStatus,
    default: SettlementStatus.PENDING,
  })
  status: SettlementStatus;

  @Column({ nullable: true })
  settledAt: Date;

  /** Payment gateway Transfer ID (e.g. trf_123456 from Razorpay Route) */
  @Column({ nullable: true })
  providerTransferId: string;

  /** Bank UTR / Payment reference ID (e.g. UTR20260818987654) */
  @Column({ type: 'text', nullable: true })
  paymentReference: string;

  @Column({ nullable: true })
  utrReference: string;

  @Column({ type: 'text', nullable: true })
  failureReason: string;

  /** Admin notes */
  @Column({ type: 'text', nullable: true })
  note: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
