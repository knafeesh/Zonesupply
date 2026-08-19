import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
} from 'typeorm';
import { Wholesaler } from '../wholesalers/wholesaler.entity';

@Entity('products')
export class Product {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  pricePerUnit: number;

  @Column()
  unit: string; // e.g. 'kg', 'piece', 'box'

  @Column({ default: 0 })
  stockQuantity: number;

  @Column({ nullable: true })
  imageUrl: string;

  @Column({ type: 'simple-array', nullable: true })
  images: string[];

  @Column({ nullable: true })
  category: string;

  @Column({ type: 'decimal', precision: 5, scale: 2, default: 0, transformer: {
    to: (value: number) => value,
    from: (value: string) => parseFloat(value) || 0
  }})
  discount: number;

  @Column({ nullable: true })
  barcode: string;

  @ManyToOne(() => Wholesaler, { eager: false })
  wholesaler: Wholesaler;

  @Column()
  wholesalerId: string;

  @Column({ type: 'simple-json', nullable: true })
  specifications: Record<string, any>;

  @Column({ default: true })
  isAvailable: boolean;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
