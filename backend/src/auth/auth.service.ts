import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  Inject,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import * as bcrypt from 'bcrypt';
import * as https from 'https';
import { UsersService } from '../users/users.service';
import { CreateUserDto } from '../users/dto/create-user.dto';
import { LoginDto } from './dto/login.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { SendOtpDto, VerifyOtpDto } from './dto/otp.dto';
import { MembershipLoginDto } from './dto/membership-login.dto';
import { User } from '../users/user.entity';
import { UserRole } from '../common/enums/user-role.enum';

export interface AuthPayload {
  accessToken: string;
  user: Omit<User, 'passwordHash'>;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    @Inject(CACHE_MANAGER) private readonly cacheManager: Cache,
  ) {}

  // ── Email / Password ──────────────────────────────────────────────────────
  async register(dto: CreateUserDto): Promise<AuthPayload> {
    const user = await this.usersService.create(dto);
    return this.buildPayload(user);
  }

  async login(dto: LoginDto): Promise<AuthPayload> {
    let searchEmail = dto.email.trim().toLowerCase();
    if (searchEmail === 'admin') searchEmail = 'admin@zonesupply.com';
    if (searchEmail === 'seller') searchEmail = 'seller@zonesupply.com';

    const user = await this.usersService.findByEmail(searchEmail);
    if (!user) throw new UnauthorizedException('Invalid credentials');

    if (!user.passwordHash)
      throw new UnauthorizedException(
        'This account uses Google or Phone login. Please use the correct method.',
      );

    const isValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isValid) throw new UnauthorizedException('Invalid credentials');
    if (!user.isActive) throw new UnauthorizedException('Account is deactivated');

    return this.buildPayload(user);
  }

  // ── Google OAuth ──────────────────────────────────────────────────────────
  async loginWithGoogle(dto: GoogleAuthDto): Promise<AuthPayload> {
    const googleUser = await this.verifyGoogleIdToken(dto.idToken);

    const user = await this.usersService.findOrCreateByGoogle(
      googleUser.sub,
      googleUser.email,
      googleUser.name,
      googleUser.picture ?? null,
      dto.role,
    );

    if (!user.isActive) throw new UnauthorizedException('Account is deactivated');
    return this.buildPayload(user);
  }

  // ── Phone OTP ─────────────────────────────────────────────────────────────
  async sendOtp(dto: SendOtpDto): Promise<{ message: string; devOtp?: string }> {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const cacheKey = `otp:${dto.phone}`;

    // Store OTP in Redis for 5 minutes
    await this.cacheManager.set(cacheKey, otp, 300_000);

    // TODO: Integrate real SMS provider (Twilio/MSG91)
    // For now: log to console and return in response for testing
    console.log(`[OTP STUB] Phone: ${dto.phone}  OTP: ${otp}`);

    return {
      message: `OTP sent to ${dto.phone}`,
      devOtp: otp, // Remove this line in production!
    };
  }

  async verifyOtp(dto: VerifyOtpDto): Promise<AuthPayload> {
    const cacheKey = `otp:${dto.phone}`;
    const storedOtp = await this.cacheManager.get<string>(cacheKey);

    if (!storedOtp) {
      throw new BadRequestException('OTP expired or not found. Please request a new one.');
    }

    if (storedOtp !== dto.otp) {
      throw new UnauthorizedException('Invalid OTP');
    }

    // Consume OTP (delete from cache)
    await this.cacheManager.del(cacheKey);

    const user = await this.usersService.findOrCreateByPhone(dto.phone, dto.name, dto.role);
    if (!user.isActive) throw new UnauthorizedException('Account is deactivated');

    return this.buildPayload(user);
  }

  // ── Membership Direct Login ───────────────────────────────────────────────
  async loginWithMembership(dto: MembershipLoginDto): Promise<AuthPayload> {
    const user = await this.usersService.findOrCreateByMembership(
      dto.membershipId,
      dto.mobile,
      dto.email,
      dto.name,
      UserRole.RETAILER,
    );
    if (!user.isActive) throw new UnauthorizedException('Account is deactivated');
    return this.buildPayload(user);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  private buildPayload(user: User): AuthPayload {
    const payload = { sub: user.id, email: user.email, role: user.role };
    const { passwordHash, ...safeUser } = user;
    return {
      accessToken: this.jwtService.sign(payload),
      user: safeUser,
    };
  }

  private verifyGoogleIdToken(
    idToken: string,
  ): Promise<{ sub: string; email: string; name: string; picture?: string }> {
    return new Promise((resolve, reject) => {
      const url = `https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`;
      https
        .get(url, (res) => {
          let data = '';
          res.on('data', (chunk) => (data += chunk));
          res.on('end', () => {
            try {
              const parsed = JSON.parse(data);
              if (parsed.error_description) {
                reject(new UnauthorizedException('Invalid Google token: ' + parsed.error_description));
              } else {
                resolve({
                  sub: parsed.sub,
                  email: parsed.email,
                  name: parsed.name,
                  picture: parsed.picture,
                });
              }
            } catch {
              reject(new UnauthorizedException('Failed to parse Google token response'));
            }
          });
        })
        .on('error', (e) => reject(new UnauthorizedException('Google token verification failed: ' + e.message)));
    });
  }
}
