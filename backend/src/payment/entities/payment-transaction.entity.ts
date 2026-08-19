import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

export enum PaymentTransactionStatus {
  INITIATED = 'INITIATED',
  SUCCESS = 'SUCCESS',
  FAILED = 'FAILED',
  CANCELLED = 'CANCELLED',
  REFUNDED = 'REFUNDED',
}

export enum PaymentMethodType {
  UPI = 'UPI',
  CARD = 'CARD',
  NET_BANKING = 'NET_BANKING',
  WALLET = 'WALLET',
  COD = 'COD',
  CREDIT = 'CREDIT',
}

@Entity('payment_transactions')
export class PaymentTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Index()
  @Column({ nullable: true })
  parentOrderId: string;

  @Column({ nullable: true })
  retailerId: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  amount: number;

  @Column({ default: 'INR' })
  currency: string;

  @Column({
    type: 'enum',
    enum: PaymentTransactionStatus,
    default: PaymentTransactionStatus.INITIATED,
  })
  status: PaymentTransactionStatus;

  @Column({
    type: 'enum',
    enum: PaymentMethodType,
    default: PaymentMethodType.UPI,
  })
  paymentMethod: PaymentMethodType;

  @Column({ default: 'razorpay' })
  provider: string;

  @Index()
  @Column({ nullable: true })
  providerOrderId: string;

  @Index()
  @Column({ nullable: true })
  providerPaymentId: string;

  @Column({ nullable: true })
  signature: string;

  @Column({ type: 'jsonb', nullable: true })
  rawResponse: any;

  @Column({ type: 'text', nullable: true })
  failureReason: string;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
