import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Wholesaler } from '../wholesalers/wholesaler.entity';

@Entity('banners')
export class Banner {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => Wholesaler, { eager: true, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'wholesalerId' })
  wholesaler: Wholesaler;

  @Column()
  wholesalerId: string;

  @Column()
  title: string;

  @Column({ nullable: true })
  subtitle: string;

  @Column({ default: 'OFFER' })
  tag: string;

  @Column()
  imageUrl: string;

  @Column({ default: 'Fashion' })
  category: string;

  @Column({ nullable: true })
  subCategory: string;

  @Column({ default: '#6C3BD5' })
  gradientStart: string;

  @Column({ default: '#BB4DE0' })
  gradientEnd: string;

  @Column({ default: true })
  isActive: boolean;

  @Column({ default: 0 })
  displayOrder: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
