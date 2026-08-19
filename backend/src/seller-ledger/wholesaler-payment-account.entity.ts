import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
  JoinColumn,
} from 'typeorm';
import { Wholesaler } from '../wholesalers/wholesaler.entity';

export enum PayoutAccountStatus {
  NOT_CONFIGURED = 'NOT_CONFIGURED',
  PENDING_VERIFICATION = 'PENDING_VERIFICATION',
  ACTIVE = 'ACTIVE',
  REJECTED = 'REJECTED',
  SUSPENDED = 'SUSPENDED',
}

@Entity('wholesaler_payment_accounts')
export class WholesalerPaymentAccount {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  wholesalerId: string;

  @OneToOne(() => Wholesaler, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'wholesalerId' })
  wholesaler: Wholesaler;

  @Column({ default: 'razorpay_route' })
  provider: string;

  /** Connected / linked account ID from payment provider (e.g. Razorpay Linked Account ID / Fund Account ID) */
  @Column({ nullable: true })
  accountReferenceId: string;

  @Column({ nullable: true })
  beneficiaryName: string;

  /** Masked bank account (e.g. XXXXXXXX1234) - never store raw credentials in clear */
  @Column({ nullable: true })
  maskedAccountNumber: string;

  @Column({ nullable: true })
  ifscCode: string;

  @Column({ nullable: true })
  bankName: string;

  @Column({ nullable: true })
  vpaId: string; // UPI ID (e.g. seller@okaxis)

  @Column({
    type: 'enum',
    enum: PayoutAccountStatus,
    default: PayoutAccountStatus.NOT_CONFIGURED,
  })
  status: PayoutAccountStatus;

  @Column({ default: false })
  isVerified: boolean;

  @Column({ type: 'jsonb', nullable: true })
  metadata: any;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
