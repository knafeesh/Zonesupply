import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, Unique } from 'typeorm';
import { Retailer } from '../retailers/retailer.entity';
import { Wholesaler } from './wholesaler.entity';

@Entity('favorite_wholesalers')
@Unique(['retailerId', 'wholesalerId'])
export class FavoriteWholesaler {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  retailerId: string;

  @Column()
  wholesalerId: string;

  @ManyToOne(() => Retailer, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'retailerId' })
  retailer: Retailer;

  @ManyToOne(() => Wholesaler, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'wholesalerId' })
  wholesaler: Wholesaler;
}
