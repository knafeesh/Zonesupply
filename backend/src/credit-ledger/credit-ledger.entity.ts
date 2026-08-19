import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
} from 'typeorm';
import { Retailer } from '../retailers/retailer.entity';
import { Wholesaler } from '../wholesalers/wholesaler.entity';

@Entity('credit_ledger')
@Unique(['retailerId', 'wholesalerId'])
export class CreditLedger {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Retailer, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'retailerId' })
  retailer: Retailer;

  @Column()
  retailerId: string;

  @ManyToOne(() => Wholesaler, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'wholesalerId' })
  wholesaler: Wholesaler;

  @Column()
  wholesalerId: string;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  creditLimit: number;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  outstandingBalance: number;

  @UpdateDateColumn()
  updatedAt: Date;
}
