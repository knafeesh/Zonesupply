import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  Unique,
} from 'typeorm';
import { ConsolidationBatch } from './consolidation-batch.entity';
import { Order } from '../orders/order.entity';

export enum BatchOrderDeliveryStatus {
  PENDING = 'pending',
  DELIVERED = 'delivered',
  FAILED = 'failed',
}

@Entity('batch_orders')
@Unique(['batchId', 'orderId'])
export class BatchOrder {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => ConsolidationBatch, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'batchId' })
  batch: ConsolidationBatch;

  @Column()
  batchId: string;

  @ManyToOne(() => Order, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'orderId' })
  order: Order;

  @Column()
  orderId: string;

  @Column({ type: 'int', default: 0 })
  deliverySequence: number;

  @Column({
    type: 'enum',
    enum: BatchOrderDeliveryStatus,
    default: BatchOrderDeliveryStatus.PENDING,
  })
  deliveryStatus: BatchOrderDeliveryStatus;
}
