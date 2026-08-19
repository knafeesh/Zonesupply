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
import { DeliveryPartnerStatus } from '../common/enums/delivery-partner-status.enum';

@Entity('delivery_partners')
export class DeliveryPartner {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @OneToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({ unique: true })
  userId: string;

  @Column()
  vehicleType: string;

  @Column({ nullable: true })
  licenseNumber: string;

  @ManyToOne(() => Zone, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'currentZoneId' })
  currentZone: Zone;

  @Column({ nullable: true })
  currentZoneId: string;

  @Column({
    type: 'enum',
    enum: DeliveryPartnerStatus,
    default: DeliveryPartnerStatus.OFFLINE,
  })
  status: DeliveryPartnerStatus;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
