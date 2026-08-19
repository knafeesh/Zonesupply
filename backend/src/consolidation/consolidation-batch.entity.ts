import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Zone } from '../zones/zone.entity';
import { Wholesaler } from '../wholesalers/wholesaler.entity';
import { DeliveryPartner } from '../delivery-partners/delivery-partner.entity';

export enum BatchStatus {
  CREATED = 'created',
  PICKED_UP = 'picked_up',
  IN_TRANSIT = 'in_transit',
  COMPLETED = 'completed',
}

@Entity('consolidation_batches')
export class ConsolidationBatch {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Zone, { eager: true })
  @JoinColumn({ name: 'zoneId' })
  zone: Zone;

  @Column()
  zoneId: string;

  @ManyToOne(() => Wholesaler, { eager: true })
  @JoinColumn({ name: 'wholesalerId' })
  wholesaler: Wholesaler;

  @Column()
  wholesalerId: string;

  @ManyToOne(() => DeliveryPartner, { nullable: true, eager: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'deliveryPartnerId' })
  deliveryPartner: DeliveryPartner;

  @Column({ nullable: true })
  deliveryPartnerId: string | null;

  @Column({ type: 'enum', enum: BatchStatus, default: BatchStatus.CREATED })
  status: BatchStatus;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  totalValue: number;

  @Column({ default: 0 })
  orderCount: number;

  @Column({ type: 'timestamp', nullable: true })
  pickupTime: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
