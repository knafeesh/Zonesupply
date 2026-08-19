import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { CreditLedger } from './credit-ledger.entity';
import { Order } from '../orders/order.entity';
import { LedgerTransactionType } from '../common/enums/ledger-transaction-type.enum';

@Entity('ledger_transactions')
export class LedgerTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => CreditLedger, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'ledgerId' })
  ledger: CreditLedger;

  @Column()
  ledgerId: string;

  @ManyToOne(() => Order, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'orderId' })
  order: Order;

  @Column({ nullable: true })
  orderId: string;

  @Column({
    type: 'enum',
    enum: LedgerTransactionType,
  })
  type: LedgerTransactionType;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  amount: number;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  balanceAfter: number;

  @Column({ nullable: true })
  note: string;

  @CreateDateColumn()
  createdAt: Date;
}
