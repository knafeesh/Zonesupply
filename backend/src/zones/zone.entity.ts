import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

@Entity('zones')
export class Zone {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column()
  city: string;

  @Column()
  pincode: string;

  @Column({ type: 'decimal', precision: 10, scale: 6 })
  centerLat: number;

  @Column({ type: 'decimal', precision: 10, scale: 6 })
  centerLng: number;

  @Column({ type: 'decimal', precision: 6, scale: 2 })
  radiusKm: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
