import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from './user.entity';
import { CreateUserDto } from './dto/create-user.dto';
import { UserRole } from '../common/enums/user-role.enum';
import { WholesalersService } from '../wholesalers/wholesalers.service';
import { RetailersService } from '../retailers/retailers.service';
import { DeliveryPartnersService } from '../delivery-partners/delivery-partners.service';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly wholesalersService: WholesalersService,
    private readonly retailersService: RetailersService,
    private readonly partnersService: DeliveryPartnersService,
  ) {}

  async create(dto: CreateUserDto): Promise<User> {
    const existing = await this.userRepo.findOne({ where: { email: dto.email } });
    if (existing) throw new ConflictException('Email already registered');

    const passwordHash = await bcrypt.hash(dto.password, 12);
    const user = this.userRepo.create({
      email: dto.email,
      name: dto.name,
      phone: dto.phone,
      role: dto.role || UserRole.RETAILER,
      passwordHash,
      authProvider: 'email',
    });
    const savedUser = await this.userRepo.save(user);

    await this._createRoleProfile(savedUser, dto);
    return savedUser;
  }

  async findByEmail(email: string): Promise<User | null> {
    const cleanEmail = email.trim().toLowerCase();
    return this.userRepo
      .createQueryBuilder('user')
      .where('LOWER(user.email) = :email', { email: cleanEmail })
      .getOne();
  }

  async findById(id: string): Promise<User> {
    const user = await this.userRepo.findOne({ where: { id } });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  async updateFcmToken(userId: string, fcmToken: string): Promise<void> {
    await this.userRepo.update(userId, { fcmToken });
  }

  async findOrCreateByGoogle(
    googleId: string,
    email: string,
    name: string,
    picture: string | null,
    role: UserRole,
  ): Promise<User> {
    // 1. Try to find by googleId
    let user = await this.userRepo.findOne({ where: { googleId } });
    if (user) return user;

    // 2. Try to find by email (link existing email account)
    if (email) {
      user = await this.userRepo.findOne({ where: { email } });
      if (user) {
        user.googleId = googleId;
        user.authProvider = 'google';
        if (picture) user.profilePicture = picture;
        return this.userRepo.save(user);
      }
    }

    // 3. Create brand-new user
    const newUser = this.userRepo.create({
      googleId,
      email,
      name,
      profilePicture: picture ?? undefined,
      role,
      authProvider: 'google',
      isActive: true,
    });
    const saved = await this.userRepo.save(newUser);
    await this._createRoleProfile(saved);
    return saved;
  }

  async findOrCreateByPhone(
    phone: string,
    name: string | undefined,
    role: UserRole,
  ): Promise<User> {
    let user = await this.userRepo.findOne({ where: { phone } });
    if (user) return user;

    const newUser = this.userRepo.create({
      phone,
      name: name ?? phone,
      role,
      authProvider: 'otp',
      isActive: true,
    });
    const saved = await this.userRepo.save(newUser);
    await this._createRoleProfile(saved);
    return saved;
  }

  async findOrCreateByMembership(
    membershipId: string,
    phone: string,
    email: string | undefined,
    name: string | undefined,
    role: UserRole = UserRole.RETAILER,
  ): Promise<User> {
    let user: User | null = null;
    if (email) {
      user = await this.userRepo.findOne({ where: { email } });
    }
    if (!user && phone) {
      user = await this.userRepo.findOne({ where: { phone } });
    }
    if (user) {
      if (user.role !== role) {
        user.role = role;
        await this.userRepo.save(user);
      }
      return user;
    }

    const cleanPhone = phone ? phone.replace(/\D/g, '') : '';
    const newUser = this.userRepo.create({
      email: email || `member_${cleanPhone}@zonesupply.com`,
      phone: phone || undefined,
      name: name ?? `Member ${membershipId}`,
      role,
      authProvider: 'membership',
      isActive: true,
    });
    const saved = await this.userRepo.save(newUser);
    await this._createRoleProfile(saved);
    return saved;
  }

  private async _createRoleProfile(user: User, dto?: CreateUserDto): Promise<void> {
    if (user.role === UserRole.WHOLESALER) {
      await this.wholesalersService.createProfile(user, {
        businessName: dto?.businessName,
        gstNumber: dto?.gstNumber,
        panNumber: dto?.panNumber,
        address: dto?.address,
        shopNumber: dto?.shopNumber,
      });
    } else if (user.role === UserRole.RETAILER) {
      await this.retailersService.createDefault(user);
    } else if (user.role === UserRole.DELIVERY) {
      await this.partnersService.createDefault(user);
    }
  }
}
