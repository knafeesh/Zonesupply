import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToOne,
  JoinColumn,
  ManyToOne,
} from 'typeorm';
import { User } from '../users/user.entity';
import { Zone } from '../zones/zone.entity';
import { WholesalerPaymentAccount } from '../seller-ledger/wholesaler-payment-account.entity';

export enum SettlementCycle {
  T_1 = 'T_1',
  T_2 = 'T_2',
  T_7 = 'T_7',
  MANUAL = 'MANUAL',
}

@Entity('wholesalers')
export class Wholesaler {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({ unique: true })
  userId: string;

  @Column()
  businessName: string;

  @Column({ nullable: true })
  gstNumber: string;

  @Column({ nullable: true })
  panNumber: string;

  @Column({ type: 'text', nullable: true })
  address: string;

  @Column({ type: 'decimal', precision: 10, scale: 6 })
  latitude: number;

  @Column({ type: 'decimal', precision: 10, scale: 6 })
  longitude: number;

  @ManyToOne(() => Zone, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'zoneId' })
  zone: Zone;

  @Column({ nullable: true })
  zoneId: string;

  @Column({ nullable: true })
  shopNumber: string;

  /** Platform commission percentage snapshot default (e.g. 5.0 = 5%) */
  @Column({ type: 'decimal', precision: 5, scale: 2, default: 5.0 })
  commissionRate: number;

  /** Preferred settlement timing schedule */
  @Column({
    type: 'enum',
    enum: SettlementCycle,
    default: SettlementCycle.T_2,
  })
  settlementCycle: SettlementCycle;

  @OneToOne(() => WholesalerPaymentAccount, (acc) => acc.wholesaler, { cascade: true })
  paymentAccount: WholesalerPaymentAccount;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
